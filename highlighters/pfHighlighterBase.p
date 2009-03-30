# PF Library

#@module   Base Highliter
#@author   Oleg Volchkov <oleg@volchkov.net>                                                                                                          
#@web      http://oleg.volchkov.net

@CLASS
pfHighlighterBase

@USE
pf/modules/pfModule.p

@BASE
pfModule

#----- Constructor -----

@create[aOptions]
## aOptions.cssPrefix - префикс, который надо проставлять css-классам
  ^if(!($aOptions is hash)){$aOptions[^hash::create[]]}
  ^BASE:create[$aOptions]
  
  $_cssPrefix[^if(def $aOptions.cssPrefix){$aOptions.cssPrefix}{hl-}]

#----- Properties -----

@GET_cssPrefix[]
  $result[$_cssPrefix]

#----- Events -----

@onHighlight[aOptions]
## Событие, которое надо перекрывать в наследниках.
## aOptions.text - текст, который надо обработать
## aOptions.params - параметры хайлафтера
  $result[$aOptions.text]

