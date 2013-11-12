# PF Library

@CLASS
pfAssert

@OPTIONS
static

#----- Static constructor -----

@auto[]
  $_isEnabled(true)
  $_exceptionName[assert.fail]
  $_passExceptionName[assert.pass]

#----- Properties -----

@GET_enabled[]
  $result($_isEnabled)

@SET_enabled[aValue]
  $_isEnabled($aValue)

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
    $aComment[^switch[$aComment.CLASS_NAME]{
      ^case[int;double;string]{$aComment}
      ^case[date]{^aComment.sql-string[]}
      ^case[DEFAULT]{^json:string[$aComment;$.indent(true)]}
    }]
    ^throw[$_exceptionName;Fail;^if(def $aComment){$aComment}{Assertion failed exception.}]
  }

@pass[aComment][result]
  ^if($enabled){
    ^throw[$_passExceptionName;Pass;^if(def $aComment){$aComment}{Assertion pass exception.}]
  }
