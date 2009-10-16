# PF Library

@CLASS
pfHTTPRequest

@USE
pf/types/pfClass.p

@BASE
pfClass

#----- Constructor -----

@create[aOptions]   
  ^cleanMethodArgument[]
  ^BASE:create[]

  $_FIELDS[^if(def $aOptions.fields){$aOptions.fields}{$form:fields}]
  $_QTAIL[^if(def $aOptions.qtail){$aOptions.qtail}{$form:qtail}]
  $_IMAP[^if(def $aOptions.imap){$aOptions.imap}{$form:imap}]
  $_TABLES[^if(def $aOptions.tables){$aOptions.tables}{$form:tables}]
  $_FILES[^if(def $aOptions.files){$aOptions.files}{$form:files}]
  $_COOKIE[^if(def $aOptions.cookie){$aOptions.cookie}{$cookie:fields}]
  
  $_META[^if(def $aOptions.meta){$aOptions.meta}{^pfHTTPRequestMeta::create[]}]
  $_HEADERS[^if(def $aOptions.headers){$aOptions.headers}{^pfHTTPRequestHeaders::create[]}]

#----- Properties -----

@GET[]
## Return request fields count  
  $result($_FIELDS)

@GET_DEFAULT[aName]
## Return request field
  $result[$_FIELDS.[$aName]]
  ^if($result is junction){$result[]}

@GET_FIELDS[]
## Return all request fields
  $result[$_FIELDS]

@GET_META[]
## Return environment values
  $result[$_META]

@GET_HEADERS[]
## Return http-headers values
  $result[$_HEADERS]

@GET_TABLES[]
## Return form:tables field
  $result[$_TABLES]

@GET_FILES[]
## Return form:files field
  $result[$_FILES]

@GET_COOKIE[]
## Return cookie
  $result[$_COOKIE]
  
@GET_QTAIL[]
## Return form:qtail field
  $result[$_QTAIL]

@GET_IMAP[]
## Return form:imap field
  $result[$_IMAP]


@GET_isSECURE[]
## Проверяет пришел ли нам запрос по протоколу HTTPS.
  $result(^META.HTTPS.lower[] eq "on" || ^META.SERVER_PORT.int(80) == 443)


@GET_METHOD[]
## Возвращает http-метод запроса в нижнем регистре
  $result[^META.REQUEST_METHOD.lower[]]

@GET_isGET[]
  $result($METHOD eq "get")

@GET_isPOST[]
  $result($METHOD eq "post")

@GET_isHEAD[]
  $result($METHOD eq "head")

@GET_isPUT[]
  $result($METHOD eq "put")

@GET_isDELETE[]
  $result($METHOD eq "delete")

@GET_isAJAX[]
  $result(^HEADERS.[X_Requested_With].pos[XMLHttpRequest] > -1)


@GET_URI[]
## Return request:uri
  $result[$request:uri]

@GET_QUERY[]
## Return request:query
  $result[$request:query]
  
@GET_CHARSET[]
## Return request:charset
  $result[$request:charset]

@GET_POST-CHARSET[]
## Return request:post-charset
  $result[$request:post-charset]

@GET_BODY[]
## Return request:body
  $result[$request:body]

@GET_DOCUMENT-ROOT[]
## Return request:document-root
  $result[$request:document-root]
  

#----- Iterators -----

@foreach[aKeyName;aValueName;aCode;aSeparator]
## Iterate all request fields
  $result[^_FIELDS.foreach[k;v]{$caller.[$aKeyName][$k]$caller.[$aValueName][$v]$aCode}{$aSeparator}]


#----- Reflection -----  

@__add[aNewFields]
## Add new fields in to request
  ^pfAssert:isTrue($aNewFields is hash)[New fields must be a hash.]
  ^_FIELDS.add[$aNewFields]       
  $result[]


#################################################

@CLASS
pfHTTPRequestMeta

@BASE
pfClass

@create[]
  ^BASE:create[]

@GET_DEFAULT[aName]
  $result[$env:[$aName]]


#################################################

@CLASS
pfHTTPRequestHeaders

@BASE
pfClass

@create[]
  ^BASE:create[]

@GET_DEFAULT[aName][lName]
## Возвращает поле запроса.
## Позволяет задать имя в привычном виде (например, User-Agent).
  ^if(def $aName){
    $lName[^aName.trim[both][ :]]
    $lName[^aName.match[[-\s]][g]{_}]
    $result[$env:[HTTP_^lName.upper[]]]
  }{
     $result[]
  }
  