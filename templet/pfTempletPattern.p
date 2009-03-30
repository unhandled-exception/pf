# PF Library
# Templet Engine 1.0

@CLASS
pfTempletPattern

@USE
pf/types/pfClass.p

@BASE
pfClass

## Базовый класс для шаблона

#----- Constructor -----

@create[aPattern;aTemplet;aOptions]
  ^BASE:create[]
  ^cleanMethodArgument[]
  
  $_VARS[^hash::create[]]
  
  $_FILE[$aOptions.fileName]
  $_TEMPLET[$aTemplet]
  ^assignPattern[$aPattern]

#----- Properties -----

@GET_TEMPLET[]
  $result[$_TEMPLET]

@GET_VARS[]
  $result[$_VARS]

@GET_FILE[]
  $result[$_FILE]

@GET_DEFAULT[aName]
  $result[$_VARS.[$aName]]

#----- Public -----

@include[aTemplateName;aOptions]
## Включает другой шаблон в текущий.
## ВАЖНО: включаемый шаблон не кешируется.
  ^cleanMethodArgument[]
  $result[^TEMPLET.render[$aTemplateName;$.isCaching(0) $.vars[$aOptions.vars] $.force(^aOptions.force.bool(false))]]

@assignPattern[aPattern]
## Компилируем основной метод
   ^process{$aPattern}[ $.main[_pattern] $.file[$_FILE] ]

@assignVars[aVars;aOptions]
## Присваиваем переменные шаблона 
  $_VARS[^if($aVars is hash){$aVars}{^hash::create[]})]
