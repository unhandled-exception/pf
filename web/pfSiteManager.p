# PF Library

@CLASS
pfSiteManager

@USE
pf/web/pfSiteModule.p
pf/web/pfHTTPRequest.p

@BASE
pfSiteModule

#----- Constructor -----

@create[aOptions]
## aOptions.request
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]

  $_REQUEST[$aOptions.request]
  $_uriProtocol[$aOptions.uriProtocol]
  $_uriServerName[$aOptions.uriServerName]
  
#----- Public -----  

@run[aOptions][lRequest;lResult;lAction]
## Основной процесс обработки запроса (как правило перекрывать не нужно).
  $lRequest[$REQUEST]                   
  $lAction[$lRequest._action]
  ^authenticate[$lAction;$lRequest]
  $result[^dispatch[$lAction;$lRequest]]

@authenticate[aAction;aOptions]
## Производит авторизацию.
  ^if(^AUTH.identify[$aOptions]){
    $result[^onAuthSuccess[$aOptions]]
   }{
      $result[^onAuthFailed[$aOptions]]
    }

#----- Properties -----

@GET_uriProtocol[]
  ^if(!def $uriProtocol){
    $_uriProtocol[^if($REQUEST.isSECURE){https}{http}]
  }
  $result[$_uriProtocol]

@GET_uriServerName[]
  ^if(!def $_uriServerName){
    $_uriServerName[$REQUEST.META.SERVER_NAME]
  }
  $result[$_uriServerName]
  
@GET_REQUEST[]
  ^if(!def $_REQUEST){
    $_REQUEST[^pfHTTPRequest::create[]]
  }
  $result[$_REQUEST]

#----- Events -----

@onAuthSuccess[aRequest]
## Вызывается при удачной авторизации.
  $result[]
  
@onAuthFailed[aRequest]
## Вызывается при неудачной авторизации
  $result[]

@processResponse[aResponse;aAction;aRequest;aOptions]
## aOptions.passManagerPost(false)
  $result[^BASE:processResponse[$aResponse;$aAction;$aRequest;$aOptions $.passPost(^aOptions.passManagerPost.bool(false))]]

@postDEFAULT[aResponse]
  ^throw[pfSiteManager.postDEFAULT;Unknown response type "$aResponse.type".]

@postAS-IS[aResponse]
  ^_setResponseHeaders[$aResponse]
  ^if(def $aResponse.download){
    $response:download[$aResponse.download]
  }{
     $result[$aResponse.body]
   }

@postHTML[aResponse]
  ^if(!def ${aResponse.content-type}){
    $aResponse.content-type[text/html]
  }
  ^_setResponseHeaders[$aResponse]
  $result[$aResponse.body]

@postXML[aResponse]
  ^if(!def ${aResponse.content-type}){
    $aResponse.content-type[text/xml]
  }
  ^_setResponseHeaders[$aResponse]
  $result[^untaint[optimized-xml]{$aResponse.body}]

@postTEXT[aResponse]
  ^if(!def ${aResponse.content-type}){
    $aResponse.content-type[text/plain]
  }
  ^_setResponseHeaders[$aResponse]
  $result[^untaint[as-is]{$aResponse.body}]

@postFILE[aResponse]
  $result[]
  ^if(!def ${aResponse.content-type}){
    $aResponse.content-type[application/octet-stream]
  }
  ^if(def $aResponse.download){
    $response:download[$aResponse.download]
  }{
     $response:body[$aResponse.body]
   }
  ^_setResponseHeaders[$aResponse]

@postREDIRECT[aResponse]         
  $result[]
  ^_setResponseHeaders[$aResponse]

#----- Methods -----

@_setResponseHeaders[aResponse]   
  $result[]
  ^if(def $aResponse.charset){$response:charset[$aResponse.charset]}
  $response:content-type[
    $.value[^if(def ${aResponse.content-type}){$aResponse.content-type}{text/html}]
    $.charset[$response:charset]
  ]
  
  ^if(def $aResponse.headers && $aResponse.headers is hash){
    ^aResponse.headers.foreach[k;v]{
      $response:$k[$v]
    }
  }
  
  ^if(def $aResponse.cookie && $aResponse.cookie is hash){
    ^aResponse.cookie.foreach[k;v]{
      $cookie:$k[$v]
    }
  }
  
  ^if(^aResponse.status.int(-1) >= 0){
    $response:status[$aResponse.status]
  }
   
  