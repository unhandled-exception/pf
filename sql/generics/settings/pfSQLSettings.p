@CLASS
pfSQLSettings

@USE
pf/types/pfClass.p

@BASE
pfClass

@create[aOptions]
## aOptions.sql - ссылка на sql-класс.
## aOptions.ignoreKeyCase(false) - игнорировать регистр символов для ключей.
## aOptions.tableName[settings] - имя таблицы в БД.
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]
  
  ^pfAssert:isTrue($aOptions.sql is pfSQL)[SQL-класс должен быть наследником pfSQL. ($aOptions.sql.CLASS_NAME)]
  $_CSQL[$aOptions.sql]
  $_tableName[^if(def $aOptions.tableName){$aOptions.tableName}{settings}]
  $_ignoreKeyCase(^aOptions.ignoreKeyCase.bool(false))
  
  $_vars[^_CSQL.hash{select distinct ^if($_ignoreKeyCase){upper(`key`)}{`key`} as `key`, value from $_tableName}[$.type[string]]]
    
@GET_DEFAULT[aKey]
  $result[^get[$aKey]]
  
@SET_DEFAULT[aKey;aValue]
  ^set[$aKey;$aValue]

@GET_ALL[]
  $result[$_vars]

@contains[aKey]
  $result(^_vars.contains[$aKey])

@get[aKey;aDefault][lKey]
  $lKey[^if($_ignoreKeyCase){^aKey.upper[]}{$aKey}]            
  $result[^if(^_vars.contains[$lKey]){$_vars.[$lKey]}{$aDefault}]

@set[aKey;aValue][lKey]
  $result[]  
  $lKey[^if($_ignoreKeyCase){^aKey.upper[]}{$aKey}]            
  ^_CSQL.safeInsert{
    ^_CSQL.void{insert into $_tableName (`key`, value) values ('$lKey', '$aValue')}
  }{
    ^_CSQL.void{update $_tableName set value = '$aValue' where `key` = '$lKey'}
   }
  $_vars.[$lKey][$aValue]
  