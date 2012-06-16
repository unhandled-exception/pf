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

  $_csql[^if(def $aOptions.sql){$aOptions.sql}{$_PFSQLTABLE_CSQL}]
  ^pfAssert:isTrue(def $_csql)[Не задан объект для работы с SQL-сервером.]

  $_tableName[$aTableName]
  $_builder[^if(def $aOptions.builder){$aOptions.builder}{$_PFSQLTABLE_BUILDER}]

  $_tableAlias[^if(def $aOptions.tableAlias){$aOptions.tableAlias}{$aTableName}]
  $_enableTableAlias(false)

  $_primaryKey[^if(def $aOptions.primaryKey){$aOptions.primaryKey}]

  $_fields[^hash::create[]]
  $_plurals[^hash::create[]]
  ^if(^aOptions.contains[fields]){
    ^aOptions.fields.foreach[k;v]{
      ^addField[$k;$v]
    }
  }

  $_skipOnInsert[^hash::create[^if(def $aOptions.skipOnInsert){$aOptions.skipOnInsert}]]
  $_skipOnUpdate[^hash::create[^if(def $aOptions.skipOnUpdate){$aOptions.skipOnUpdate}]]

  $_defaultResultType[^if(^aOptions.allAsTable.bool(false)){table}{hash}]

  $_now[^date::now[]]
  $_today[^date::today[]]

  $__context[]

#----- Статические методы и конструктор -----

@auto[]
  $_PFSQLTABLE_CSQL[]
  $_PFSQLTABLE_BUILDER[^pfSQLBuilder::create[]]
  $_PFSQLTABLE_COMPARSION_REGEX[^regex::create[^^\s*(\S+)(?:\s+(\S+))?][]]
  $_PFSQLTABLE_OPS[
    $.[<][<]
    $.[>][>]
    $.[<=][<=]
    $.[>=][>=]
    $.not[<>]
    $.[!=][<>]
    $.[!][<>]
    $.[<>][<>]
    $.like[like]
    $.[=][=]
    $.[==][=]
    $._default[=]
  ]
  $_PFSQLTABLE_LOGICAL[
    $.OR[or]
    $.AND[and]
    $.NOT[and]
    $._default[and]
  ]

@static:assignServer[aSQLServer]
# Чтобы можно было задать коннектор для всех объектов сразу.
  $_PFSQLTABLE_CSQL[$aSQLServer]

@static:assignBuilder[aSQLBuilder]
  $_PFSQLTABLE_BUILDER[$aSQLBuilder]

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

  $lField.name[$aFieldName]
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
  ^if(def $lField.plural){
    $_plurals.[$lField.plural][$lField]
  }

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
## Выражения для контроля выборки (код в фигурных скобках):
##   aOptions.selectFields{exression} — выражение для списка полей (вместо автогенерации)
##   aOptions.where{expression} — выражение для where
##   aOptions.having{expression} — выражение для having
##   aOptions.groupBy{expression} — выражение для groupBy
##   aOptions.orderBy{expression} — выражение для orderBy
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
   ^_selectExpression[
     ^_asContext[select]{
       ^if(def $aSQLOptions.selectОptions){$aSQLOptions.selectОptions}
       ^if(^aOptions.contains[selectFields]){
         $aOptions.selectFields
       }{
         ^if($lResultType eq "hash"){
           ^pfAssert:isTrue(def $_primaryKey)[Не определен первичный ключ для таблицы ${_tableName}. Выборку можно делать только в таблицу.]
#             Для хеша добавляем еще одно поле с первичным ключем
            $PRIMARYKEY as `_ORM_HASH_KEY_`,
         }
         $lJoinFields[^_allJoinFields[$aOptions]]
         ^_allFields[$aOptions;$aSQLOptions]^if(def $lJoinFields){, $lJoinFields}
        }
     }
   ][$lResultType;$aOptions;$aSQLOptions]
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
  ^_asContext[where]{
    $lGroup[^if(^aOptions.contains[groupBy]){$aOptions.groupBy}{^_allGroup[$aOptions]}]
    $lOrder[^if(^aOptions.contains[orderBy]){$aOptions.orderBy}{^_allOrder[$aOptions]}]
    $lHaving[^if(^aOptions.contains[having]){$aOptions.having}{^_allHaving[$aOptions]}]
  }

  $result[
       select $aFields
         from $_tableName as $_tableAlias
              ^_asContext[where]{^_allJoin[$aOptions]}
        where ^_asContext[where]{^_allWhere[$aOptions]}
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
  $lConds[^__conditions[$aOptions]]
  $result[^if(^aOptions.contains[where]){$aOptions.where}{1=1}^if(def $lConds){ and $lConds}]

@__conditions[aOptions;aOP][locals]
## Строим выражение для сравнения
## aOp[AND|OR|NOT]
  ^cleanMethodArgument[]
  $result[]

  $lConds[^hash::create[]]
  $_res[^hash::create[]]

  ^aOptions.foreach[k;v]{
    ^k.match[$_PFSQLTABLE_COMPARSION_REGEX][]{
      ^if(^_fields.contains[$match.1]){
#       Проверка одного поля
        ^if(def $match.2 && !^_PFSQLTABLE_OPS.contains[$match.2]){
          ^throw[pfSQLTable.invalid.op;Неизвестный оператор «${match.2}» для поля «${match.1}».]
        }
        $lField[$_fields.[$match.1]]
        $_res.[^_res._count[]][^_sqlFieldName[$match.1] $_PFSQLTABLE_OPS.[$match.2] ^_fieldValue[$lField;$v]]
      }(^_plurals.contains[$match.1]){
#       Проверка поля в множественном числе
        $lField[$_plurals.[$match.1]]
        $lColumn[^if(^aOptions.contains[${lField.plural}Column]){$aOptions.[${k}Column]}{$lField.name}]
        $_res.[^_res._count[]][^_sqlFieldName[$lField.name] ^if(^match.2.lower[] eq "not"){not in}{in} (^_valuesArray[$lField.name;$v;$.column[$lColumn]])]
      }($match.1 eq "OR" || $match.1 eq "AND" || $match.1 eq "NOT"){
#       Рекурсивный вызов логического блока
        $_res.[^_res._count[]][^__conditions[$v;$match.1]]
      }
    }
  }
  $result[^if($_res){^if($aOP eq "NOT"){not} (^_res.foreach[k;v]{$v}[ $_PFSQLTABLE_LOGICAL.[$aOP] ])}]

@_allGroup[aOptions]
  $result[]

@_allHaving[aOptions]
  $result[]

@_allOrder[aOptions]
  $result[^if(def $_primaryKey){$PRIMARYKEY asc}]


#----- Манипуляция данными -----

@new[aData;aSQLOptions]
## Вставляем значение в базу
## aSQLOptions.ignore(true)
  ^cleanMethodArgument[aData;aSQLOptions]
  ^CSQL.void{^_builder.insertStatement[$_tableName;$_fields;$aData;^hash::create[$aSQLOptions] $.skipFields[$_skipOnInsert]]}
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

@_sqlFieldName[aFieldName][locals]
  $lField[$_fields.[$aFieldName]]
  ^if($__context eq "where"
      && ^lField.contains[fieldExpression]
      && def $lField.fieldExpression){
    $result[$lField.fieldExpression]
  }(^lField.contains[expression]
    && def $lField.expression
   ){
     $result[$lField.expression^if($__context eq "select"){ as `$aFieldName`}]
  }{
     ^if(!^lField.contains[dbField]){
       ^throw[pfSQLTable.field.fail;Для поля «${aFieldName}» не задано выражение или имя в базе данных.]
     }
     $result[^_builder.sqlFieldName[$lField;^if($__context eq "where" || $__context eq "select"){$_tableAlias}]]
   }

@_asContext[aContext;aCode][locals]
  $lOldContext[$self.__context]
  $self.__context[$aContext]
  $result[$aCode]
  $self.__context[$lOldContext]
