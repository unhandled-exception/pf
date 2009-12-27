# PF Library

@CLASS
pfAntiFlood

## Класс для защиты форм от дублирования

@USE
pf/types/pfClass.p

@BASE
pfClass

#----- Constructor -----

@create[aOptions]
## aOptions.storage[pfAntiFloodStorage] - хранилище данных
## aOptions.path - путь к файлам для дефолтного хранилища
## aOptions.fieldName[form_uid] - имя поля формы
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]

  $_storage[^if(def $aOptions.storage){$aOptions.storage}{^pfAntiFloodStorage::create[$.path[$aOptions.path]]}]
  ^defReadProperty[storage]

  $_fieldName[^if(def $aOptions.fieldName){$aOptions.fieldName}{form_uid}]
  ^defReadProperty[fieldName]
  
  $_safeValue[0]
  $_doneValue[1]
  
#----- Methods -----

@protect[aUIDVarName;aCode][lUID]
## Формирует uid в переменной aUIDVarName и выполняет код
  ^storage.process{
    $lUID[^math:uuid[]]
    ^storage.set[$lUID;$_safeValue]
    $caller.[$aUIDVarName][$lUID]
    $result[$aCode]
  }

@field[aUID]
## Возвращает html-код для поля
  $result[<input type="hidden" name="$fieldName" value="$aUID" />]

@process[aRequest;aNormalCode;aFailCode][lUID]
## Вы полняет проверку полей запроса aRequest и выполняет код aNormalCode
## Если проверка прошла неудачно, то выполняет aFailCode
  ^storage.process{
    $lUID[$aRequest.[$fieldName]]
    ^if(def $lUID && ^storage.get[$lUID] eq $_safeValue){
      $result[$aNormalCode]
      ^storage.set[$lUID;$_doneValue]
    }{
       $result[$aFailCode]
     }
  }



@CLASS
pfAntiFloodStorage

## Хранилище ключей-значений 
## Должен реализовывать простой интерфейс get/set/process
## Изначально реализует хранение сессий в хеш-файле

@USE
pf/io/pfOS.p

@BASE
pfClass

@create[aOptions]
## aOptions.path[/../antiflood] - имя хеш-файла для хранения ключей
## aOptions.expires(15*60) - сколько секунд хранить пару ключ/значение
## aOptions.autoCleanup(true) - автоматически очищать неиспользуемые пары
## aOptions.cleanupTimeout - время в секундах между очистками хешфайла
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]
  
  $_path[^if(def $aOptions.path){$aOptions.path}{/../antiflood}]
  ^defReadProperty[path]
  
  $_expires(^aOptions.expires.int(15*60) * (1.0/(24*60*60)))
  
  $_autoCleanup(^aOptions.autoCleanup.bool(true))
  $_cleanupTimeout(^aOptions.cleanupTimeout.int(60*60))
  $_cleanupKey[LAST_CLEANUP]
    
  $_hashFile[]
  $_lockKey[GET_LOCK]

@GET_hashFile[]
  ^if(def $_hashFile){
    $result[$_hashFile]
  }{
    ^throw[${CLASS_NAME}.fail;Не используйет методы get/set вне process.]
  }

@get[aKey;aOptions]
## Получает ключ из хранилища
  $result[$hashFile.[$aKey]]

@set[aKey;aValue;aOptions]
## Записывает ключ в хранилище
  $hashFile.[$aKey][
    $.value[$aValue] 
    ^if($_expires){$.expires($_expires)}
  ]
  $result[]
  
@delete[aKey]
## Удаляет ключ из хранилища
  ^if(def $aKey){
    ^hashFile.delete[$aKey]
  }
  $result[]

@process[aCode][lNow]
## Метод в который необходимо "завернуть" вызовы get/set
## чтобы обеспечить атомарность операций
  ^pfOS:hashFile[$path][_hashFile]{
    $_hashFile.[$_lockKey][^math:uuid[]]
    $result[$aCode]
    
    ^if($_autoCleanup){
      $lNow[^date::now[]]
      ^if(^_hashFile.[$_cleanupKey].int(0) + $_cleanupTimeout < ^lNow.unix-timestamp[]){
        ^_hashFile.cleanup[]
        $_hashFile.[$_cleanupKey][^lNow.unix-timestamp[]]
      }
    }
  }
  $_hashFile[]

