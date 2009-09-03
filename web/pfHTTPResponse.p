# PF Library

@CLASS
pfHTTPResponse

@USE
pf/types/pfClass.p

@BASE
pfClass

#----- Constructor -----

# HttpResponse.__init__(content='', mimetype=None, status=200, content_type=DEFAULT_CONTENT_TYPE)¶
# $.content-type[] $.charset[] $.headers[] $.status[] $.cookie[]

@create[aBody;aOptions]
## aBody              
## aOptions.type[html]
## aOptions.status(200)
## aOptions.contentType[text/html]
## aOptions.charset[]
## aOptions.canDownload(false)
  ^cleanMethodArgument[]

  $_body[$aBody]

  $_type[^if(def $aOptions.type){$aOptions.type}{html}]
  $_contentType[^if(def $aOptions.contentType){$aOptions.contentType}{text/html}]
  $_status(^if(def $aOptions.status){$aOptions.status}{200})
  $_charset[^if(def $aOptions.charset){$aOptions}{$response:charset}]
  
  $_canDownload($aOptions.canDownload)

  $_headers[^hash::create[]]
  $_cookie[^hash::create[]]

@GET_type[]
  $result[$_type]  

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
  ^BASE:create[;$.type[redirect] $.status(301)]
  $_headers.location[^untaint{$aPath}]

#################################################

@CLASS
pfHTTPResponsePermanentRedirect

@BASE
pfHTTPResponse

@create[aPath]      
## aPath - полный путь для редиректа или uri
  ^BASE:create[;$.type[redirect] $.status(302)]
  $_headers.location[^untaint{$aPath}]

#################################################

@CLASS
pfHTTPResponseNotFound

@BASE
pfHTTPResponse

@create[aBody;aOptions]      
  ^BASE:create[$aBody;$aOptions]
  $_status(404)

#################################################

@CLASS
pfHTTPResponseNotAllowed

@BASE
pfHTTPResponse

@create[aBody;aOptions]      
  ^BASE:create[$aBody;$aOptions]
  $_status(405)

#################################################

@CLASS
pfHTTPResponseForbidden

@BASE
pfHTTPResponse

@create[aBody;aOptions]      
  ^BASE:create[$aBody;$aOptions]
  $_status(403)

#################################################

@CLASS
pfHTTPResponseNotFound

@BASE
pfHTTPResponse

@create[aBody;aOptions]      
  ^BASE:create[$aBody;$aOptions]
  $_status(404)

#################################################

@CLASS
pfHTTPResponseGone

@BASE
pfHTTPResponse

@create[aBody;aOptions]      
  ^BASE:create[$aBody;$aOptions]
  $_status(410)

#################################################

@CLASS
pfHTTPResponseServerError

@BASE
pfHTTPResponse

@create[aBody;aOptions]      
  ^BASE:create[$aBody;$aOptions]
  $_status(500)
