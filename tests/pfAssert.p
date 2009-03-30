# PF Library
# Units Test Suite
# Copyright (c) 2006-2007 Oleg Volchkov

#@module   Assert Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

@CLASS
pfAssert

#----- Static constructor -----

@auto[]
  $_isEnabled(true)
  $_exceptionName[assert.fail]
  $_passExceptionName[assert.pass]
  
#----- Constructor -----

@create[]
  ^fail[pfAssert нельзя использовать динамически.]

#----- Properties -----

@GET_enabled[]
  $result($_isEnabled)

@SET_enabled[aValue]
  $_isEnabled($aValue)

#----- Private -----

#----- Public -----

@isTrue[aCondition;aComment][result]
  ^if($enabled && !$aCondition){
    ^throw[$_exceptionName;isTrue;^if(def $aComment){$aComment}{Assertion failed exception.}]
  }
  
@isFalse[aCondition;aComment][result]
  ^if($enabled && $aCondition){
    ^throw[$_exceptionName;isFalse;^if(def $aComment){$aComment}{Assertion failed exception.}]
  }
  
@fail[aComment][result]
  ^if($enabled){
    ^throw[$_exceptionName;Fail;^if(def $aComment){$aComment}{Assertion failed exception.}]
  }

@pass[aComment][result]
  ^if($enabled){
    ^throw[$_passExceptionName;Pass;^if(def $aComment){$aComment}{Assertion pass exception.}]
  }
