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
## aOptions.expires(15*60) - сколько секунд хранить пару ключ/значение [для дефолтного хранилища]
## aOptions.ignoreLockErrors(false) - игнорировать ошибки блокировки при проверке формы
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]

  $_expires(^aOptions.expires.int(15*60))
  $_storage[^if(def $aOptions.storage){$aOptions.storage}{^pfAntiFloodStorage::create[$.path[$aOptions.path] $.expires($_expires)]}]
  ^defReadProperty[storage]

  $_fieldName[^if(def $aOptions.fieldName){$aOptions.fieldName}{form_uid}]
  ^defReadProperty[fieldName]

  $_ignoreLockErrors(^aOptions.ignoreLockErrors.bool(false))
  $_safeValue[0]
  $_doneValue[1]

#----- Methods -----

@protect[aUIDVarName;aCode][lUID]
## Формирует uid в переменной aUIDVarName и выполняет код
  ^storage.process{
    $lUID[^math:uuid[]]
    ^storage.set[$lUID;$_safeValue]
    $caller.[$aUIDVarName][$lUID]
  }
  $result[$aCode]

@field[aUID;aFieldName]
## Возвращает html-код для поля
## aFieldName[_fieldName]
  $result[<input type="hidden" name="^if(def $aFieldName){$aFieldName}{$fieldName}" value="$aUID" />]

@process[aRequest;aNormalCode;aFailCode][lUID;lValidRequest]
## Вы полняет проверку полей запроса aRequest и выполняет код aNormalCode
## Если проверка прошла неудачно, то выполняет aFailCode
  $lValidRequest(false)
  ^try{
    ^storage.process{
      $lUID[$aRequest.[$fieldName]]
      ^if(def $lUID && ^storage.get[$lUID] eq $_safeValue){
        ^storage.set[$lUID;$_doneValue]
        $lValidRequest(true)
      }
    }
  }{
    ^if($_ignoreLockErrors && $exception.type eq "storage.locked"){
      $exception.handled(true)
      $lValidRequest(true)      
    }
  }
  $result[^if($lValidRequest){$aNormalCode}{$aFailCode}]



@CLASS
pfAntiFloodStorage

## Хранилище ключей-значений 
## Должен реализовывать простой интерфейс get/set/process
## Изначально реализует хранение сессий в хеш-файле

@BASE
pfClass

#@exception: storage.locked - хранилище заблокировано (невозможно получить эксклюзивную блокировку). 

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
  ^if(!def $_hashFile){
    $_hashFile[^hashfile::open[$_path]]
  }
  $result[$_hashFile]

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
  ^try{
    $hashFile.[$_lockKey][^math:uuid[]]
    $result[$aCode]
  
    ^if($_autoCleanup){
      $lNow[^date::now[]]
      ^if(^hashFile.[$_cleanupKey].int(0) + $_cleanupTimeout < ^lNow.unix-timestamp[]){
        ^hashFile.cleanup[]
        $hashFile.[$_cleanupKey][^lNow.unix-timestamp[]]
      }
    }
  }{
    ^if($exception.type eq "file.access" && ^exception.comment.pos[pa_sdbm_open] > -1){
      ^throw[storage.locked;$exception.source;$exception.comment]
    }
  }{
    ^hashFile.release[]
  }

