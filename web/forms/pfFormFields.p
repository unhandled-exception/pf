## PF web forms fields

@USE
pf/types/pfClass.p
pf/web/forms/widgets/pfFormTextInputWidget.p
pf/web/forms/widgets/pfFormHiddenInputWidget.p
pf/types/pfValidate.p
pf/web/forms/widgets/pfFormInputWidget.p

@CLASS
pfFormBaseField

@BASE
pfClass

@create[aOptions]
## aOptions.required(true) - обязательное поле.
## aOptions.widget[!def] - объект-виджет, реализующий отображение поля в форме.
## aOptions.hiddenWidget[!def] - объект-виджет, реализующий отображение скрытого поля в форме.
## aOptions.label[!def] - метка поля, отображаемая в форме. По-умолчанию используем 
##                        имя поля: "field_name" -> "Field name".
## aOptions.initial[!def] - начальное значение поля.
## aOptions.helpText[!def] - "строка помощи" для поля.
## aOptions.isHidden(false)
## aOptions.errorMessages[$.required[] $.invalid[]] - сообщения об ошибках.
  
  ^cleanMethodArgument[aOptions]
  ^pfAssert:isTrue(!def $aOptions.errorMessages || $aOptions.errorMessages is hash)[errorMessages должны быть заданы в виде хеша.]

  $_validationException[pfForms.validationError]

  $_required(^if(def $aOptions.required){$aOptions.required}{1})
  ^defReadProperty[required;_required]
  
  $_widget[^if(def $aOptions.widget){$aOptions.widget}{^pfFormTextInputWidget::create[]}]
  ^defReadProperty[widget;_widget]
  
  ^if(def $aOptions.isHidden){$_isHidden($aOptions.isHidden)}{$_isHidden(false)})
  ^defReadProperty[isHidden;_isHidden]
  
  $_hiddenWidget[^if(def $aOptions.hiddenWidget){$aOptions.hiddenWidget}{^pfFormHiddenInputWidget::create[]}]
  ^defReadProperty[hiddenWidget;_hiddenWidget]

  $_label[^if(def $aOptions.label){$aOptions.label}{$aName}]
  ^defReadProperty[label;_label]
  
  $_initial[$aOptions.initial]
  ^defReadProperty[initial;_initial]
  
  $_defaultErrorMessages[
    $.required[Это поле должно быть заполнено.]
    $.invalid[Поле заполнено неверно.]
  ]
  $errorMessages[$aOptions.errorMessages]

@SET_errorMessages[aErrorMessages]
  ^if(!($_errorMessages is hash)){
    $_errorMessages[^hash::create[$_defaultErrorMessages]]
  }
  ^if($_errorMessages is hash){
    ^_errorMessages.add[$aErrorMessages]
  }

@GET_errorMessages[]
  $result[$_errorMessages]

@clean[aValue]
## Проверяет значение aValue и возвращает его "очищенно" значение в виде парсеровского объекта.
  ^if($required && !def $aValue){
    ^throw[$_validationException;$errorMessages.required]
  }
  $result[$aValue]
  
@widgetAttrs[aWidget]
## Возвращает атрибуты, которые должны быть добавлены к атрибутам виджета.
  $result[^hash::create[]]


###############################################################################################


@CLASS
pfFormCharField

@BASE
pfFormBaseField

@create[aOptions]
  ^BASE:create[$aOptions]
