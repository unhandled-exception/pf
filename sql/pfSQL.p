# PF Library

#@module   Base SQL Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

## Базовый класс для работы с sql-сервером.

## Общая идея и часть реализации взята из кода sql-классов
## Михаила Петрушина (misha@design.ru)
## http://www.parser.ru/examples/sql/

## Важно понимать, что задача полной совместимости с Мишиными классами
## не ставилась, поэтому при миграции возможны сложности.

@CLASS
pfSQL

@USE
pf/types/pfClass.p

@BASE
pfClass

#----- Constructor -----

@create[aConnectString;aOptions]
## Создает оъект
## aOptions.cache - объект класса pfCache (если не найден, то используем базовый класс)
## aOptions.isCaching(false) - включено ли кэширование?
## aOptions.cacheLifetime(3600) - время кеширования в секундах
## aOptions.cacheKeyPrefix[sql/] - префикс для ключа кеширования
## aOptions.isNaturalTransactions(0) - выполнять транзакции средствами SQL-сервера.
## aOptions.enableIdentityMap(0) - включить добавление результатов запросов в коллекцию объектов.

  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aConnectString)[Не определана строка соединения.]

  $_connectString[$aConnectString]
  $_transactionCount(0)

  $_serverType[SQL Generic]

# Готовим кэш
  $isCaching(^if(def $aOptions.isCaching){$aOptions.isCaching}{0})
  ^if(def $aOptions.cache){
    ^if($aOptions.cache is pfCache){
      $_CACHE[$aOptions.cache]
    }{
    	 ^throw[pfSQL.create;Cache must be child of pfCache.]
     }
  }

  $_cacheLifetime(^aOptions.cacheLifetime.int(3600))
  $_cacheKeyPrefix[^if(def $aOptions.cacheKeyPrefix){$aOptions.cacheKeyPrefix}{sql/}]

  $_isNaturalTransactions[^aOptions.isNaturalTransactions.int(0)]

  $_enableIdentityMap[^aOptions.enableIdentityMap.int(0)]  
  $_identityMap[]

  $_stat[
    $.queriesCount(0) 
    $.identityMap[
      $.size(0)
      $.usage(0)
    ]
    $.queries[^table::create{query}]
    $.queriesTime(0)
  ]
  
#----- Properties -----
@GET_connectString[]
  $result[$_connectString]

@GET_identityMap[]
  ^if(!def $_identityMap){
    ^use[pf/collections/pfDictionary.p]
    $_identityMap[^pfDictionary::create[]]
  }
  $result[$_identityMap]

@GET_CACHE[]
  ^if(!def $_CACHE){
     ^use[pf/cache/pfCache.p]
     $_CACHE[^pfCache::create[]]
  }
  $result[$_CACHE]

@GET_isTransaction[]
## Возвращает true, если идет  транзакция.
  $result($_transactionCount > 0)

@GET_serverType[]
  $result[$_severType]

@GET_isNaturalTransactions[]
## Возвращает true, если идет  транзакция.
  $result($_isNaturalTransactions)

@GET_stat[]
## Возвращает статистику по запросам
  $_stat.identityMap.size($identityMap.count)
  $result[$_stat]

#----- Public -----

@transaction[aCode]
## Организует транзакцию (вместо Мишиного server), обеспечивая возможность отката.
  ^connect[$connectString]{
    ^try{
     	^_transactionCount.inc(1)
  		^setServerEnvironment[]
  		^if($isTransaction == 1 && $isNaturalTransactions){
  			^startTransaction[]
    		$result[$aCode]
  			^commit[]
  	    }{
      	   $result[$aCode]
  	     }
    	^_transactionCount.dec(1)
    }{
  	   ^switch(true){
  	     ^case($exception.type eq "sql.transaction.roll"){
  	 	   $exception.handled(1)
  	     }
  	     ^case(!$exception.handled && $exception.type ne "sql.connect" && $isNaturalTransactions){
  	        ^rollback[]
  	     }
  	   }
   	   ^_transactionCount.dec(1)
  	   $result[]
     }
  }

@rollback[]
## Откатывает текущую транзакцию средствами парсера.
## Если запущено не в transaction, то выкидывает sql.transaction.failed
  ^if($isTransaction){
  	^throw[sql.transaction.roll;Roll current transaction.]
  }{
  	 ^throw[sql.transaction.failed;Call roll method from transaction.]
   }

@startTransaction[aOptions]
## Открывает транзакцию. Необходимо перекрыть для конкретного сервера.
  $result[]

@commit[aOptions]
## Комитит транзакцию. Необходимо перекрыть для конкретного сервера.
  $result[]

@setServerEnvironment[]
## Устанавливает переменные окружения сервера. 
## Вызывается перед транзакцией

#----- Queries -----

@table[aQuery;aSQLOptions;aOptions][lQuery;lOptions]
  $lQuery[^_processQuery{$aQuery}]
  $lOptions[^_getOptions[$lQuery;table;$aSQLOptions;$aOptions]]
  $result[^_processIdentityMap{^_sql[table]{^table::sql{$lQuery}[$aSQLOptions]}[$lOptions]}[$lOptions]]

@hash[aQuery;aSQLOptions;aOptions][lQuery;lOptions]
  $lQuery[^_processQuery{$aQuery}]
  $lOptions[^_getOptions[$lQuery;hash;$aSQLOptions;$aOptions]]
  $result[^_processIdentityMap{^_sql[hash]{^hash::sql{$lQuery}[$aSQLOptions]}[$lOptions]}[$lOptions]]

@file[aQuery;aSQLOptions;aOptions][lQuery;lOptions]
  $lQuery[^_processQuery{$aQuery}]
  $lOptions[^_getOptions[$lQuery;file;$aSQLOptions;$aOptions]]
  $result[^_processIdentityMap{^_sql[file]{^file::sql{$lQuery}[$aSQLOptions]}[$lOptions]}[$lOptions]]

@string[aQuery;aSQLOptions;aOptions][lQuery;lOptions]
  $lQuery[^_processQuery{$aQuery}]
  $lOptions[^_getOptions[$lQuery;string;$aSQLOptions;$aOptions]]
  $result[^_processIdentityMap{^_sql[string]{^string:sql{$lQuery}[$aSQLOptions]}[$lOptions]}[$lOptions]]

@double[aQuery;aSQLOptions;aOptions][lQuery;lOptions]
  $lQuery[^_processQuery{$aQuery}]
  $lOptions[^_getOptions[$lQuery;double;$aSQLOptions;$aOptions]]
  $result(^_processIdentityMap{^_sql[double]{^double:sql{$lQuery}[$aSQLOptions]}[$lOptions]}[$lOptions])

@int[aQuery;aSQLOptions;aOptions][lQuery;lOptions]
  $lQuery[^_processQuery{$aQuery}]
  $lOptions[^_getOptions[$lQuery;int;$aSQLOptions;$aOptions]]
  $result(^_processIdentityMap{^_sql[int]{^int:sql{$lQuery}[$aSQLOptions]}[$lOptions]}[$lOptions])

@void[aQuery;aSQLOptions;aOptions][lQuery]
  $lQuery[^_processQuery{$aQuery}]
  $result[^_sql[void]{^void:sql{$lQuery}[$aSQLOptions]}[$aOptions]]

@clearIdentityMap[]
  ^identityMap.clear[]

#----- Private -----

@_processQuery[aQuery]
  $result[^if($isTransaction){$aQuery}{^connect[$connectString]{$aQuery}}]
#   ^_stat.queries.append{^taint[$result]}


@_processIdentityMap[aCode;aOptions][lKey;lResult]
## Возвращает результат запроса из коллекции объектов.
## Если объект не найден, то запускает запрос и добавляет его результат в коллекцию.
## aOptions.isForce(0) - принудительно отменяет кеширование
## aOptions.identityMapKey[] - ключ для коллекции (по-умолчанию MD5 на aQuery).
  ^if($_enableIdentityMap && !^aOptions.isForce.int(0)){
    $lKey[^if(def $aOptions.identityMapKey){$aOptions.identityMapKey}{$aOptions.queryKey}]
    ^if(^identityMap.contains[$lKey]){
      $result[^identityMap.by[$lKey]]
      ^_stat.identityMap.usage.inc[]
    }{
       $result[$aCode]
       ^identityMap.add[$lKey;$result]
     }
  }{
     $result[$aCode]
   }

@_makeQueryKey[aQuery;aType;aSQLOptions]
## Формирует ключ для запроса
   $result[auto-${aType}-^math:md5[$aQuery]]
   ^if(def $aSQLOptions.limit){$result[${result}-$aSQLOptions.limit]}
   ^if(def $aSQLOptions.offset){$result[${result}-$aSQLOptions.offset]}

@_getOptions[aQuery;aType;aSQLOptions;aOptions]
## Объединяет опции запроса в один хеш, и, при необходимости, 
## вычисляет ключ запроса.
  ^cleanMethodArgument[]
  ^cleanMethodArgument[aSQLOptions]
  $result[^hash::create[$aOptions]]
  ^result.add[$aSQLOptions]
  $result.type[$aType]
  ^if(!$aOptions.isForce && ($_enableIdentityMap || $isCaching)){
    $result.queryKey[^_makeQueryKey[$aQuery;$aType;$aSQLOptions]]
  }

@_sql[aType;aCode;aOptions][lResult;lCacheKey]
## Возвращает результат запроса
## aOptions.isForce(0) - принудительно отменяет кеширование
## aOptions.cacheKey[] - ключ кеширования
## aOptions.cacheTime[секунды|дата окончания]
## aOptions.queryKey
  ^cleanMethodArgument[]
  ^if($isCaching 
      && (def $aOptions.cacheKey || def $aOptions.queryKey) 
      && !^aOptions.isForce.int(0)){
    ^if(!def $aOptions.cacheTime){$aOptions.cacheTime[$_cacheLifetime]}
    $lCacheKey[^if(def $aOptions.cacheKey){$aOptions.cacheKey}{$aOptions.queryKey}]
    $result[^CACHE.data[${_cacheKeyPrefix}$lCacheKey][$aOptions.cacheTime][$aType]{^_exec{$aCode}}] 
  }{
     $result[^_exec{$aCode}]
   }

@_exec[aCode][lStart;lEnd]
## Выполняет sql-запрос. Если нужно оранизует транзакцию.
  $lStart($status:rusage.tv_sec + $status:rusage.tv_usec/1000000.0)
  $result[^if($isTransaction){$aCode}{^transaction{$aCode}}]
  $lEnd($status:rusage.tv_sec + $status:rusage.tv_usec/1000000.0)
  ^_stat.queriesCount.inc[]
  $_stat.queriesTime($_stat.queriesTime + ($lEnd-$lStart))

#----- DATE functions -----

@today[]
  ^_abstractMethod[]    

@now[]
  ^_abstractMethod[]    

@year[sSource]
  ^_abstractMethod[]    

@month[sSource]
  ^_abstractMethod[]    

@day[sSource]
  ^_abstractMethod[]    

@ymd[sSource]
  ^_abstractMethod[]    

@time[sSource]
  ^_abstractMethod[]    

@date_diff[t;sDateFrom;sDateTo]
  ^_abstractMethod[]    

@date_sub[sDate;iDays]
  ^_abstractMethod[]    

@date_add[sDate;iDays]
  ^_abstractMethod[]    


#----- Functions available not for all sql servers -----

@date_format[sSource;sFormatString]
  ^_abstractMethod[]    

@last_insert_id[sTable]
  ^_abstractMethod[]    

@set_last_insert_id[sTable;sField]
  ^_abstractMethod[]    

#--- STRING functions ---

@substring[sSource;iPos;iLength]
  ^_abstractMethod[]    

@upper[sField]
  ^_abstractMethod[]    

@lower[sField]
  ^_abstractMethod[]    

@concat[sSource]
  ^_abstractMethod[]    

#----- MISC functions -----

@password[sPassword]
  ^_abstractMethod[]    

@left_join[sType;sTable;sJoinConditions;last]
  ^_abstractMethod[]    

