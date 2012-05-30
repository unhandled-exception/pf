# PF Library

## Класс для упрощения построения сложных sql-запросов.
#! BETA

@CLASS
pfSQLBuilder

@USE
pf/types/pfClass.p
pf/tests/pfAssert.p

@BASE
pfClass

@create[aOptions]
## aOptions.createdAtField[created_at]
## aOptions.createdAtAlias[createdAt]
## aOptions.updatedAtField[updated_at]
## aOptions.updatedAtAlias[updatedAt]
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]

  $_now[^date::now[]]
  $_today[^date::today[]]

## Имена полей и алиасов для автоматически-добавляемых полей created_at и updated_at
  $_createdAtField[^if(def $aOptions.createdAtField){$aOptions.createdAtField}{created_at}]
  $_createdAtAlias[^if(def $aOptions.createdAtAlias){$aOptions.createdAtAlias}{createdAt}]
  $_updatedAtField[^if(def $aOptions.updatedAtField){$aOptions.updatedAtField}{updated_at}]
  $_updatedAtAlias[^if(def $aOptions.updatedAtAlias){$aOptions.updatedAtAlias}{updatedAt}]

@auto[]
  $_pfSQLBuilderPatternVar[((?:[:\*])\{?([\p{L}\p{Nd}_\-]+)\}?)]
  $_pfSQLBuilderPatternRegex[^regex::create[$_pfSQLBuilderPatternVar][g]]

#----- Работа с полями -----

## Формат описания полей
## aFields[
##   $.fieldName[ <- Имя поля в прорамме
##     $.dbf[field_name] <- Имя поля в базе
##     $.processor[int|bool|curdate|curtime|...] <- Как обрабатывать поле при присвоении (по-умолчанию "^taint[value]")
##     $.default[] <- Значение по-умолчанию (if !def).
##     $.auto(false) <- Автоматически добавлять значение (игнорируем ключ skipAbsent)
##   ]
## ]
##
## Процессоры:
##  int - целое число, если не задан default, то приведение делаем без значение по-умолчанию
##  bool - 1/0
##  now - текущие дата время (если не задано значение поля)
##  curtime - текущее время (если не задано значение поля)
##  curdate - текущая дата (если не задано значение поля)

@_processFieldsOptions[aOptions]
  $result[^hash::create[$aOptions]]
  $result.skipNames(^aOptions.skipNames.bool(false))
  $result.skipAbsent(^aOptions.skipAbsent.bool(false))
  $result.skipFields[^hash::create[$aOptions.skipFields]]

@selectFields[aFields;aOptions][locals]
## Возвращает список полей для выражения select
## aOptions.alias
## aOptions.skipFields[$.field[] ...] — хеш с полями, которые надо исключить из выражения
  ^pfAssert:isTrue(def $aFields)[Не задан список полей.]
  $aOptions[^_processFieldsOptions[$aOptions]]
  $lAlias[^if(def $aOptions.alias){${aOptions.alias}}]
  $lTableAlias[^if(def $lAlias){${lAlias}.}]

  $result[^hash::create[]]
  ^aFields.foreach[k;v]{
    ^if(^aOptions.skipFields.contains[$k]){^continue[]}
    $result.[^result._count[]][${lTableAlias}$v.dbf as $k]
  }
  $result[^result.foreach[k;v]{$v}[, ]]

@fieldsList[aFields;aOptions][locals]
## Возвращает список полей
## aOptions.skipFields[$.field[] ...] — хеш с полями, которые надо исключить из выражения
## aOptions.skipAbsent(false) - пропустить поля, данных для которых нет (недо обязательно задать поле aOptions.data)
## aOptions.data - хеш с данными
  ^pfAssert:isTrue(def $aFields)[Не задан список полей.]
  $aOptions[^_processFieldsOptions[$aOptions]]
  $lData[^if(def $aOptions.data){$aOptions.data}]
  $result[^hash::create[]]
  ^aFields.foreach[k;v]{
    ^if($aOptions.skipAbsent && !^lData.contains[$k] && !(def $v.processor && ^v.processor.pos[auto_] >= 0)){^continue[]}
    ^if(^aOptions.skipFields.contains[$k]){^continue[]}
    $result.[^result._count[]][$v.dbf]
  }
  $result[^result.foreach[k;v]{$v}[, ]]

@setExpression[aFields;aData;aOptions][locals]
## Возвращает выражение для присвоения значения (field = vale, ...)
## aOptions.alias
## aOptions.skipAbsent(false) - пропустить поля, данных для которых нет
## aOptions.skipFields[$.field[] ...] — хеш с полями, которые надо исключить из выражения
## aOptions.skipNames(false) - не выводить имена полей, только значения (для insert values)
  ^pfAssert:isTrue(def $aFields)[Не задан список полей.]
  ^cleanMethodArgument[aData]
  $aOptions[^_processFieldsOptions[$aOptions]]
  $lAlias[^if(def $aOptions.alias){${aOptions.alias}}]
  $lTableAlias[^if(def $lAlias){${lAlias}.}]

  $result[^hash::create[]]
  ^aFields.foreach[k;v]{
    ^if(^aOptions.skipFields.contains[$k]){^continue[]}
    ^if($aOptions.skipAbsent && !^aData.contains[$k] && !(def $v.processor && ^v.processor.pos[auto_] >= 0)){^continue[]}
    $result.[^result._count[]][^if(!$aOptions.skipNames){${lTableAlias}$v.dbf = }^fieldValue[$v;^if(^aData.contains[$k]){$aData.[$k]}]]
  }
  $result[^result.foreach[k;v]{$v}[, ]]

@fieldValue[aField;aValue][locals]
  ^pfAssert:isTrue(def $aField)[Не задано описание поля.]
  $result[^switch[^if(def $aField.processor){$aField.processor}]{
    ^case[int;auto_int]{^if(^aField.contains[default]){^aValue.int($aField.default)}{^aValue.int[]}}
    ^case[bool;auto_bool]{^if(^aValue.bool(^if(^aField.contains[default]){$aField.default}{false})){1}{0}}
    ^case[now;auto_now]{^if(def $aValue){"^taint[$aValue]"}{"^_now.sql-string[]"}}
    ^case[cuttime;auto_curtime]{^if(def $aValue){"^taint[$aValue]"}{"^_now.sql-string[time]"}}
    ^case[cutdate;auto_curdate]{^if(def $aValue){"^taint[$aValue]"}{"^_now.sql-string[date]"}}
    ^case[DEFAULT]{"^taint[$aValue]"}
  }]

#----- Построение sql-выражений -----

## Макроподстановки:
##   — В выражениях «:fieldName» заменяется на имя поля в БД.

@processStatementMacro[aFields;aString;aOptions]
  $result[^aString.match[$_pfSQLBuilderPatternRegex][]{^if(^aFields.contains[$match.2]){$aFields.[$match.2].dbf}{$match.1}}]

@insertStatement[aTableName;aFields;aData;aOptions][locals]
## Строит выражение insert into values
## aTableName - имя таблицы
## aFields - поля
## aData - данные
## aOptions.skipFields[$.field[] ...] — хеш с полями, которые надо исключить из выражения
  ^pfAssert:isTrue(def $aTableName)[Не задано имя таблицы.]
  ^pfAssert:isTrue(def $aFields)[Не задан список полей.]
  ^cleanMethodArgument[]
  $result[insert into $aTableName (^fieldsList[$aFields;$aOptions]) values (^setExpression[$aFields;$aData;^hash::create[$aOptions] $.skipNames(true)])]

@updateStatement[aTableName;aFields;aData;aWhere;aOptions][locals]
## Строит выражение для update
## aTableName - имя таблицы
## aFields - поля
## aData - данные
## aWhere - выражение для where
##          (для безопасности блок where принудительно задается принудительно,
##           если нужно иное поведение укажите aWhere[1=1])
## aOptions.skipAbsent(false) - пропустить поля, данных для которых нет
## aOptions.skipFields[$.field[] ...] — хеш с полями, которые надо исключить из выражения
## aOptions.emptySetExpression[выражение, которое надо подставить, если нет данных для обновления]
  ^pfAssert:isTrue(def $aTableName)[Не задано имя таблицы.]
  ^pfAssert:isTrue(def $aFields)[Не задан список полей.]
  ^pfAssert:isTrue(def $aWhere)[Не задано выражение для where.]
  ^cleanMethodArgument[]

  $lSetExpression[^setExpression[$aFields;$aData;$aOptions]]
  ^pfAssert:isTrue(def $lSetExpression || (!def $lSetExpression && def $aOptions.emptySetExpression))[Необходимо задать выражение для пустого update set.]
  $result[update $aTableName set ^if(def $lSetExpression){$lSetExpression}{$aOptions.emptySetExpression} where ^processStatementMacro[$aFields;$aWhere]]
