@CLASS
pfFormBoundField

@USE
pf/types/pfClass.p

@BASE
pfClass

@auto[]
  $_UNDERTOSPACE[^table::create[nameless]{_	 }]

@create[aForm;aField;aName]
  ^BASE:create[]
  
  $_form[$aForm]
  $_field[$aField]
  $_name[$aName]
  
  $_htmlName[^_form.addPrefix[$_name]]
  $_label[^if(def $aField.label){$aField.label}{^_prettyName[$_name]}] 
  ^defReadProperty[label;_label]
 
@asHTML[]
  $result[^asWidget[]]

@asWidget[aWidget;aAttrs][lAttrs]
  $lAttrs[^hash::create[$aAttrs]]
  ^if(!def $aWidget){$aWidget[$_field.widget]}
#   $lAttrs.id
  $result[^aWidget.render[$_htmlName;$data;$lAttrs]]
  
@labelTag[aContents;aAttrs][lWidget]
  ^if(!def $aContents){$aContents[$_label]}
  $lWidget[$_field.widget]
  $result[<label for="id"^lWidget.flatAttrs[$lAttrs]>$aContents</label>]

@GET_isHidden[]
  $result($field.widget.isHidden)

@GET_data[]
  $result[]

@GET_autoID[]
  $result[]


@_prettyName[aName]
  $result[^aName.match[^^(.)(.*)][]{^match.1.upper[]$match.2}]
  $result[^result.replace[$_UNDERTOSPACE]]

