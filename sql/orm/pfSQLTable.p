@CLASS
pfSQLTable

#@compat 3.4.2

@USE
pf/types/pfClass.p
pf/tests/pfAssert.p
pf/sql/generics/builder/pfSQLBuilder.p

@BASE
pfClass

@create[aTableName;aOptions][k;v]
## aOptions.sql
## aOptions.tableAlias
## aOptions.schema
## aOptions.builder

## Следующие поля необязательны, но полезны
## при создании объекта на основании другой таблицы:
##   aOptions.fields
##   aOptions.primaryKey
##   aOptions.plural[название первичного ключа в множественном числе]
##   aOptions.skipOnInsert[$.field(bool)]
##   aOptions.skipOnUpdate[$.field(bool)]
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]
  ^pfAssert:isTrue(def $aTableName)[Не задано имя таблицы.]

  $_tableName[$aTableName]
  $_csql[^if(def $aOptions.sql){$aOptions.sql}{$_pfSQLTable_csql}]
  $_builder[^if(def $aOptions.builder){$aOptions.builder}{$_pfSQLTable_builder}]

  $_tableAlias[^if(def $aOptions.tableAlias){$aOptions.tableAlias}{$aTableName}]

  $_primaryKey[^if(def $aOptions.primaryKey){$aOptions.primaryKey}]
  $_plural[^if(def $aOptions.plural){$aOptions.plural}]

  $_skipOnInsert[^if(def $aOptions.skipOnInsert){$aOptions.skipOnInsert}{^hash::create[]}]
  $_skipOnUpdate[^if(def $aOptions.skipOnUpdate){$aOptions.skipOnUpdate}{^hash::create[]}]

  $_fields[^hash::create[]]
  ^if(^aOptions.contains[fields]){
    ^aOptions.fields.foreach[k;v]{
      ^addField[$k;$v]
    }
  }


#----- Статические методы и конструктор -----

@auto[]
  $_pfSQLTable_csql[]
  $_pfSQLTable_builder[^pfSQLBuilder::create[]]

@static:assignServer[aSQLServer]
# Чтобы можно было задать коннектор для всех объектов сразу.
  $_pfSQLTable_csql[$aSQLServer]

@static:assignBuilder[aSQLBuilder]
  $_pfSQLTable_csql[$aSQLBuilder]

#----- Метаданные -----

@GET_tableName[]
  $result[$_tableName]

@GET_tableAlias[]
  $result[$_tableAlias]

@GET_primaryKey[]
  $result[$_primaryKey]

@GET_plural[]
  $result[$_plural]

@GET_fields[]
  $result[$_fields]

@addField[aFieldName;aOptions][locals]
## aOptions.expression
## aOptions.bdField
## aOptions.processor
## aOptions.default
## aOptions.format
## aOptions.primary(false)
## aOptions.auto(false)
## aOptions.primary(false)
## aOptions.skipOnInsert(false)
## aOptions.skipOnUpdate(false)
  $result[]
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aFieldName)[Не задано имя поля таблицы.]
  ^pfAssert:isTrue(!^_fields.contains[$aFieldName])[Поле «${aFieldName}» в таблице уже существует.]

  $lField[^hash::create[]]
  ^if(^aOptions.contains[expression]){
     $lField.expression[$aOptions.expression]
     $self._skipOnUpdate.[$aFieldName](true)
     $self._skipOnInsert.[$aFieldName](true)
  }{
     $lField.dbField[^if(def $aOptions.dbField){$aOptions.dbField}{$aFieldName}]
     $lField.primary(^aOptions.primary.bool(false))
     $lField.auto(^aOptions.auto.bool(false))
     $lField.processor[$aOptions.processor]
     $lField.default{$aOptions.processor}
     $lField.format[$aOptions.format]
     ^if(^aOptions.skipOnUpdate.bool(false)){
       $self._skipOnUpdate.[$aFieldName](true)
     }
     ^if(^aOptions.skipOnInsert.bool(false)){
       $self._skipOnInsert.[$aFieldName](true)
     }
     ^if($lField.primary && !def $_primaryKey){
       $self._primaryKey[$aFieldName]
     }
   }
  $_fields.[$aFieldName][$lField]


#----- Свойства -----

@GET_CSQL[]
  $result[$_csql]

@GET_DEFAULT[aPrimaryKeyValue][locals]
# На подобие итератора для выборки отдельной записи
  ^unsafe{
    $result[^get[$aPrimaryKeyValue]]
    $result[$result.fields]
  }{
     ^throw[unknow.field;Неизвестное поле «${aPrimaryKeyValue}».]
   }


#----- Выборки -----

@get[aPrimaryKeyValue;aOptions]
  ^pfAssert:isTrue(def $_primaryKey)[Невозможно получить запись — не задан первичный ключ.]
  $result[^all[$.[$_primaryKey][$aPrimaryKeyValue]]]
  ^if($result){
    $result[^result._at[first]]
  }

@all[aOptions;aSQLOptions][locals]
## aOptions.asTable(false) — по-умолчанию возвращаем hash
## aOptions.where{expression} — выражение для where
## aOptions.having{expression} — выражение для having
## aOptions.limit
## aOptions.offset
## Для поддержки специфики СУБД:
##   aSQLOptions.tail — концовка запроса
##   aSQLOptions.options — модификатор после select (distinct, sql_cach и т.п.)
 ^cleanMethodArgument[aOptions;aSQLOptions]
 $lJoinFields[^_allJoinFields[$aOptions]]
 $lGroup[^_allGroup[$aOptions]]
 $lOrder[^_allOrder[$aOptions]]

 $lWhere[^if(^aOptions.contains[where]){$aOptions.where}]
 $lHaving[^if(^aOptions.contains[having]){$aOptions.having}{^_allHaving[$aOptions]}]

 ^CSQL.[^if(^aOptions.asTable.bool(false)){table}{hash}]{
   ^_builder.processStatementMacro[$_fields;
     select ^if(def $aSQLOptions.options){$aSQLOptions.options}
            ^_allFields[$aOptions]^if(def $lJoinFields){, $lJoinFields}
       from $_tableName as $_tableAlias
            ^_allJoin[]
      where ^if(def $lWhere){$lWhere}{1=1}
            ^_allWhere[$aOptions]
    ^if(def $lGroup){
      group by $lGroup
    }
    ^if(def $lHaving){
     having $lHaving
    }
    ^if(def $lOrder){
      order by $lOrder
    }
    ^if(def $aSQLOptions.tail){$aSQLOptions.tail}
  ][$.tableAlias[$_tableAlias]]
 }[
    ^if(^aOptions.contains[limit]){$.limit($aOptions.limit)}
    ^if(^aOptions.contains[offset]){$.offset($aOptions.offset)}
  ]]

@_allFields[aOptions]
  $result[^_builder.selectFields[$_fields;$.tableAlias[$_tableAlias]]]

@_allJoinFields[aOptions]
  $result[]

@_allJoin[aOptions]
  $result[]

@_allWhere[aOptions][locals]
## Если надо сделать иной вариант для where, перекрываем метод...
  $result[
#  Выборка отдельных полей
   ^_fields.foreach[k;v]{
     ^if(^aOptions.contains[$k]){
         and :$k = ^_builder.fieldValue[$v;$aOptions.[$k]]
     }
   }
#  Выборка по нескольким значениям из первичного ключа
   ^if(def $_plural && ^aOptions.contains[$_plural]){
     and :$_primaryKey in (^_builder.array[$_fields.[$_primaryKey];$aOptions.[$_plural];$.column[$_primaryKey]])
   }
  ]

@_allGroup[aOptions]
  $result[]

@_allHaving[aOptions]
  $result[]

@_allOrder[aOptions]
  $result[^if(def $_primaryKey){:$_primaryKey asc}]


#----- Манипуляция данными -----

@new[aOptions]
  …
  $result[^CSQL.lastInsertId[]]

@modify[aPrimaryKey;aOptions]
  update
         set …, $_primaryKeyField = $_primaryKeyField
    where $_primaryKeyField = "^taint[$aPrimaryKey]"

@delete[aPrimaryKey]
  delete from $_tableName where $_primaryKeyField = "^taint[$aPrimaryKey]"

@deleteAll[aOptions]
  delete from $_tableName
    where ^_allWhere[aOptions]

