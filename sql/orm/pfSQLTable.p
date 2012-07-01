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

  $_csql[^if(def $aOptions.sql){$aOptions.sql}{$_PFSQLTABLE_CSQL}]
  ^pfAssert:isTrue(def $_csql){Не задан объект для работы с SQL-сервером.}

  $_builder[^if(def $aOptions.builder){$aOptions.builder}{$_PFSQLTABLE_BUILDER}]

  $_tableName[$aTableName]
  $_tableAlias[^if(def $aOptions.tableAlias){$aOptions.tableAlias}]
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

  $_defaultOrderBy[]
  $_defaultGroupBy[]

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
## aOptions.sequence(true) — автоинкремент (только для первичного ключа)
## aOptions.skipOnInsert(false)
## aOptions.skipOnUpdate(false)
  $result[]
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aFieldName){Не задано имя поля таблицы.}
  ^pfAssert:isTrue(!^_fields.contains[$aFieldName]){Поле «${aFieldName}» в таблице уже существует.}

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
     $lField.sequence($lField.primary && ^aOptions.sequence.bool(true))
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

@GET_TABLE_NAME[]
  ^pfAssert:isTrue(def $_tableName){Не задано имя таблицы в классе $self.CLASS_NAME}
  $result[$_tableName]

@GET_TABLE_ALIAS[]
  ^if(!def $_tableAlias){
    $_tableAlias[$TABLE_NAME]
  }
  $result[$_tableAlias]

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
  ^pfAssert:isTrue(def $aPrimaryKeyValue){Не задано значение первичного ключа}
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
##   aOptions.orderBy[hash[$.field[asc]]|{expression}] — хеш с полями или выражение для orderBy
##   aOptions.groupBy[hash[$.field[asc]]|{expression}] — хеш с полями или выражение для groupBy
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
           ^pfAssert:isTrue(def $_primaryKey){Не определен первичный ключ для таблицы ${TABLE_NAME}. Выборку можно делать только в таблицу.}
#             Для хеша добавляем еще одно поле с первичным ключем
            $PRIMARYKEY as ^_builder.quoteIdentifier[_ORM_HASH_KEY_],
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
    $lGroup[^_allGroup[$aOptions]]
    $lOrder[^_allOrder[$aOptions]]
    $lHaving[^if(^aOptions.contains[having]){$aOptions.having}{^_allHaving[$aOptions]}]
  }

  $result[
       select $aFields
         from ^_builder.quoteIdentifier[$TABLE_NAME] as ^_builder.quoteIdentifier[$TABLE_ALIAS]
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
    $.tableAlias[$TABLE_ALIAS]
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
  $lConds[^_buildConditions[$aOptions]]
  $result[^if(^aOptions.contains[where]){$aOptions.where}{1=1}^if(def $lConds){ and $lConds}]

@_allHaving[aOptions]
  $result[]

@_allGroup[aOptions][locals]
## aOptions.groupBy
  ^if(^aOptions.contains[groupBy]){
    $lGroup[$aOptions.groupBy]
  }{
    $lGroup[$_defaultGroupBy]
  }
  ^switch(true){
    ^case($lGroup is hash){$result[^lGroup.foreach[k;v]{^if(^_fields.contains[$k]){^_sqlFieldName[$k]^if(^v.lower[] eq "desc"){desc}(^v.lower[] eq "asc"){asc}}}[, ]]}
    ^case[DEFAULT]{$result[^lGroup.trim[]]}
  }

@_allOrder[aOptions][locals]
## aOptions.orderBy
  ^if(^aOptions.contains[orderBy]){
    $lOrder[$aOptions.orderBy]
  }(def $_defaultOrderBy){
    $lOrder[$_defaultOrderBy]
  }{
     $lOrder[^if(def $_primaryKey){$PRIMARYKEY asc}]
   }
  ^switch(true){
    ^case($lOrder is hash){$result[^lOrder.foreach[k;v]{^if(^_fields.contains[$k]){^_sqlFieldName[$k] ^if(^v.lower[] eq "desc"){desc}{asc}}}[, ]]}
    ^case[DEFAULT]{$result[^lOrder.trim[]]}
  }

#----- Манипуляция данными -----

@new[aData;aSQLOptions]
## Вставляем значение в базу
## aSQLOptions.ignore(true)
## Возврашает автосгенерированное значение первичного ключа (last_insert_id) для sequence-полей.
  ^cleanMethodArgument[aData;aSQLOptions]
  $result[^CSQL.void{^_builder.insertStatement[$TABLE_NAME;$_fields;$aData;^hash::create[$aSQLOptions] $.skipFields[$_skipOnInsert]]}]
  ^if(def $_primaryKey && $_fields.[$_primaryKey].sequence){
    $result[^CSQL.lastInsertId[]]
  }

@modify[aPrimaryKeyValue;aData]
## Изменяем запись с первичныйм ключем aPrimaryKeyValue в таблице
  ^pfAssert:isTrue(def $_primaryKey){Не определен первичный ключ для таблицы ${TABLE_NAME}.}
  ^pfAssert:isTrue(def $aPrimaryKeyValue){Не задано значение первичного ключа}
  ^cleanMethodArgument[aData]
  $result[^CSQL.void{
    ^_builder.updateStatement[$TABLE_NAME;$_fields;$aData][$PRIMARYKEY = ^_fieldValue[$_fields.[$_primaryKey];$aPrimaryKeyValue]][
      $.skipAbsent(true)
      $.skipFields[$_skipOnUpdate]
      $.emptySetExpression[$PRIMARYKEY = $PRIMARYKEY]
    ]
  }]

@delete[aPrimaryKeyValue]
## Удаляем запись из таблицы с первичныйм ключем aPrimaryKeyValue
  ^pfAssert:isTrue(def $_primaryKey){Не определен первичный ключ для таблицы ${TABLE_NAME}.}
  ^pfAssert:isTrue(def $aPrimaryKeyValue){Не задано значение первичного ключа}
  $result[^CSQL.void{
    delete from $TABLE_NAME where $PRIMARYKEY = ^_fieldValue[$_fields.[$_primaryKey];$aPrimaryKeyValue]
  }]


#----- Групповые операции с данными -----

@modifyAll[aOptions;aData]
## Изменяем все записи
## Условие обновления берем из _allWhere
  ^cleanMethodArgument[aOptions;aData]
  $result[^CSQL.void{
    ^_builder.updateStatement[$TABLE_NAME;$_fields;$aData][
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
    delete from $TABLE_NAME
     where ^_allWhere[$aOptions]
  }]


#----- Private -----

@_fieldValue[aField;aValue]
## aField — имя или хеш с полем
  ^if($aField is string){
    $aField[$_fields.[$aField]]
  }
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
     $result[$lField.expression^if($__context eq "select"){ as ^_builder.quoteIdentifier[$aFieldName]}]
  }{
     ^if(!^lField.contains[dbField]){
       ^throw[pfSQLTable.field.fail;Для поля «${aFieldName}» не задано выражение или имя в базе данных.]
     }
     $result[^_builder.sqlFieldName[$lField;^if($__context eq "where" || $__context eq "select"){$TABLE_ALIAS}]]
   }

@_asContext[aContext;aCode][locals]
  $lOldContext[$self.__context]
  $self.__context[$aContext]
  $result[$aCode]
  $self.__context[$lOldContext]

@_buildConditions[aConds;aOP][locals]
## Строим выражение для сравнения
## aOp[AND|OR|NOT]
  ^cleanMethodArgument[aConds]
  $result[]

  $lConds[^hash::create[]]
  $_res[^hash::create[]]

  ^aConds.foreach[k;v]{
    ^k.match[$_PFSQLTABLE_COMPARSION_REGEX][]{
      ^if(^_fields.contains[$match.1] && !def $match.2 || ^_PFSQLTABLE_OPS.contains[$match.2]){
#       $.[field operator][value]
        $lField[$_fields.[$match.1]]
        $_res.[^_res._count[]][^_sqlFieldName[$match.1] $_PFSQLTABLE_OPS.[$match.2] ^_fieldValue[$lField;$v]]
      }(^_fields.contains[$match.1] && $match.2 eq "is"){
        $_res.[^_res._count[]][^_sqlFieldName[$match.1] is ^if(!def $v || $v eq "null"){null}{not null}]
      }(^_plurals.contains[$match.1]
        || (^_fields.contains[$match.1] && ($match.2 eq "in" || $match.2 eq "!in"))
       ){
#       $.[field [!]in][hash|table|values string]
#       $.[plural [not]][hash|table|values string]
        $_res.[^_res._count[]][^_condArrayField[$aConds;$match.1;^match.2.lower[];$v]]
      }($match.1 eq "OR" || $match.1 eq "AND" || $match.1 eq "NOT"){
#       Рекурсивный вызов логического блока
        $_res.[^_res._count[]][^_buildConditions[$v;$match.1]]
      }
    }
  }
  $result[^if($_res){^if($aOP eq "NOT"){not} (^_res.foreach[k;v]{$v}[ $_PFSQLTABLE_LOGICAL.[$aOP] ])}]

@_condArrayField[aConds;aFieldName;aOperator;aValue][locals]
  $lField[^if(^_plurals.contains[$aFieldName]){$_plurals.[$aFieldName]}{$_fields.[$aFieldName]}]
  $lColumn[^if(^aConds.contains[${aFieldName}Column]){$aConds.[${aFieldName}Column]}{$lField.name}]
  $result[^_sqlFieldName[$lField.name] ^if($aOperator eq "not" || $aOperator eq "!in"){not in}{in} (^_valuesArray[$lField.name;$aValue;$.column[$lColumn]])]
