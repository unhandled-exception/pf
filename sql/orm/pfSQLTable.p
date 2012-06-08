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

## Следующие поля необязательны, но полезны
## при создании объекта на основании другой таблицы:
##   aOptions.fields[$.field[...]]
##   aOptions.primaryKey
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
  $_enableTableAlias(false)

  $_primaryKey[^if(def $aOptions.primaryKey){$aOptions.primaryKey}]

  $_fields[^hash::create[]]
  ^if(^aOptions.contains[fields]){
    ^aOptions.fields.foreach[k;v]{
      ^addField[$k;$v]
    }
  }

  $_skipOnInsert[^hash::create[^if(def $aOptions.skipOnInsert){$aOptions.skipOnInsert}]]
  $_skipOnUpdate[^hash::create[^if(def $aOptions.skipOnUpdate){$aOptions.skipOnUpdate}]]

  $_defaultResultType[^if(^aOptions.allAsTable.bool(false)){table}{hash}]


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

@addField[aFieldName;aOptions][locals]
## aOptions.bdField
## aOptions.fieldExpression[] — выражение для названия поля
## aOptions.expression[] — sql-выражение для значения поля (если не определено, то используем fieldExpression)
## aOptions.plural[] — название поля для групповой выборки
## aOptions.processor
## aOptions.default
## aOptions.format
## aOptions.primary(false)
## aOptions.skipOnInsert(false)
## aOptions.skipOnUpdate(false)
  $result[]
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aFieldName)[Не задано имя поля таблицы.]
  ^pfAssert:isTrue(!^_fields.contains[$aFieldName])[Поле «${aFieldName}» в таблице уже существует.]

  $lField[^hash::create[]]

  $lField.plural[$aOptions.plural]
  $lField.processor[^if(def $aOptions.processor){$aOptions.processor}]
  $lField.default[^if(def $aOptions.default){$aOptions.default}]
  $lField.format[^if(def $aOptions.format){$aOptions.format}]

  ^if(^aOptions.contains[fieldExpression] || ^aOptions.contains[expression]){
     $lField.fieldExpression[$aOptions.fieldExpression]
     $lField.expression[^if(def $aOptions.expression){$aOptions.expression}{$lField.fieldExpression}]
     $self._skipOnUpdate.[$aFieldName](true)
     $self._skipOnInsert.[$aFieldName](true)
  }{
     $lField.dbField[^if(def $aOptions.dbField){$aOptions.dbField}{$aFieldName}]
     $lField.primary(^aOptions.primary.bool(false))
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

@GET_TABLENAME[]
  $result[$_tableName]

@GET_FIELDS[]
  $result[$_fields]

@GET_CSQL[]
  $result[$_csql]

@GET_DEFAULT[aField][locals]
# Если нам пришло имя поля, то возвращаем имя поля в БД
# Для сложных случаев поддерживаем альтернативный синтаксис f_fieldName.
  $result[]
  $lField[^if(^aField.pos[f_] == 0){^aField.mid(2)}{$aField}]
  ^if($lField eq "PRIMARYKEY"){
    $lField[$_primaryKey]
  }
  ^if(^_fields.contains[$lField]){
    $result[^_sqlFieldName[$lField]]
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
## aOptions.where{expression} — выражение для where [Обязательно код в фигурных скобках.]
## aOptions.having{expression} — выражение для having [Обязательно код в фигурных скобках.]
## aOptions.limit
## aOptions.offset
## aOptions.primaryKeyColumn[:primaryKey] — имя колонки для первичного ключа
## Для поддержки специфики СУБД:
##   aSQLOptions.tail — концовка запроса
##   aSQLOptions.selectОptions — модификатор после select (distinct, sql_no_cache и т.п.)
##   aSQLOptions.skipFields — пропустить поля
##   + Все опции pfSQL.
 ^cleanMethodArgument[aOptions;aSQLOptions]

 $lResultType[^switch(true){
   ^case(^aOptions.asTable.bool(false)){table}
   ^case(^aOptions.asHash.bool(false)){hash})
   ^case[DEFAULT]{$_defaultResultType}
 }]
 $result[^CSQL.[$lResultType]{
   ^_processAliases{
     ^_selectExpression[
       ^if(def $aSQLOptions.selectОptions){$aSQLOptions.selectОptions}
       ^if($lResultType eq "hash"){
         ^pfAssert:isTrue(def $_primaryKey)[Не определен первичный ключ для таблицы ${_tableName}. Выборку можно делать только в таблицу.]
#         Для хеша добавляем еще одно поле с первичным ключем
          $PRIMARYKEY as `_ORM_HASH_KEY_`,
       }
       $lJoinFields[^_allJoinFields[$aOptions]]
       ^_allFields[$aOptions;$aSQLOptions]^if(def $lJoinFields){, $lJoinFields}
     ][$lResultType;$aOptions;$aSQLOptions]
   }
 }[
    ^if(^aOptions.contains[limit]){$.limit($aOptions.limit)}
    ^if(^aOptions.contains[offset]){$.offset($aOptions.offset)}
  ][$aSQLOptions]]]


@count[aOptions;aSQLOptions]
  ^cleanMethodArgument[aOptions;aSQLOptions]
  $result[^CSQL.int{
    ^_processAliases{^_selectExpression[count(*)][$lResultType;$aOptions;$aSQLOptions]}
  }[
    ^if(^aOptions.contains[limit]){$.limit($aOptions.limit)}
    ^if(^aOptions.contains[offset]){$.offset($aOptions.offset)}
  ][$aSQLOptions]]]


@_selectExpression[aFields;aResultType;aOptions;aSQLOptions][locals]
  $lGroup[^_allGroup[$aOptions]]
  $lOrder[^_allOrder[$aOptions]]
  $lHaving[^if(^aOptions.contains[having]){$aOptions.having}{^_allHaving[$aOptions]}]

  $result[
       select $aFields
         from $_tableName as $_tableAlias
              ^_allJoin[$aOptions]
#            Выражение для where делаем из двух частей, чтобы не огребать проблемы с макросами
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
  ]

@_allFields[aOptions;aSQLOptions]
  $result[^_builder.selectFields[$_fields;
    $.tableAlias[$_tableAlias]
    ^if(^aSQLOptions.contains[skipFields]){
      $.skipFields[$aSQLOptions.skipFields]
    }
  ]]

@_allJoinFields[aOptions]
  $result[]

@_allJoin[aOptions]
  $result[]

@_allWhere[aOptions][locals]
## Дополнительное выражение для where
## (выражение для полей формируется в _fieldsWhere)
  $result[
#   Дополнительное условие
    ^if(^aOptions.contains[where]){$aOptions.where}{1=1}

    ^_fields.foreach[k;v]{
#     Выборка по отдельным полям (равенство значений)
      ^if(^aOptions.contains[$k]){
        and ^_sqlFieldName[$k] = ^_fieldValue[$v;$aOptions.[$k]]
      }

#     Если для колонки задано поле с множественным числом, то строим выражение in
      ^if(def $v.plural && ^aOptions.contains[$v.plural]){
        $lColumn[^if(^aOptions.contains[${v.plural}Column]){$aOptions.[${v.plural}Column]}{$k}]
        and ^_sqlFieldName[$k] in (^_valuesArray[$k;$aOptions.[$v.plural];$.column[$lColumn]])
      }
    }
  ]

@_allGroup[aOptions]
  $result[]

@_allHaving[aOptions]
  $result[]

@_allOrder[aOptions]
  $result[^if(def $_primaryKey){$PRIMARYKEY asc}]


#----- Манипуляция данными -----

@new[aOptions;aSQLOptions]
## Вставляем значение в базу
## aSQLOptions.ignore(true)
  ^cleanMethodArgument[]
  ^CSQL.void{^_builder.insertStatement[$_tableName;$_fields;$aOptions;^hash::create[$aSQLOptions] $.skipFields[$_skipOnInsert]]}
  $result[^if(def $_primaryKey){^CSQL.lastInsertId[]}]

@modify[aPrimaryKeyValue;aData]
## Изменяем запись с первичныйм ключем aPrimaryKeyValue в таблице
  ^pfAssert:isTrue(def $_primaryKey)[Не определен первичный ключ для таблицы ${_tableName}.]
  ^pfAssert:isTrue(def $aPrimaryKeyValue)[Не задано значение первичного ключа]
  ^cleanMethodArgument[aData]
  $result[^CSQL.void{
    ^_builder.updateStatement[$_tableName;$_fields;$aData][$PRIMARYKEY = ^_fieldValue[$_fields.[$_primaryKey];$aPrimaryKeyValue]][
      $.skipAbsent(true)
      $.skipFields[$_skipOnUpdate]
      $.emptySetExpression[$PRIMARYKEY = $PRIMARYKEY]
    ]
  }]

@delete[aPrimaryKeyValue]
## Удаляем запись из таблицы с первичныйм ключем aPrimaryKeyValue
  ^pfAssert:isTrue(def $_primaryKey)[Не определен первичный ключ для таблицы ${_tableName}.]
  ^pfAssert:isTrue(def $aPrimaryKeyValue)[Не задано значение первичного ключа]
  $result[^CSQL.void{
    delete from $_tableName where $PRIMARYKEY = ^_fieldValue[$_fields.[$_primaryKey];$aPrimaryKeyValue]
  }]


#----- Групповые операции с данными -----

@modifyAll[aOptions;aData]
## Изменяем все записи
## Условие обновления берем из _allWhere
  ^cleanMethodArgument[aOptions;aData]
  $result[^CSQL.void{
    ^_builder.updateStatement[$_tableName;$_fields;$aData][
      ^_allWhere[$aOptions]
    ][
      $.skipAbsent(true)
      $.skipFields[$_skipOnUpdate]
      $.emptySetExpression[]
    ]
  }]

@deleteAll[aOptions]
## Удаляем все записи из таблицы
## Условие для удаления берем из _allWhere
  ^cleanMethodArgument[]
  $result[^CSQL.void{
    delete from $_tableName
     where ^_allWhere[$aOptions]
  }]


#----- Private -----

@_fieldValue[aField;aValue]
  $result[^_builder.fieldValue[$aField;$aValue]]

@_valuesArray[aField;aValues;aOptions]
## aField — имя или хеш с полем
  ^cleanMethodArgument[]
  ^if($aField is string){
    $aField[$_fields.[$aField]]
  }
  $result[^_builder.array[$aField;$aValues;$aOptions $.valueFunction[$_fieldValue]]]

@_sqlFieldName[aFieldName;aSkipAlias][locals]
  $lField[$_fields.[$aFieldName]]
  ^if(^lField.contains[fieldExpression]){
    $result[$lField.fieldExpression]
  }{
     $result[^_builder.sqlFieldName[$lField;^if($_enableTableAlias){$_tableAlias}]]
   }

@_processAliases[aCode]
  $_enableTableAlias(true)
  $result[$aCode]
  $_enableTableAlias(false)
