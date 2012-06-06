# PF Library

## Шлюз таблицы данных (Table Data Gateway).

@CLASS
pfSQLTable

#@compat 3.4.2
#@compat_db mysql

@USE
pf/types/pfClass.p
pf/tests/pfAssert.p
pf/sql/orm/pfSQLBuilder.p

@BASE
pfClass

@create[aTableName;aOptions][k;v]
## aOptions.sql
## aOptions.tableAlias
## aOptions.schema
## aOptions.builder
## aOptions.allAsTable(false) — по умолчанию возвращать результат в виде таблицы.
## aOptions.enableUnsafeActions(false) — включить небезопасные групповые операции

## Следующие поля необязательны, но полезны
## при создании объекта на основании другой таблицы:
##   aOptions.fields[$.field[...]]
##   aOptions.primaryKey
##   aOptions.plural[название первичного ключа в множественном числе]
##   aOptions.skipOnInsert[$.field(bool)]
##   aOptions.skipOnUpdate[$.field(bool)]
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]
  ^pfAssert:isTrue(def $aTableName)[Не задано имя таблицы.]

  $_csql[^if(def $aOptions.sql){$aOptions.sql}{$_pfSQLTable_csql}]
  ^pfAssert:isTrue(def $_csql)[Не задан объект для работы с SQL-сервером.]

  $_tableName[$aTableName]
  $_builder[^if(def $aOptions.builder){$aOptions.builder}{$_pfSQLTable_builder}]

  $_tableAlias[^if(def $aOptions.tableAlias){$aOptions.tableAlias}{$aTableName}]

  $_primaryKey[^if(def $aOptions.primaryKey){$aOptions.primaryKey}]
  $_plural[^if(def $aOptions.plural){$aOptions.plural}]

  $_fields[^hash::create[]]
  ^if(^aOptions.contains[fields]){
    ^aOptions.fields.foreach[k;v]{
      ^addField[$k;$v]
    }
  }

  $_skipOnInsert[^hash::create[^if(def $aOptions.skipOnInsert){$aOptions.skipOnInsert}]]
  $_skipOnUpdate[^hash::create[^if(def $aOptions.skipOnUpdate){$aOptions.skipOnUpdate}]]

  $_defaultResultType[^if(^aOptions.allAsTable.bool(false)){table}{hash}]
  $_enableUnsafeActions(^aOptions.enableUnsafeActions.bool(false))
  
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
     $lField.processor[^if(def $aOptions.processor){$aOptions.processor}]
     $lField.default[^if(def $aOptions.default){$aOptions.default}]
     $lField.format[^if(def $aOptions.format){$aOptions.format}]
     ^if(^aOptions.skipOnUpdate.bool(false) || $lField.primary){
       $self._skipOnUpdate.[$aFieldName](true)
     }
     ^if(^aOptions.skipOnInsert.bool(false) || $lField.primary){
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
  ^pfAssert:isTrue(def $aPrimaryKeyValue)[Не задано значение первичного ключа]
  $result[^one[$.[$_primaryKey][$aPrimaryKeyValue]]]

@one[aOptions;aSQLOptions]
  $result[^all[$aOptions;$aSQLOptions]]
  ^if($result){
    ^if($result is table){
      $result[$result.fields]
    }{
       $result[^result._at[first]]
     }
  }{
     $result[^hash::create[]]
   }

@all[aOptions;aSQLOptions][locals]
## aOptions.asTable(false) — возвращаем хеш
## aOptions.asHash(true) — возвращаем таблицу
## aOptions.where{expression} — выражение для where
## aOptions.having{expression} — выражение для having
## aOptions.limit
## aOptions.offset
## aOptions.primaryKeyColumn[:primaryKey] — имя колонки для первичного ключа
## Для поддержки специфики СУБД:
##   aSQLOptions.tail — концовка запроса
##   aSQLOptions.options — модификатор после select (distinct, sql_cach и т.п.)
 ^cleanMethodArgument[aOptions;aSQLOptions]

 $lResultType[^switch(true){
   ^case(^aOptions.asTable.bool(false)){table}
   ^case(^aOptions.asHash.bool(false)){hash})
   ^case[DEFAULT]{$_defaultResultType}
 }]
 ^CSQL.[$lResultType]{
   ^_selectExpression[$lResultType;$aOptions;$aSQLOptions]
 }[
    ^if(^aOptions.contains[limit]){$.limit($aOptions.limit)}
    ^if(^aOptions.contains[offset]){$.offset($aOptions.offset)}
  ]]

@_selectExpression[aResultType;aOptions;aSQLOptions][locals]
  $lJoinFields[^_allJoinFields[$aOptions]]
  $lGroup[^_allGroup[$aOptions]]
  $lOrder[^_allOrder[$aOptions]]

  $lHaving[^if(^aOptions.contains[having]){$aOptions.having}{^_allHaving[$aOptions]}]
  $result[^_builder.processStatementMacro[$_fields;
     select ^if(def $aSQLOptions.options){$aSQLOptions.options}
            ^if($aResultType eq "hash"){
              ^pfAssert:isTrue(def $_primaryKey)[Не определен первичный ключ для таблицы ${_tableName}. Выборку можно делать только в таблицу.]
#             Для хеша добавляем еще одно поле с первичным ключем
              `${_tableAlias}`.`$_fields.[$_primaryKey].dbField` as  `_ORM_HASH_KEY_`,
            }
            ^_allFields[$aOptions]^if(def $lJoinFields){, $lJoinFields}
       from $_tableName as $_tableAlias
            ^_allJoin[]
      where ^_allWhere[$aOptions]
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
  ][$.tableAlias[$_tableAlias]]]

@_allFields[aOptions]
  $result[^_builder.selectFields[$_fields;$.tableAlias[$_tableAlias]]]

@_allJoinFields[aOptions]
  $result[]

@_allJoin[aOptions]
  $result[]

@_allWhere[aOptions][locals]
## Если надо сделать иной вариант для where, перекрываем метод...
  $lWhere[^if(^aOptions.contains[where]){$aOptions.where}]
  $result[^if(def $lWhere){$lWhere}{1=1}
#  Выборка по отдельным полям (равенство значений)
   ^_fields.foreach[k;v]{
     ^if(^aOptions.contains[$k]){
         and :$k = ^_fieldValue[$v;$aOptions.[$k]]
     }
   }
#  Выборка по нескольким значениям из первичного ключа
   ^if(def $_plural && ^aOptions.contains[$_plural]){
     $lColumn[^if(def $aOptions.primaryKeyColumn){$aOptions.primaryKeyColumn}{$_primaryKey}]
     and :$_primaryKey in (^_valuesArray[$_fields.[$_primaryKey];$aOptions.[$_plural];$.column[$lColumn]])
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
## Вставляем значение в базу
  ^cleanMethodArgument[]
  ^CSQL.void{^_builder.insertStatement[$_tableName;$_fields;$aOptions;$.skipFields[$_skipOnInsert]]}
  $result[^if(def $_primaryKey){^CSQL.lastInsertId[]}]

@modify[aPrimaryKeyValue;aData]
## Изменяем запись с первичныйм ключем aPrimaryKeyValue в таблице
  ^pfAssert:isTrue(def $_primaryKey)[Не определен первичный ключ для таблицы ${_tableName}.]
  ^pfAssert:isTrue(def $aPrimaryKeyValue)[Не задано значение первичного ключа]
  ^cleanMethodArgument[aData]
  $result[^CSQL.void{
    ^_builder.updateStatement[$_tableName;$_fields;$aData][:$_primaryKey = ^_fieldValue[$_fields.[$_primaryKey];$aPrimaryKeyValue]][
      $.skipAbsent(true)
      $.skipFields[$_skipOnUpdate]
      $.emptySetExpression[:$_primaryKey = :$_primaryKey]
    ]
  }]

@delete[aPrimaryKeyValue]
## Удаляем запись из таблицы с первичныйм ключем aPrimaryKeyValue
  ^pfAssert:isTrue(def $_primaryKey)[Не определен первичный ключ для таблицы ${_tableName}.]
  ^pfAssert:isTrue(def $aPrimaryKeyValue)[Не задано значение первичного ключа]
  $result[^CSQL.void{^_builder.processStatementMacro[$_fields;
    delete from $_tableName where :$_primaryKey = ^_fieldValue[$_fields.[$_primaryKey];$aPrimaryKeyValue]
  ]}]

#----- Групповые операции с данными -----
#----- Крайне опасные функции!

@modifyAll[aOptions;aData]
## Изменяем все записи/ Условие обновления берем из _allWhere
  ^pfAssert:isTrue($_enableUnsafeActions)[Выполнение modifyAll запрещено.]
  ^cleanMethodArgument[aOptions;aData]
  $result[^CSQL.void{
    ^_builder.updateStatement[$_tableName;$_fields;$aData][^_allWhere[$aOptions]][
      $.skipAbsent(true)
      $.skipFields[$_skipOnUpdate]
      $.emptySetExpression[]
    ]
  }]

@deleteAll[aOptions]
## Удаляем все записи из таблицы
## Условие для удаления берем из _allWhere
  ^pfAssert:isTrue($_enableUnsafeActions)[Выполнение deleteAll запрещено.]
  ^cleanMethodArgument[]
  $result[^CSQL.void{^_builder.processStatementMacro[$_fields;
    delete from $_tableName
     where ^_allWhere[$aOptions]
  ]}]


#----- Private -----

@_fieldValue[aField;aValue]
  $result[^_builder.fieldValue[$aField;$aValue]]

@_valuesArray[aField;aValues;aOptions]
  ^cleanMethodArgument[]
  $result[^_builder.array[$aField;$aValues;$aOptions $.valueFunction[$_fieldValue]]]
