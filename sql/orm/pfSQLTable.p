# PF Library

## Шлюз таблицы данных (Table Data Gateway).

@CLASS
pfSQLTable

#@compat 3.4.2
#@compat_db mysql, sqlite

@USE
pf/types/pfClass.p
pf/tests/pfAssert.p
pf/sql/orm/pfSQLBuilder.p

@BASE
pfClass

@create[aTableName;aOptions][k;v]
## aOptions.sql
## aOptions.tableAlias
## aOptions.schema — название базы данных (можно не указывать).
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

  $_schema[^aOptions.schema.trim[]]

  $_tableName[$aTableName]
  $_tableAlias[^if(def $aOptions.tableAlias){$aOptions.tableAlias}(def $_schema){${_schema}_$_tableName}]
  $_primaryKey[^if(def $aOptions.primaryKey){$aOptions.primaryKey}]

  $_fields[^hash::create[]]
  $_plurals[^hash::create[]]
  ^if(^aOptions.contains[fields]){
    ^addFields[$aOptions.fields]
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
  $_PFSQLTABLE_AGR_REGEX[^regex::create[^^\s*(([^^\s(]+)(.*?)?)\s*(?:as\s+(\S+))?\s*^$][i]]
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
## aOptions.dbField[aFieldName] — название поля
## aOptions.fieldExpression{} — выражение для названия поля
## aOptions.expression{} — sql-выражение для значения поля (если не определено, то используем fieldExpression)
## aOptions.plural[] — название поля для групповой выборки
## aOptions.processor — процессор
## aOptions.default — значение «по-умолчанию»
## aOptions.format — формат числового значения
## aOptions.primary(false) — первичный ключ
## aOptions.sequence(true) — последовательность формирует БД (автоинкремент; только для первичного ключа)
## aOptions.skipOnInsert(false) — пропустить при вставке
## aOptions.skipOnUpdate(false) — пропустить при обновлении
## aOptions.label[aFieldName] — текстовое название поля (например, для форм)
## aOptions.comment — описание поля
## aOptions.widget — название html-виджета для редактирования поля.
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

  $lField.label[^if(def $aOptions.label){$aOptions.label}{$lField.name}]
  $lField.comment[$aOptions.comment]
  $lField.widget[$aOptions.widget]

  ^if(^aOptions.contains[fieldExpression] || ^aOptions.contains[expression]){
     ^if(def $aOptions.dbField){$lField.dbField[$aOptions.dbField]}
     $lField.fieldExpression[$aOptions.fieldExpression]
     $lField.expression[$aOptions.expression]
     ^if(!def $lField.expression){
       $lField.expression[$lField.fieldExpression]
     }
     ^if(!def $lField.dbField){
       $self._skipOnUpdate.[$aFieldName](true)
       $self._skipOnInsert.[$aFieldName](true)
     }
  }{
     $lField.dbField[^if(def $aOptions.dbField){$aOptions.dbField}{$aFieldName}]
     $lField.primary(^aOptions.primary.bool(false))
     $lField.sequence($lField.primary && ^aOptions.sequence.bool(true))
     ^if(^aOptions.skipOnUpdate.bool(false) || $lField.primary){
       $self._skipOnUpdate.[$aFieldName](true)
     }
     ^if(^aOptions.skipOnInsert.bool(false) || $lField.sequence){
       $self._skipOnInsert.[$aFieldName](true)
     }
     ^if(def $lField.primary && !def $_primaryKey){
       $self._primaryKey[$aFieldName]
     }
   }
  $_fields.[$aFieldName][$lField]
  ^if(def $lField.plural){
    $_plurals.[$lField.plural][$lField]
  }

@addFields[aFields][locals]
## Добавляет сразу несколько полей
## aFields[hash]
  ^cleanMethodArgument[aFields]
  $result[]
  ^aFields.foreach[k;v]{
    ^addField[$k;$v]
  }

@cleanFormData[aFormData]
## Возвращает хеш с полями, для которых разрешены html-виджеты.
  ^cleanMethodArgument[aFormData]
  $result[^hash::create[]]
  ^aFormData.foreach[k;v]{
    ^if(^_fields.contains[$k]
        && $_fields.[$k].widget ne "none"
    ){
      $result.[$k][$v]
    }
  }


#----- Свойства -----

@GET_SCHEMA[]
  $result[$_schema]

@GET_TABLE_NAME[]
  ^pfAssert:isTrue(def $_tableName){Не задано имя таблицы в классе $self.CLASS_NAME}
  $result[$_tableName]

@GET_TABLE_ALIAS[]
  ^if(!def $_tableAlias){
    $_tableAlias[$TABLE_NAME]
  }
  $result[$_tableAlias]

@GET_TABLE_EXPRESSION[]
  $result[^if(def $SCHEMA){^_builder.quoteIdentifier[$SCHEMA].}^_builder.quoteIdentifier[$TABLE_NAME] as ^_builder.quoteIdentifier[$TABLE_ALIAS]]

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
 $lResultType[^__getResultType[$aOptions]]
 $result[^CSQL.[$lResultType]{
   ^_selectExpression[
     ^__allSelectFieldsExpression[$lResultType;$aOptions;$aSQLOptions]
   ][$lResultType;$aOptions;$aSQLOptions]
 }[
    ^if(^aOptions.contains[limit]){$.limit($aOptions.limit)}
    ^if(^aOptions.contains[offset]){$.offset($aOptions.offset)}
  ][$aSQLOptions]]]

@__getResultType[aOptions]
  $result[^switch(true){
    ^case(^aOptions.asTable.bool(false)){table}
    ^case(^aOptions.asHash.bool(false)){hash})
    ^case[DEFAULT]{$_defaultResultType}
  }]

@union[*aConds][locals]
## Выполняет несколько запросов и объединяет их в один результат.
## Параметр aSQLOptions не поддерживается!
## Тип результата берем из самого первого условия.
  ^pfAssert:isTrue($aConds){Надо задать как-минимум одно условие выборки.}
  $result[]
  $lResultType[^__getResultType[^hash::create[$aConds.0]]]

  ^aConds.foreach[k;v]{
    $v[^hash::create[$v]]
    $lRes[^CSQL.[$lResultType]{
      ^_selectExpression[
        ^__allSelectFieldsExpression[$lResultType;$v]
      ][$lResultType;$v]
    }[
       ^if(^v.contains[limit]){$.limit($v.limit)}
       ^if(^v.contains[offset]){$.offset($v.offset)}
    ]]
    ^if($k eq "0"){
      $result[$lRes]
    }($lResultType eq "table"){
      ^result.join[$lRes]
    }($lResultType eq "hash"){
      ^result.add[$lRes]
    }
  }

#----- Агрегации -----

@count[aConds;aSQLOptions][locals]
## Возвращает количество записей в таблице
  ^cleanMethodArgument[aConds;aSQLOptions]
  $result[^CSQL.int{
    ^_selectExpression[count(*)][;$aConds;$aSQLOptions]
  }[
    ^if(^aOptions.contains[limit]){$.limit($aConds.limit)}
    ^if(^aOptions.contains[offset]){$.offset($aConds.offset)}
  ][$aSQLOptions]]]

@aggregate[*aConds][locals]
## Выборки с группировкой
## ^aggregate[func(expr) as alias;_fields(field1, field2 as alias2);_fields(*);conditions hash;sqlOptions]
  $lConds[^__getAgrConds[$aConds]]
  $lResultType[^__getResultType[$lConds.options]]
  $result[^CSQL.[$lResultType]{
    ^_selectExpression[
      ^_asContext[select]{^__getAgrFields[$lConds.fields]}
    ][$lResultType;$lConds.options;$lConds.sqlOptions]
  }[
     ^if(^lConds.options.contains[limit]){$.limit($lConds.options.limit)}
     ^if(^lConds.options.contains[offset]){$.offset($lConds.options.offset)}
   ][$lConds.sqlOptions]]]

#----- Манипуляции с данными -----

@new[aData;aSQLOptions]
## Вставляем значение в базу
## aSQLOptions.ignore(false)
## Возврашает автосгенерированное значение первичного ключа (last_insert_id) для sequence-полей.
  ^cleanMethodArgument[aData;aSQLOptions]
  ^_asContext[update]{
    $result[^CSQL.void{^_builder.insertStatement[$TABLE_NAME;$_fields;$aData;^hash::create[$aSQLOptions] $.skipFields[$_skipOnInsert] $.schema[$SCHEMA]]}]
  }
  ^if(def $_primaryKey && $_fields.[$_primaryKey].sequence){
    $result[^CSQL.lastInsertId[]]
  }

@modify[aPrimaryKeyValue;aData]
## Изменяем запись с первичныйм ключем aPrimaryKeyValue в таблице
  ^pfAssert:isTrue(def $_primaryKey){Не определен первичный ключ для таблицы ${TABLE_NAME}.}
  ^pfAssert:isTrue(def $aPrimaryKeyValue){Не задано значение первичного ключа}
  ^cleanMethodArgument[aData]
  $result[^CSQL.void{
    ^_asContext[update]{
      ^_builder.updateStatement[$TABLE_NAME;$_fields;$aData][$PRIMARYKEY = ^_fieldValue[$_fields.[$_primaryKey];$aPrimaryKeyValue]][
        $.skipAbsent(true)
        $.skipFields[$_skipOnUpdate]
        $.emptySetExpression[$PRIMARYKEY = $PRIMARYKEY]
        $.schema[$SCHEMA]
      ]
    }
  }]

@newOrModify[aData;aSQLOptions]
## Аналог мускулевского "insert on duplicate key update"
## Пытаемся создать новую запись, а если она существует, то обновляем данные.
## Работает только для таблиц с первичным ключем.
  $result[]
  ^cleanMethodArgument[aSQLOptions]
  ^pfAssert:isTrue(def $_primaryKey){Не определен первичный ключ для таблицы ${TABLE_NAME}.}
  ^CSQL.safeInsert{
     $result[^new[$aData;$aSQLOptions]]
  }{
      ^modify[$aData.[$_primaryKey];$aData]
      $result[$aData.[$_primaryKey]]
   }

@delete[aPrimaryKeyValue]
## Удаляем запись из таблицы с первичныйм ключем aPrimaryKeyValue
  ^pfAssert:isTrue(def $_primaryKey){Не определен первичный ключ для таблицы ${TABLE_NAME}.}
  ^pfAssert:isTrue(def $aPrimaryKeyValue){Не задано значение первичного ключа}
  $result[^CSQL.void{
    ^_asContext[update]{
      delete from ^if(def $SCHEMA){^_builder.quoteIdentifier[$SCHEMA].}^_builder.quoteIdentifier[$TABLE_NAME] where $PRIMARYKEY = ^_fieldValue[$_fields.[$_primaryKey];$aPrimaryKeyValue]
    }
  }]


#----- Групповые операции с данными -----

@modifyAll[aOptions;aData]
## Изменяем все записи
## Условие обновления берем из _allWhere
  ^cleanMethodArgument[aOptions;aData]
  $result[^CSQL.void{
    ^_asContext[update]{
      ^_builder.updateStatement[$TABLE_NAME;$_fields;$aData][
        ^_allWhere[$aOptions]
      ][
        $.schema[$SCHEMA]
        $.skipAbsent(true)
        $.skipFields[$_skipOnUpdate]
        $.emptySetExpression[]
      ]
    }
  }]

@deleteAll[aOptions]
## Удаляем все записи из таблицы
## Условие для удаления берем из _allWhere
  ^cleanMethodArgument[]
  $result[^CSQL.void{
    ^_asContext[update]{
      delete from ^if(def $SCHEMA){^_builder.quoteIdentifier[$SCHEMA].}^_builder.quoteIdentifier[$TABLE_NAME]
       where ^_allWhere[$aOptions]
    }
  }]


#----- Private -----
## Методы с префиксом _all используются для построения частей выражений выборки.
## Их можно перекрывать в наследниках смело, но не рекомендуется их использовать
## напрямую во внешнем коде.

@_allFields[aOptions;aSQLOptions]
  ^cleanMethodArgument[aOptions;aSQLOptions]
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
  ^_asContext[group]{
    ^switch(true){
      ^case($lGroup is hash){$result[^lGroup.foreach[k;v]{^if(^_fields.contains[$k]){^_sqlFieldName[$k]^if(^v.lower[] eq "desc"){ desc}(^v.lower[] eq "asc"){ asc}}}[, ]]}
      ^case[DEFAULT]{$result[^lGroup.trim[]]}
    }
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
  ^_asContext[group]{
    ^switch(true){
      ^case($lOrder is hash){$result[^lOrder.foreach[k;v]{^if(^_fields.contains[$k]){^_sqlFieldName[$k] ^if(^v.lower[] eq "desc"){desc}{asc}}}[, ]]}
      ^case[DEFAULT]{$result[^lOrder.trim[]]}
    }
  }

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
  ^pfAssert:isTrue(^_fields.contains[$aFieldName]){Неизвестное поле «${aFieldName}».}
  $lField[$_fields.[$aFieldName]]
  ^if($__context eq "where"
      && ^lField.contains[fieldExpression]
      && def $lField.fieldExpression){
    $result[$lField.fieldExpression]
  }(^lField.contains[expression]
    && def $lField.expression
   ){
     ^if($__context eq "group"){
       $result[$lField.name]
     }{
        $result[$lField.expression]
      }
  }{
     ^if(!^lField.contains[dbField]){
       ^throw[pfSQLTable.field.fail;Для поля «${aFieldName}» не задано выражение или имя в базе данных.]
     }
     $result[^_builder.sqlFieldName[$lField;^if($__context ne "update"){$TABLE_ALIAS}]]
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
      $lField[$_fields.[$match.1]]
      ^if(^_fields.contains[$match.1] && !def $match.2 || ^_PFSQLTABLE_OPS.contains[$match.2]){
#       $.[field operator][value]
        $_res.[^_res._count[]][^_sqlFieldName[$match.1] $_PFSQLTABLE_OPS.[$match.2] ^_fieldValue[$lField;$v]]
      }($match.2 eq "range"){
#       $.[field range][$.from $.to]
        $_res.[^_res._count[]][^_sqlFieldName[$match.1] between ^_fieldValue[$lField;$v.from] and ^_fieldValue[$lField;$v.to]]
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

@_selectExpression[aFields;aResultType;aOptions;aSQLOptions][locals]
  ^_asContext[where]{
    $lGroup[^_allGroup[$aOptions]]
    $lOrder[^_allOrder[$aOptions]]
    $lHaving[^if(^aOptions.contains[having]){$aOptions.having}{^_allHaving[$aOptions]}]
  }

  $result[
       select $aFields
         from ^if(def $SCHEMA){^_builder.quoteIdentifier[$SCHEMA].}^_builder.quoteIdentifier[$TABLE_NAME] as ^_builder.quoteIdentifier[$TABLE_ALIAS]
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

#----- Вспомогательные методы (deep private :) -----
## Методы, начинаююшиеся с двух подчеркиваний сугубо внутренние,
## желательно их не перекрывать и ни при каких условиях не использовать
## во внешнем коде.

@__allSelectFieldsExpression[aResultType;aOptions;aSQLOptions]
  $result[
    ^_asContext[select]{
     ^if(def $aSQLOptions.selectОptions){$aSQLOptions.selectОptions}
     ^if(^aOptions.contains[selectFields]){
       $aOptions.selectFields
     }{
       ^if($aResultType eq "hash"){
         ^pfAssert:isTrue(def $_primaryKey){Не определен первичный ключ для таблицы ${TABLE_NAME}. Выборку можно делать только в таблицу.}
#         Для хеша добавляем еще одно поле с первичным ключем
          $PRIMARYKEY as ^_builder.quoteIdentifier[_ORM_HASH_KEY_],
       }
       $lJoinFields[^_allJoinFields[$aOptions]]
       ^_allFields[$aOptions;$aSQLOptions]^if(def $lJoinFields){, $lJoinFields}
      }
    }
  ]

@__getAgrConds[aConds][locals]
  $result[$.fields[^hash::create[]] $.options[] $.sqlOptions[]]
  ^aConds.foreach[k;v]{
    ^switch[$v.CLASS_NAME]{
      ^case[string]{
        $result.fields.[^eval($result.fields)][$v]
      }
      ^case[hash]{
        ^if(!def $result.options){
          $result.options[$v]
        }(def $result.options && !def $result.sqlOptions){
          $result.sqlOptions[$v]
        }
      }
    }
  }
  ^if(!def $result.options){$result.options[^hash::create[]]}
  ^if(!def $result.sqlOptions){$result.sqlOptions[^hash::create[]]}

@__getAgrFields[aFields][locals]
  $result[^hash::create[]]
  ^aFields.foreach[k;v]{
    ^v.match[$_PFSQLTABLE_AGR_REGEX][]{
      $lField[
        $.expr[$match.1]
        $.function[$match.2]
        $.args[^match.3.trim[both;() ]]
        $.alias[$match.4]
      ]
      ^if(^lField.function.lower[] eq "_fields"){
        ^if(^lField.args.trim[] eq "*"){
          $lField.expr[^_allFields[]]
        }{
           $lSplit[^lField.args.split[,;lv]]
           $lField.expr[^lSplit.menu{^lSplit.piece.match[$_PFSQLTABLE_AGR_REGEX][]{^if(def $match.1){^_sqlFieldName[$match.1] as ^_builder.quoteIdentifier[^if(def $match.4){$match.4}{$match.1}]}}}[, ]]
           $lField.alias[]
         }
      }
      $result.[^result._count[]][$lField]
    }
  }
  $result[^result.foreach[k;v]{$v.expr^if(def $v.alias){ as ^_builder.quoteIdentifier[$v.alias]}}[, ]]
