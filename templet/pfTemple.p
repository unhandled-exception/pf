# PF library

@CLASS
pfTemple

@USE
pf/types/pfClass.p
pf/debug/pfRuntime.p

@BASE
pfClass

@create[aOptions]
## aOptions.templateFolder - путь к базовому каталогу с шаблонами 
## aOptions.force(false) - принудительно отменяет кеширование в стораджах и пр. местах 
## aOptions.defaultEnginePattern[(?:pt|htm|html)^$] - шаблон для дефолтного энжина
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]

# Массив путей для поиска шаблонов (hash[$.0 $.1 ...])
  $_templatePath[^hash::create[]]
  ^appendPath[^if(def $aOptions.templateFolder){$aOptions.templateFolder}{/../views}]

  $_force($aOptions.force)
  
  $_storages[^hash::create[]]
  ^registerStorage[file;pfTempleStorage;$.force($_isForce)]
  $_defaultStorage[file]

  $_engines[^hash::create[]]    
  $_defaultEnginePattern[^if(def $aOptions.defaultEnginePattern){$aOptions.defaultEnginePattern}{(?:pt|htm|html)^$}]
  ^registerEngine[parser;;pfTempleParserEngine]
  $_defaultEngine[parser]   
  
  $_globalVars[^hash::create[]]
  $_profiles[^hash::create[]]


#----- Properties -----

@GET_templatePath[]
  $result[$_templatePath]

@GET_defaultStorage[]
  $result[$_defaultStorage]

@SET_defaultStorage[aName]
  $_defaultStorage[$aName]

@GET_defaultEngine[]
  $result[$_defaultEngine]

@SET_defaultEngine[aName]
  $_defaultEngine[$aName]

@GET_defaultEnginePattern[]
  $result[$_defaultEnginePattern]

@SET_defaultEnginePattern[aName]
  $_defaultEnginePattern[$aName]

@GET_VARS[]
  $result[$_globalVars]

#----- Public -----

@appendPath[aPath]
## Добавляет путь для поиска шаблонов
  ^if(def $aPath){
    $_templatePath.[^_templatePath._count[]][$aPath]
  }
  $result[]

@registerStorage[aStorageName;aClassName;aOptions]
## aOptions.file - имя файла с классом
## aOptions.args - переменные, которые надо передать конструктору стораджа
  ^cleanMethodArgument[]   
  ^pfAssert:isTrue(def $aStorageName)[Не задано имя стораджа.]
  ^pfAssert:isTrue(def $aClassName)[Не задано имя класса стораджа.]
  $_storages.[$aStorageName][
    $.className[$aClassName]
    $.file[$aOptions.file]
    $.args[$aOptions.args]
    $.object[]  
  ]

@registerEngine[aEngineName;aPattern;aClassName;aOptions]
## aPattern[] - регулярное выражение для определения типа движка по имени шаблона, если не задано, то опеределяем движок
## aOptions.file - имя файла с классом
## aOptions.args - переменные, которые надо передать конструктору энжина
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aEngineName)[Не задано имя энжина.]
  ^pfAssert:isTrue(def $aClassName)[Не задано имя класса энжина.]
  $_engines.[$aEngineName][
    $.pattern[^if(def $aPattern){$aPattern}]
    $.className[$aClassName]
    $.file[$aOptions.file]
    $.args[$aOptions.args]
    $.object[]  
  ]

@loadTemplate[aTemplateName;aOptions][lParsed;lStorage]
## Загружает шаблон                      
## result: $.body $.path
  ^cleanMethodArgument[]
  $result[^hash::create[]]
  $lParsed[^_parseTemplateName[$aTemplateName]]
  $lStorage[^_getStorage[$lParsed.protocol]]
  $result[^lStorage.load[$aTemplateName;$aOptions]]

@assign[aVarName;aValue]
  $_globalVars.[$aVarName][$aValue]

@clearAllAssigned[]
  $_globalVars[^hash::create[]]

@render[aTemplateName;aOptions][lEngine;lTemplate]
## Рендрит шаблон
## $aTemplateName может быть задан в форме protocol:path/to/template/
## Если протокол не указан, то используем дефолтный - file
## aOptions.vars - переменные, которые необходимо передать шаблону (замещают VARS)
## aOptions.force(false) - принудительно перекомпилировать шаблон и отменить кеширование
## aOptions.engine[] - принудительно рендрит щаблон с помощью конкретного энжина
  ^cleanMethodArgument[]
  $lEngine[^_findEngine[$aTemplateName;$aOptions.engine]]
  $lTemplate[^loadTemplate[$aTemplateName;$.force($_force || $aOptions.force)]]
  $result[^lEngine.render[$lTemplate;$.vars[$aOptions.vars] $.force($_force || $aOptions.force)]]

@display[aTemplateName;aOptions]
## DEPRECATED!
  $result[^render[$aTemplateName;$aOptions]] 

#----- Private -----

@_getStorage[aStorageName][$lStorage]
## Возвращает объект стораджа
  ^if(^_storages.contains[$aStorageName]){   
    $lStorage[$_storages.[$aStorageName]]
    ^if(!def $lStorage.object){
      ^if(def $lStorage.file){
        ^use[$lStorage.file]
      }
      $lStorage.object[^reflection:create[$lStorage.className;create;$self;$lStorage.args]]
    }
    $result[$lStorage.object]
  }{
     ^throw[pfTemple.runtime;Не зарегистрирован сторадж "$aStorageName".] 
   }

@_getEngine[aEngineName][lEngine]   
  ^if(^_engines.contains[$aEngineName]){   
    $lEngine[$_engines.[$aEngineName]]
    ^if(!def $lEngine.object){
      ^if(def $lEngine.file){
        ^use[$lEngine.file]
      }
      $lEngine.object[^reflection:create[$lEngine.className;create;$self;$lEngine.args]]
    }
    $result[$lEngine.object]
  }{
     ^throw[pfTemple.runtime;Не зарегистрирован энжин "$aEngineName".] 
   }

@_findEngine[aTemplateName;aEngineName][lEngineName;k;v]
## Ищет энжин для шаблона по имени или по типу энжина.
  ^_engines.foreach[k;v]{
    ^if($k eq $aEngineName || ^aTemplateName.match[^if(def $v.pattern){$v.pattern}{$_defaultEnginePattern}][n]){
      $lEngineName[$k]
      ^break[]
    }
  }
  ^if(def $lEngineName){
    $result[^_getEngine[$lEngineName]]
  }{
     ^throw[template.engine.not.found;Не найден энжин для шаблона "$aTemplateName".]
   }


@_parseTemplateName[aTemplateName][lTemp;lProtocol;lPath]
## Разбирает строку с именем шаблона и возвращает
## хэш: $.protocol $.path
  $lTemp[^aTemplateName.match[(?:(.*?):(?://)?)?(.*)]]
  $lProtocol[$lTemp.1]
  $lPath[$lTemp.2]
  ^if(!def $lProtocol || !def $_storages.$lProtocol){
    $lProtocol[$defaultStorage]
  }
  ^if(!def $lProtocol){
    ^throw[templet.runtime;Storage "$lProtocol" not found.]
  }
  $result[$.protocol[$lProtocol] $.path[$lPath]]


#---------------------------------------------------------------------------------------------------


@CLASS
pfTempleStorage

@BASE
pfClass

@create[aTemple;aOptions]
## aTemple - ссылка на объект темпла, которому принадлежит сторадж
## aOptions.force(false)
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aTemple)[Не задан объект Темпла.]

  $_temple[$aTemple]
  $_isForce($aOptions.force)
  $_cache[^hash::create[]]


@load[aTemplateName;aOptions][lPath;lFile;v;i;c]
## Возвращает шаблон    
## aOptions.base[] - базовый путь в котором начинается поиск шаблона
## aOptions.force(false)
## result: $.body $.path
## throw: tepmlate.not.found - возбуждается, если шаблон не найден
  ^cleanMethodArgument[]
  $result[^hash::create[]]

# Ищем файл
  $lPath[^if(def $aOptions.base && -f "$aOptions.base/$aTemplateName"){$aOptions.base/$aTemplateName}]
  ^if(!def $lPath){
    $c($_temple.templatePath)
    ^for[i](1;$c){
      $v[$_temple.templatePath.[^eval($c - $i)]]
      ^if(-f "$v/$aTemplateName"){
        $lPath[$v/$aTemplateName]
        ^break[]
      }
    }
  }                             
  
# Загружаем файл или достаем его из кеша
  ^if(def $lPath){
    $result.path[$lPath]
    ^if((!$_isForce || !$aOptions.force) && ^_cache.contains[$lPath]){
      $result.body[$_cache.[$lPath]]            
    }{
       $lFile[^file::load[text;$lPath]]
       $result.body[$lFile.text]
       ^if(!$_isForce){
         $_cache.[$lPath][$result.body]
       }
     }
  }{
     ^throw[template.not.found;Шаблон "$aTemplateName" не найден.] 
   }

@flushCache[]
## Очищает кеш
  $_cache[^hash::create[]]


#---------------------------------------------------------------------------------------------------


@CLASS
pfTempleEngine

@BASE
pfClass

@create[aTemple;aOptions]
  ^pfAssert:isTrue($aTemple is pfTemple)[Не передан объект pfTemple.]
  $_temple[$aTemple]  

@GET_TEMPLE[]
  $result[$_temple]


#---------------------------------------------------------------------------------------------------


@CLASS
pfTempleParserEngine

@BASE
pfTempleEngine

@create[aTemple;aOptions]
## aTemple - ссылка на объект темпла, которому принадлежит энжин
  ^cleanMethodArgument[]
  ^BASE:create[$aTemple;$aOptions]
  
@render[aTemplate;aOptions][lPattern]
## aTemplate[$.body $.path]
## aOptions.vars[]
  ^cleanMethodArgument[]
  $lPattern[^pfTempleParserPattern::create[$.temple[$TEMPLE] $.file[$aTemplate.path]]]
  ^_compileToPattern[$lPattern;$aTemplate]

  $result[^lPattern.__process__[$.global[$TEMPLE.VARS] $.local[$aOptions.vars]]]

@_compileToPattern[aPattern;aTemplate][lBases]
  $result[]
  
# Ищем ссылки на предков
  $lBases[^aTemplate.body.match[^^#@base\s+(.+)^$][mg]]
  ^lBases.menu{
    ^_compileToPattern[$aPattern;^TEMPLE.loadTemplate[^lBases.1.trim[both; ];$.base[^file:dirname[$aTemplate.path]]]]
  }

# Компилируем текущий шаблон  
  ^process[$aPattern]{^taint[as-is][$aTemplate.body]}[$.main[__pattern__] $.file[$aTemplate.path]]


#---------------------------------------------------------------------------------------------------


@CLASS
pfTempleParserPattern

@BASE
pfClass

@create[aOptions]
## aOptions.file
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions] 

  $_temple[$aOptions.temple]
  $_FILE[$aOptions.file]  
  $_GLOBAL[]
  $_LOCAL[]

@GET_DEFAULT[aName]
  $result[^if(^_LOCAL.contains[$aName]){$_LOCAL.[$aName]}{$_GLOBAL.[$aName]}]

@GET_GLOBAL[]
  $result[$_GLOBAL]

@GET_LOCAL[]
  $result[$_LOCAL]

@GET_TEMPLET[]
  $result[$_temple]
    
@__process__[aOptions]
## aOptions.global
## aOptions.local
  ^cleanMethodArgument[]
  $_GLOBAL[^if(def $aOptions.global){$aOptions.global}{^hash::create[]}]
  $_LOCAL[^if(def $aOptions.local){$aOptions.local}{^hash::create[]}]
  $result[^__pattern__[]]
  $_GLOBAL[]
  $_LOCAL[]

@__pattern__[]
  ^throw[template.empty;Не задано тело шаблона.]  

@compact[]
## Вызывает принуительную сборку мусора.                   
  ^pfRuntime:compact[]
  $result[]  

