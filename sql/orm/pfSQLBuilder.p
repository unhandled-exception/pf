# PF Library

## Класс для упрощения построения сложных sql-запросов.

@CLASS
pfSQLBuilder

#@compat 3.4.2

@USE
pf/types/pfClass.p
pf/tests/pfAssert.p

@BASE
pfClass

@create[aOptions]
## aOptions.quoteStyle[mysql|ansi] — стиль «кавычек» для идентификаторов (default: mysql)
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]

  $_quote[]
  ^_setQuoteStyle[^if(def $aOptions.quoteStyle){^aOptions.quoteStyle.lower[]}]

  $_now[^date::now[]]
  $_today[^date::today[]]

@auto[][lSeparator;lEncloser]
  $_PFSQLBUILDER_CSV_REGEX_[^regex::create[((?:\s*"(?:[^^"]*|"{2})*"\s*(?:,|^$))|\s*"[^^"]*"\s*(?:,|^$)|[^^,]+(?:,|^$)|(?:,))][g]]
  $_PFSQLBUILDER_CSV_QTRIM_REGEX_[^regex::create["(.*)"][]]

@_setQuoteStyle[aStyle]
  $result[]
  ^switch[$aStyle]{
    ^case[ansi]{$_quote["]}
    ^case[DEFAULT;mysql]{$_quote[`]}
  }

#----- Работа с полями -----

## Формат описания полей
## aFields[
##   $.fieldName[ <- Имя поля в прорамме
##     $.dbField[field_name] <- Имя поля в базе
##     $.processor[int|bool|curdate|curtime|...] <- Как обрабатывать поле при присвоении (по-умолчанию "^taint[value]")
##     $.format[] — форматная строка для процессоров (числа)
##     $.default[] <- Значение по-умолчанию (if !def).
##     $.expression{}
##   ]
## ]
##
## Процессоры:
##   int - целое число, если не задан default, то приведение делаем без значения по-умолчанию
##   double - целое число, если не задан default, то приведение делаем без значения по-умолчанию
##   bool - 1/0
##   datetime - дата и время (если нам передали дату, то делаем sql-string)
##   date - дата (если нам передали дату, то делаем sql-string[date])
##   time - время (если нам передали дату, то делаем sql-string[time])
##   now - текущие дата время (если не задано значение поля)
##   curtime - текущее время (если не задано значение поля)
##   curdate - текущая дата (если не задано значение поля)
##   json - сереиализует значение в json
##   null - если не задано значение, то возвращает null.
##   uint_null - преобразуем зачение в целое без знака, если не задано значение, то возвращаем null
##   uid - уникальный идентификатор (math:uuid)

@_processFieldsOptions[aOptions]
  $result[^hash::create[$aOptions]]
  $result.skipNames(^aOptions.skipNames.bool(false))
  $result.skipAbsent(^aOptions.skipAbsent.bool(false))
  $result.skipFields[^hash::create[$aOptions.skipFields]]

@quoteIdentifier[aIdent]
  $result[${_quote}${aIdent}${_quote}]

@sqlFieldName[aField;aTableAlias][locals]
  $result[^if(def $aTableAlias){^quoteIdentifier[$aTableAlias].}^quoteIdentifier[^taint[$aField.dbField]]]

@selectFields[aFields;aOptions][locals]
## Возвращает список полей для выражения select
## aOptions.tableAlias
## aOptions.skipFields[$.field[] ...] — хеш с полями, которые надо исключить из выражения
  ^pfAssert:isTrue(def $aFields){Не задан список полей.}
  $aOptions[^_processFieldsOptions[$aOptions]]
  $lTableAlias[^if(def $aOptions.tableAlias){$aOptions.tableAlias}]

  $result[^hash::create[]]
  $lFields[^hash::create[$aFields]]
  ^aFields.foreach[k;v]{
    ^if(^aOptions.skipFields.contains[$k]){^continue[]}
    ^if(^v.contains[expression]){
      $result.[^result._count[]][$v.expression as ^quoteIdentifier[$k]]
    }{
       $result.[^result._count[]][^sqlFieldName[$v;$lTableAlias] as ^quoteIdentifier[$k]]
     }
  }
  $result[^result.foreach[k;v]{$v}[, ]]

@fieldsList[aFields;aOptions][locals]
## Возвращает список полей
## aOptions.tableAlias
## aOptions.skipFields[$.field[] ...] — хеш с полями, которые надо исключить из выражения
## aOptions.skipAbsent(false) - пропустить поля, данных для которых нет (нaдо обязательно задать поле aOptions.data)
## aOptions.data - хеш с данными
  ^pfAssert:isTrue(def $aFields){Не задан список полей.}
  $aOptions[^_processFieldsOptions[$aOptions]]
  $lData[^if(def $aOptions.data){$aOptions.data}{^hash::create[]}]
  $lTableAlias[^if(def $aOptions.tableAlias){$aOptions.tableAlias}]
  $result[^hash::create[]]
  ^aFields.foreach[k;v]{
    ^if(^v.contains[expression]){^continue[]}
    ^if($aOptions.skipAbsent && !^lData.contains[$k] && !(def $v.processor && ^v.processor.pos[auto_] >= 0)){^continue[]}
    ^if(^aOptions.skipFields.contains[$k]){^continue[]}
    $result.[${_quote}^result._count[]][^sqlFieldName[$v;$lTableAlias]]
  }
  $result[^result.foreach[k;v]{$v}[, ]]

@setExpression[aFields;aData;aOptions][locals]
## Возвращает выражение для присвоения значения (field = vale, ...)
## aOptions.tableAlias
## aOptions.skipAbsent(false) - пропустить поля, данных для которых нет
## aOptions.skipFields[$.field[] ...] — хеш с полями, которые надо исключить из выражения
## aOptions.skipNames(false) - не выводить имена полей, только значения (для insert values)
  ^pfAssert:isTrue(def $aFields){Не задан список полей.}
  ^cleanMethodArgument[aData;aOptions]
  $aOptions[^_processFieldsOptions[$aOptions]]
  $lAlias[^if(def $aOptions.alias){${aOptions.alias}}]

  $result[^hash::create[]]
  ^aFields.foreach[k;v]{
    ^if(^aOptions.skipFields.contains[$k] || ^v.contains[expression]){^continue[]}
    ^if($aOptions.skipAbsent && !^aData.contains[$k] && !(def $v.processor && ^v.processor.pos[auto_] >= 0)){^continue[]}
    $result.[^result._count[]][^if(!$aOptions.skipNames){^sqlFieldName[$v;$lAlias] = }^fieldValue[$v;^if(^aData.contains[$k]){$aData.[$k]}]]
  }
  $result[^result.foreach[k;v]{$v}[, ]]

@fieldValue[aField;aValue][locals]
## Возвращает значение поля в sql-формате.
  ^pfAssert:isTrue(def $aField){Не задано описание поля.}
  ^try{
    $result[^switch[^if(def $aField.processor){^aField.processor.lower[]}]{
      ^case[int;auto_int]{^eval(^if(^aField.contains[default]){^aValue.int($aField.default)}{^aValue.int[]})[^if(def $aField.format){$aField.format}{%d}]}
      ^case[double;auto_double]{^eval(^if(^aField.contains[default]){^aValue.double($aField.default)}{^aValue.double[]})[^if(def $aField.format){$aField.format}{%f}]}
      ^case[bool;auto_bool]{^if(^aValue.bool(^if(^aField.contains[default]){$aField.default}{false})){1}{0}}
      ^case[now;auto_now]{^if(def $aValue){'^if($aValue is date){^aValue.sql-string[]}{^taint[$aValue]}'}{'^_now.sql-string[]'}}
      ^case[cuttime;auto_curtime]{'^if(def $aValue){^if($aValue is date){^aValue.sql-string[time]}{^taint[$aValue]}}{^_now.sql-string[time]}'}
      ^case[cutdate;auto_curdate]{'^if(def $aValue){^if($aValue is date){^aValue.sql-string[date]}{^taint[$aValue]}}{^_now.sql-string[date]}'}
      ^case[datetime]{'^if($aValue is date){^taint[$aValue]}{^aValue.sql-string[]}'}
      ^case[date]{'^if($aValue is date){^taint[$aValue]}{^aValue.sql-string[date]}'}
      ^case[time]{'^if($aValue is date){^taint[$aValue]}{^aValue.sql-string[time]}'}
      ^case[json]{'^taint[^json:string[$aValue]]'}
      ^case[null]{^if(def $aValue){'^taint[$aValue]'}{null}}
      ^case[uint_null]{^if(^aValue.int(-1) >= 0){^aValue.int[]}{null}}
      ^case[uid;auto_uid]{'^taint[^if(def $aValue){$aValue}{^math:uuid[]}']}
      ^case[DEFAULT;auto_default]{'^taint[^if(def $aValue){$aValue}(def $aField.default){$aField.default}]'}
    }]
  }{
     ^throw[pfSQLBuilder.bad.value;Ошибка при преобразовании поля ${aField.name} (processor: ^if(def $aField.processor){$aField.processor}{default}^; value type: $aValue.CLASS_NAME);[${exception.type}] ${exception.source}, ${exception.comment}.]
   }

@array[aField;aValue;aOptions][locals]
## Строит массив значений
## aValue[table|hash|csv-string]
## aOptions.column[primaryKey] — имя колонки в таблице
## aOptions.emptyValue[null] — значение массива, если в aValue нет данных
## aOptions.valueFunction[fieldValue] — функция форматирования значения поля
  ^cleanMethodArgument[]
  $result[]
  $lValueFunction[^if(^aOptions.contains[valueFunction]){$aOptions.valueFunction}{$fieldValue}]
  $lEmptyValue[^if(^aOptions.contains[emptyValue]){$aOptions.emptyValue}{null}]
  $lColumn[^if(def $aOptions.column){$aOptions.column}{primaryKey}]
  ^switch(true){
    ^case($aValue is hash){$result[^aValue.foreach[k;v]{^lValueFunction[$aField;$k]}[, ]]}
    ^case($aValue is table){$result[^aValue.menu{^lValueFunction[$aField;$aValue.[$lColumn]]}[, ]]}
    ^case($aValue is string){
      $lItems[^_parseCSVString[$aValue]]
      $result[^lItems.foreach[k;v]{^lValueFunction[$aField;$v]}[, ]]
    }
    ^case[DEFAULT]{
      ^throw[pfSQLBuilder.bad.array.values;Значениями массива может быть хеш, таблица или csv-строка.]
    }
  }]
  ^if(!def $result && def $lEmptyValue){
    $result[$lEmptyValue]
  }

@_parseCSVString[aString][loacals]
# $result[$.0[] $.1[] ...]
  $result[^hash::create[]]
  ^aString.match[$_PFSQLBUILDER_CSV_REGEX_][]{
    $lValue[^match.1.trim[right;,]]
    $lValue[^lValue.match[$_PFSQLBUILDER_CSV_QTRIM_REGEX_][]{^match.1.replace[""]["]}]
    $result.[^result._count[]][$lValue]
  }

#----- Построение sql-выражений -----

@insertStatement[aTableName;aFields;aData;aOptions][locals]
## Строит выражение insert into values
## aTableName - имя таблицы
## aFields - поля
## aData - данные
## aOptions.skipFields[$.field[] ...] — хеш с полями, которые надо исключить из выражения
## aOptions.ignore(true)
  ^pfAssert:isTrue(def $aTableName){Не задано имя таблицы.}
  ^pfAssert:isTrue(def $aFields){Не задан список полей.}
  ^cleanMethodArgument[aData;aOptions]
  $lOpts[^if(^aOptions.ignore.bool(false)){ignore}]
  $result[insert $lOpts into $aTableName (^fieldsList[$aFields;^hash::create[$aOptions] $.data[$aData]]) values (^setExpression[$aFields;$aData;^hash::create[$aOptions] $.skipNames(true)])]

@updateStatement[aTableName;aFields;aData;aWhere;aOptions][locals]
## Строит выражение для update
## aTableName - имя таблицы
## aFields - поля
## aData - данные
## aWhere - выражение для where
##          (для безопасности блок where задается принудительно,
##           если нужно иное поведение укажите aWhere[1=1])
## aOptions.skipAbsent(false) - пропустить поля, данных для которых нет
## aOptions.skipFields[$.field[] ...] — хеш с полями, которые надо исключить из выражения
## aOptions.emptySetExpression[выражение, которое надо подставить, если нет данных для обновления]
  ^pfAssert:isTrue(def $aTableName){Не задано имя таблицы.}
  ^pfAssert:isTrue(def $aFields){Не задан список полей.}
  ^pfAssert:isTrue(def $aWhere){Не задано выражение для where.}
  ^cleanMethodArgument[aData;aOptions]

  $lSetExpression[^setExpression[$aFields;$aData;$aOptions]]
  ^pfAssert:isTrue(def $lSetExpression || (!def $lSetExpression && def $aOptions.emptySetExpression)){Необходимо задать выражение для пустого update set.}
  $result[update $aTableName set ^if(def $lSetExpression){$lSetExpression}{$aOptions.emptySetExpression} where $aWhere]
