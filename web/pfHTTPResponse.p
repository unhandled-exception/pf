# PF Library

@CLASS
pfHTTPResponse

@USE
pf/types/pfClass.p

@BASE
pfClass

#----- Constructor -----

@create[aBody;aOptions]
## aBody              
## aOptions.type[html] - тип ответа
## aOptions.status(200) - http-статус
## aOptions.contentType[]
## aOptions.charset[]
## aOptions.canDownload(false)
  ^cleanMethodArgument[]

  $_body[$aBody]

  $_type[^if(def $aOptions.type){$aOptions.type}{html}]
  $_contentType[^if(def $aOptions.contentType){$aOptions.contentType}]
  $_status(^if(def $aOptions.status){$aOptions.status}{200})
  $_charset[^if(def $aOptions.charset){$aOptions}]
  
  $_canDownload($aOptions.canDownload)

  $_headers[^hash::create[]]
  $_cookie[^hash::create[]]

#----- Properties -----

@GET_type[]
  $result[$_type]  

@SET_type[aType]
  $type[$aType]  


@GET_body[]
  $result[$_body]
  
@SET_body[aBody]
  $_body[$aBody]


@GET_canDownload[]
  $result($_canDownload)

@GET_download[]
  $result[^if($canDownload){$body}]


@GET_contentType[]
  $result[$_contentType]

@SET_contentType[aContentType]
  $_contentType[$aContentType]


@GET_content-type[]
# Для совместимости
  $result[$_contentType]

@SET_content-type[aContentType]
  $_contentType[$aContentType]


@GET_status[]
  $result($_status)

@SET_status[aStatus]
  $_status($aStatus)
  

@GET_charset[]
  $result[$_charset]

@SET_charset[aCharset]
  $_charset[$aCharset]
  

@GET_headers[]
  $result[$_headers]
  
@GET_cookie[]
  $result[$_cookie]

#################################################

@CLASS
pfHTTPResponseRedirect

@BASE
pfHTTPResponse

@create[aPath]      
## aPath - полный путь для редиректа или uri
  ^BASE:create[;$.type[redirect] $.status(302)]
  $headers.location[^untaint{$aPath}]

#################################################

@CLASS
pfHTTPResponsePermanentRedirect

@BASE
pfHTTPResponse

@create[aPath]      
## aPath - полный путь для редиректа или uri
  ^BASE:create[;$.type[redirect] $.status(301)]
  $headers.location[^untaint{$aPath}]

#################################################

@CLASS
pfHTTPResponseNotFound

@BASE
pfHTTPResponse

@create[aBody;aOptions]      
  ^BASE:create[$aBody;$aOptions]
  $status(404)

#################################################

@CLASS
pfHTTPResponseBadRequest

@BASE
pfHTTPResponse

@create[aBody;aOptions]      
  ^BASE:create[$aBody;$aOptions]
  $status(400)
    
#################################################

@CLASS
pfHTTPResponseNotModified

@BASE
pfHTTPResponse

@create[aBody;aOptions]      
  ^BASE:create[$aBody;$aOptions]
  $status(304)
    
#################################################

@CLASS
pfHTTPResponseNotAllowed

@BASE
pfHTTPResponse

@create[aBody;aOptions]      
  ^BASE:create[$aBody;$aOptions]
  $status(405)

#################################################

@CLASS
pfHTTPResponseForbidden

@BASE
pfHTTPResponse

@create[aBody;aOptions]      
  ^BASE:create[$aBody;$aOptions]
  $status(403)

#################################################

@CLASS
pfHTTPResponseGone

@BASE
pfHTTPResponse

@create[aBody;aOptions]      
  ^BASE:create[$aBody;$aOptions]
  $status(410)

#################################################

@CLASS
pfHTTPResponseServerError

@BASE
pfHTTPResponse

@create[aBody;aOptions]      
  ^BASE:create[$aBody;$aOptions]
  $status(500)
