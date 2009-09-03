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
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]

  $_REQUEST[^pfHTTPRequest::create[]]
  
  $_uriProtocol[^if(def $aOptions.uriProtocol){$aOptions.uriProtocol}{^if($REQUEST.isSECURE){https}{http}}]
  $_uriServerName[^if(def $aOptions.uriServerName){$aOptions.uriServerName}{$REQUEST.META.SERVER_NAME}]
  
#----- Public -----  

@run[aOptions][lArgs]
## Основной процесс обработки запроса (как правило перекрывать не нужно).
  $lArgs[^getDispatchArgs[]]
  ^authenticate[$lArgs._action;$lArgs]
  $result[^dispatch[$lArgs._action;$lArgs]]

@authenticate[aAction;aOptions]
## Производит авторизацию.
  ^if(^AUTH.identify[$aOptions]){
    $result[^onAuthSuccess[$aOptions]]
   }{
      $result[^onAuthFailed[$aOptions]]
    }

@getDispatchArgs[aOptions]
  $result[$REQUEST]

#----- Properties -----

@GET_uriProtocol[]
  $result[$_uriProtocol]

@GET_uriServerName[]
  $result[$_uriServerName]
  
@GET_REQUEST[]
  $result[$_REQUEST]

#----- Events -----

@onAuthSuccess[aRequest]
## Вызывается при удачной авторизации.
## Можно перекрыть, если есть желание

@onAuthFailed[aRequest]
## Вызывается при неудачной авторизации

@postDEFAULT[aResponse]
  ^throw[pfSiteManager.postDEFAULT;Unknown response type "$aResponse.type".]

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
  ^if(!def ${aResponse.content-type}){
    $aResponse.content-type[application/octet-stream]
  }
  ^if(def $aResponse.download){
    $response:download[$aResponse.download]
  }{
     $response:body[$aResponse.body]
   }
  ^_setResponseHeaders[$aResponse]
  $result[]

@postREDIRECT[aResponse]         
  ^if(!^aResponse.headers.location.match[^^https?://]){
    $aResponse.headers.location[${uriProtocol}://${uriServerName}$aResponse.headers.location]
  }  
  ^_setResponseHeaders[$aResponse]
  $result[]

#----- Methods -----

@_setResponseHeaders[aResponse]
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
   
  