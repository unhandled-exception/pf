@USE
pf/types/pfClass.p

@CLASS
pfFormBaseWidget

@BASE
pfClass

@create[aOptions]
## aOptions.attrs[!def] - хеш с аттрибутами тегов 
##      (ключи и значения должны быть простыми типами).
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(!def $aOptions.attrs || $aOptions is hash)[Параметр attrs должен быть хешем.]
 
  ^BASE:create[]

  $_attrs[^if($aOptions.attrs is hash){$aOptions.attrs}{^hash::create[]}]
  ^defReadProperty[attrs;_attrs]

  $_isHidden(false)
  ^defReadProperty[isHidden;_isHidden]

  $_needsMultipartForm(false)
  ^defReadProperty[needsMultipartForm;_needsMultipartForm]

@idForLabel[aDefaultID]
## Возвращает id для елемента label.
   $result[$aDefaultID]

@render[aName;aValue;aAttrs]
## Возвращает текущий виджет в виде HTML-кода.
  ^_abstractMethod[]

@flatAttrs[aAttrs]
## Преобразовывает хеш с атрибутами в строку
  ^if($aAttrs){
    $result[^aAttrs.foreach[k;v]{^if(def $v){${k}="$v"}}[ ]]
  }

#######################################################################################3

@CLASS
pfFormInputWidget

@BASE
pfFormBaseWidget

@create[aOptions]
  ^BASE:create[$aOptions]
  $_inputType[]

@render[aName;aValue;aAttrs][lAttrs]
  $lAttrs[^hash::create[$aAttrs]]
  $lAttrs.name[$aName]
  $lAttrs.type[$_inputType]
  $lAttrs.value[$aValue]
  $result[<input ^flatAttrs[$lAttrs] />]

#######################################################################################3

@CLASS
pfFormHiddenInputWidget

@BASE
pfFormInputWidget

@create[aOptions]
  ^BASE:create[$aOptions]
  $_inputType[hidden]
  $_isHidden(true)
  
#######################################################################################3

@CLASS
pfFormPasswordInputWidget

@BASE
pfFormInputWidget

@create[aOptions]
  ^BASE:create[$aOptions]
  $_inputType[password]


#######################################################################################3

@CLASS
pfFormTextInputWidget

@BASE
pfFormInputWidget

@create[aOptions]
  ^BASE:create[$aOptions]
  $_inputType[text]
