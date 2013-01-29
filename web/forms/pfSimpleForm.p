# PF Library

## Работа с веб-формами.

@CLASS
pfSimpleForm

#@compat 3.4.2

@USE
pf/types/pfClass.p

@BASE
pfClass


#----- Конструкторы -----

@auto[]
  $__FORMS_WRAPPERS__[
    $.default[$.class[pfSFWrapper]]
    $.bootstrap[$.class[pfSFBootstrapWrapper]]
  ]
  $__FORMS_DEFAULT_WRAPPER__[default]

@create[aOptions]
## aOptions.wrapperName[default]
  ^cleanMethodArgument[]
  ^BASE:create[]

  $_FIELDS[^hash::create[]]
  $_WRAPPER_NAME[^if(def $aOptions.wrapperName){$aOptions.wrapperName}{$__FORMS_DEFAULT_WRAPPER__}]
  $_WRAPPER[]


#----- Свойства -----

@GET_WRAPPER[]
  ^if(!def $_WRAPPER){
    $_WRAPPER[^__wrapperFabric[$_WRAPPER_NAME]]
  }
  $result[$_WRAPPER]


#----- Работа с враперами -----

@static:registerWrapper[aWrapperName;aWrapperClass;aOptions]
  ^cleanMethodArgument[]
  $result[]
  ^pfAssert:isTrue(!^__FORMS_WRAPPERS__.contains[$aWrapperName])[Врапер "$aWrapperName" уже существует.]
  ^pfASsert:isTrue(def $aWrapperName && def $aWrapperClass)[Не задано имя врапера или его класс.]
  $__FORMS_WRAPPERS__.[$aWrapperName][$.class[$aWrapperName][$aWrapperClass]]
  ^if(^aOptions.setAsDefault.bool(false)){
    ^CLASS:setDefaultWrapper[$aWrapperName]
  }

@static:setDefaultWrapper[aWrapperName]
  $result[]
  ^pfAssert:isTrue(^__FORMS_WRAPPERS__.contains[$aWrapperName])[Врапер "$aWrapperClass" не зарегистрирован.]
  $__FORMS_DEFAULT_WRAPPER__[$aWrapperName]

@__wrapperFabric[aWrapperName][lWrapper]
  $lWrapper[$__FORMS_WRAPPERS__.[^if(def $aWrapperName && ^__FORMS_WRAPPERS__.contains[$aWrapperName]){$aWrapperName}{$__FORMS_DEFAULT_WRAPPER__}]]
  $result[^reflection:create[$lWrapper.class;create;$self]]


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
  $lField.name[$aFieldName]

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


#----- Вывод формы -----

@print[aData]
  ^cleanMethodArgument[aData]
  $result[^WRAPPER.printForm[$aData]]


#-----------------------------------------------------------------

@CLASS
pfSFWrapper

# Штатный врапер формы.

@BASE
pfClass

@create[aForm;aOptions]
## aOptions.classes
  ^pfAssert:isTrue(def $aForm)[Не задан объект с формой.]
  ^BASE:create[]
  $_form[$aForm]
  ^defReadProperty[form]

@printForm[aData;aOptions][locals]
  ^cleanMethodArgument[aData]
  $result[^hash::create[]]
  ^form.foreach[k;v]{
    ^switch(true){
      ^case(def $v.widget && $self.[${v.widget}Widget] is junction){
        $result.[^result._count[]][^self.[${v.widget}Widget][$v;$aData.[$k]]]
      }
      ^case[DEFAULT]{
        $result.[^result._count[]][^defaultWidget[$v;$aData.[$k]]]
      }
    }
  }
  $result[^result.foreach[k;v]{$v}[^#0A]]

@widgetLine[aField;aWidgetHTML;aOptions]
  $result[<div>^if(def $aField){<label for="$aField.name">$aField.label</label> }$aWidgetHTML</div>]

#----- Функции-виджеты -----

@_getWidgetOptions[aField;aValue]
  $result[^hash::create[]]
  $result.name[$aField.name]
  ^if($aField.disabled){$result.disabled[true]}
  ^if(def $aField.placeholder){$result.placeholder[$aField.placeholder]}
  ^if(def $aField.class){$result.class[$aField.class]}

@defaultWidget[aField;aValue][locals]
  $lAttr[^_getWidgetOptions[$aField]]
  $lAttr.type[^switch[^aField.widget.lower[]]{
    ^case[password]{password}
    ^case[DEFAULT]{text}
  }]
  $lAttr.value[$aValue]
  ^if(def $aField.maxlength){$lAttr.maxlength[$aField.maxlength]}
  $result[^widgetLine[$aField;<input ^lAttr.foreach[k;v]{$k="$v"}[ ]/>]]

@hiddenWidget[aField;aValue]
  $result[<input type="hidden" name="$aField.name" value="$aValue" />]

@textWidget[aField;aValue][locals]
## aOptions.rows(8)
  $lAttr[^_getWidgetOptions[$aField]]
  $lAttr.rows[^aField.rows.int(8)]
  $result[^widgetLine[$aField;<textarea ^lAttr.foreach[k;v]{$k="$v"}[ ]>$aValue</textarea>]]

@submitWidget[aField;aValue]
  ^cleanMethodArgument[aField]
  $lAttr[^_getWidgetOptions[$aField]]
  $lAttr.type[submit]
  $lAttr.name[^if(def $aField.name){$aField.name}{send}]
  $lAttr.value[^if(def $aValue){$aValue}{Send}]
  $result[^widgetLine[;<input ^lAttr.foreach[k;v]{$k="$v"}[ ]/>]]


#-----------------------------------------------------------------

@CLASS
pfSFBootstrapWrapper

@BASE
pfSFWrapper

@create[aForm;aOptions]
  ^cleanMethodArgument[]
  ^BASE:create[$aForm;$aOptions]

@widgetLine[aField;aWidgetHTML;aOptions]
  ^cleanMethodArgument[]
  $result[<div class="control-group">^if(def $aField){<label for="$aField.name" class="control-label">$aField.label</label>}<div class="controls">$aWidgetHTML</div></div>]

@defaultWidget[aField;aValue;aOptions]
## aOptions.size[mini|small|medium|large|xlarge|xxlarge]
  $result[^BASE:defaultWidget[^hash::create[$aField] $.class[$aField.class ^if(def $aField.size){input-$aField.size}];$aValue]]

@textWidget[aField;aValue;aOptions]
## aOptions.size[mini|small|medium|large|xlarge|xxlarge]
  $result[^BASE:textWidget[^hash::create[$aField] $.class[$aField.class ^if(def $aField.size){input-$aField.size}];$aValue]]

@submitWidget[aField;aValue;aOptions]
## aOptions.size[large|smal|mini] — размер кнопки
  $result[^BASE:submitWidget[^hash::create[$aField] $.class[btn btn-primary ^if(def $aField.size){btn-$aField.size} $aField.class];$aValue]]
