# PF Library

## Работа с веб-формами.

@CLASS
pfSimpleForm

#@compat 3.4.2

@USE
pf/types/pfClass.p
pf/tests/pfAssert.p
pf/sql/orm/pfSQLBuilder.p

@BASE
pfClass


#----- Конструкторы -----

@auto[]
  $__FORMS_WRAPPERS__[
    $.default[$.class[pfSFWrapper] $.object[]]
  ]

@create[aOptions]
## aOptions.wrapper[object or name]
  ^cleanMethodArgument[]
  ^BASE:create[]

  $_FIELDS[^hash::create[]]
  $_WRAPPER_NAME[^if(def $aWrapperName){$aWrapperName}{default}]
  $_WRAPPER[]


#----- Свойства -----

@GET_WRAPPER[]
  ^if(!def $_WRAPPER){
    $_WRAPPER[^__wrapperFabric[$_WRAPPER_NAME]]
  }
  $result[$_WRAPPER]


#----- Работа с враперами -----

@static:registerWrapper[aWrapperName;aWrapperClass;aOptions]
  $result[]
  ^pfAssert:isTrue(!^__FORMS_WRAPPERS__.contains[$aWrapperClass])[Врапер "$aWrapperClass" уже существует.]
  ^pfASsert:isTrue(def $aWrapperName && def $aWrapperClass)[Не задано имя врапера или его класс.]
  $__FORMS_WRAPPERS__.[$aWrapperName][$.class[$aWrapperName][$aWrapperClass]]

@__wrapperFabric[aWrapperName][lWrapper]
  $lWrapper[$__FORMS_WRAPPERS__.[^if(def $aWrapperName && ^__FORMS_WRAPPERS__.contains[$aWrapperName]){$aWrapperName}{default}]]
  $result[$lWrapper.object[^reflection:create[$lWrapper.class;create;$self]]]


#----- Определение полей -----

@hasField[aFieldName]
  $result(^_FIELDS.contains[$aFieldName])

@getField[aFieldName]
  $result[$_FIELDS.[$aFieldName]]

@addField[aFieldName;aOptions][locals]
## Добавляет поле в форму
## aOptions.required(false)
## aOptions.label[aName]
## aOptions.default[]
## aOptions.widget[input]
## aOptions.widgetOptions[…]
## aOptions.helpText[]
## aOptions.errorMessages[hash: $.require[Поле обязательное]]
## aOptions.processor[]
## aOptions.format
## aOptions.defaults[]
  $result[]
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(!^hasField[$aFieldName])[Поле "$aFieldName" уже существует.]
  $_FIELDS.[$aFieldName][$aOptions]
  $lField[$_FIELDS.[$aFieldName]]

  ^if(!^lField.contains[disabled]){$lField.disabled(false)}
  ^if(!^lField.contains[label]){$lField.label[$aFieldName]}


@addFields[aFields][locals]
## Добавляет несколько полей в форму
  $result[]
  ^aFields.foreach[k;v]{
    ^addField[$k;$v]
  }

@foreach[aKey;aValue;aCode;aSeparator][locals]
  $result[^_FIELDS.foreach[k;v]{$caller.[$aKey][$k]$caller.[$aValue][$v]$aCode}[$aSeparator]]


#----- Проверка полей -----

@clean[aData][locals]
## Проверяет форму и возвращает данные
  $result[^hash::create[]]
  ^aData.foreach[k;v]{
    $lField[^getField[$k]]
    ^if(def $lField && !$lField.disabled){
      $result.[$k][^processField[$lField;$v]]
    }
  }

@processField[aField;aValue]
## Выполняет процессор для поля
  $result[$aValue]


#-----------------------------------------------------------------

@CLASS
pfSFWrapper

# Штатный врапер формы.

@BASE
pfClass

@create[aForm;aOptions]
  ^pfAssert:isTrue(def $aForm)[Не задан объект с формой.]
  ^BASE:create[]
  $_form[$aForm]

@printForm[aData;aOptions]
  $result[]

