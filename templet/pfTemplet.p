# PF Library
# Templet Engine

@CLASS
pfTemplet

@USE
pf/types/pfClass.p

pf/templet/pfTempletStorage.p
pf/templet/pfTempletPattern.p

@BASE
pfClass

#----- Constructor -----

@create[aOptions]
## aOptions.templateFolder - путь к каталогу с шаблонами
## aOptions.cache - объект класса pfCache (если не найден, то используем базовый класс)
## aOptions.isCaching(false) - включено ли кэширование?
## aOptions.cacheLifetime(3600) - время кеширования в секундах
## aOptions.cacheKeyPrefix[templet/] - префикс для ключа кеширования
##                                     если включена, то принудительно отменяем кэширование измененных файлов
  ^BASE:create[]
  ^cleanMethodArgument[]

  ^pfAssert:isTrue(!def $aOptions.cache || (def $aOptions.cache && $aOptions.cache is pfCache))[Кэш должен быть наследником pfCache.]

  $_templateFolder[^if(def $aOptions.templateFolder){^aOptions.templateFolder.trim[end;/]/}{/../views/}]

# Хранилище откомпилированных шаблонов
  $_templates[^hash::create[]]

# Хранилище переменных
  $_vars[^hash::create[]]

# Протоколы получения текстов шаблонов
  $_defaultStorage[file]
  $_storages[
     $.[$_defaultStorage][^pfTempletStorage::create[
        ^if(def $_templateFolder){
           $.path[$_templateFolder]
        }
     ]]
  ]

# Готовим кэш
  $isCaching(^if(def $aOptions.isCaching){$aOptions.isCaching}{0})
  ^if(def $aOptions.cache){
    $_CACHE[$aOptions.cache]
  }{
  	 $_CACHE[]
   }

  $_cacheLifetime(^aOptions.cacheLifetime.int(3600))
  $_cacheKeyPrefix[^if(def $aOptions.cacheKeyPrefix){$aOptions.cacheKeyPrefix}{templet/}]

#----- Public -----

@assign[aName;aValue]
## Добавляет в шаблон переменную aName со значением aValue
   ^_vars.add[$.[$aName][$aValue]]

@render[aTemplateName;aOptions][result;lCacheTime]
## Отрисовывает шаблон
## $aTemplateName может быть задан в форме protocol:path/to/template/
## Если протокол не указан, то используем дефолтный - file
## aOptions.isCaching - кешировать результат шаблона?
## aOptions.cacheLifetime - время кеширования шаблона в скундах
## aOptions.templateID - ID шаблона (нужно, если есть необходимость закешировать несколько версий одного шаблона) 
## aOptions.vars - переменные, которые необходимо передать шаблону (замещают VARS)
## aOptions.force(false) - принудительно перекомпилировать шаблон и отменить кеширование
  ^cleanMethodArgument[]
  ^if(!^aOptions.force.bool(false)){
    $lCacheTime[^if(^aOptions.isCaching.int($isCaching)){^aOptions.cacheLifetime.int($cacheLifetime)}{0}]
    $result[^CACHE.code[^_makeCacheKey[$aTemplateName;$aOptions.templateID]](^lCacheTime.int(0)){^_runTemplate[^_loadTemplate[$aTemplateName];$aOptions.vars]}]
  }{
    $result[^_runTemplate[^_loadTemplate[$aTemplateName;$.force(true)];$aOptions.vars]]
  }
  
@display[aTemplateName;aOptions]
## DEPRECATED!
  $result[^render[$aTemplateName;$aOptions]]

@registerStorage[aStorageName;aStorageHandler]
## Добавляет новый протокол для получения шаблонов
## При этом можно заменить и стандартный протокол "file"
## Класс протокола должен быть наследником pfTempletStorage
  ^pfAssert:isTrue($aStorageHandler is pfTempletStorage)[Класс протокола должен быть наследником pfTempletStorage.]
  ^_storages.add[$.[$aStorageName][$aStorageHandler]]

@isCached[aTemplateName;aTemplateID]
## проверяет есть ли в кеше шаблон
  $result(^CACHE.isCacheKeyFound[^_makeCacheKey[$aTemplateName;$aTemplateID]])

@isTemplateExists[aTemplateName][lTemplateName]
## Проверяет доступен ли шаблон  
  $lTemplateName[^_parseTemplateName[$aTemplateName]]
  $result(^_storages.[$lTemplateName.protocol].isTemplateExists[$lTemplateName.path])

@clearAllAssigned[]
## Очищает все, связанные переменные
  ^_vars.foreach[k;v]{$k[]}

#----- Properties -----

@GET_templateFolder[]
  $result[$_templateFolder]

@GET_CACHE[]
  ^if(!def $_CACHE){
     ^use[pf/cache/pfCache.p]
     $_CACHE[^pfCache::create[]]
  }
  $result[$_CACHE]

@GET_VARS[]
  $result[$_vars]

@GET_isCaching[]
  $result($_isCaching)

@SET_isCaching[aValue]
  $_isCaching($aValue)

@GET_cacheLifetime[]
  $result($_cacheLifetime)

@SET_cacheLifetime[aValue]
  $_cacheLifetime($aValue)

#----- Private -----

@_parseTemplateName[aTemplateName][lTemp;lProtocol;lPath]
## Разбирает строку с именем шаблона и возвращает
## хэш: $.protocol $.path
  $lTemp[^aTemplateName.match[(?:(.*?):(?://)?)?(.*)][]{
    $lProtocol[$match.1]
    $lPath[$match.2]
    ^if(!def $lProtocol || !def $_storages.$lProtocol){
      $lProtocol[$_defaultStorage]
    }
    ^if(!def $lProtocol){
      ^throw[templet.runtime;Storage "$lProtocol" not found.]
    }
  }]  
  $result[$.protocol[$lProtocol] $.path[$lPath]]

@_loadTemplate[aTemplateName;aOptions][lTemplateName]
## Возвращает объект шаблона
## aOptions.force(false) - принудительно создать отдельный объект для шаблона шаблон
  ^cleanMethodArgument[]
  $lTemplateName[^_parseTemplateName[$aTemplateName]]
  ^if(!^aOptions.force.bool(false)){
    ^if(!def $_templates.[$aTemplateName]){
      ^_templates.add[
         $.[$aTemplateName][
              $.source[^_storages.[$lTemplateName.protocol].getTemplate[$lTemplateName.path]]           
              $.object[]
              $.fileName[$path/$lTemplateName.path]
         ]
      ]
      $_templates.[$aTemplateName].object[^_compileTemplate[$_templates.[$aTemplateName].source;$_templates.[$aTemplateName].fileName]]
    }
    $result[$_templates.[$aTemplateName].object]
  }{
    $result[^_compileTemplate[^_storages.[$lTemplateName.protocol].getTemplate[$lTemplateName.path];$path/$lTemplateName.path]]
  }
  
@_compileTemplate[aSource;aFileName]
# Возвращает откомпилированный шаблон 
   $result[^pfTempletPattern::create[$aSource;$self;$.fileName[$aFileName]]]

@_runTemplate[aTemplate;aVars][lVars]
  $lVars[$_vars]
  ^if(def $aVars && $aVars is hash ){
#   Объединяем переменные уже добавленные в шаблон с теми, которые пришли нам в метод render.      
    $lVars[^hash::create[$lVars]]
    ^lVars.add[$aVars]
  }
  ^aTemplate.assignVars[$lVars]
  $result[^aTemplate._pattern[]]

@_makeCacheKey[aTemplateName;aTemplateID]
## Возвращает ключ кеширования для шаблона
  $result[${_cacheKeyPrefix}^math:md5[$aTemplateName]^if(def $aTemplateID){^math:md5[$aTemplateID]}]
  