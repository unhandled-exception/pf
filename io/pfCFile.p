# PF Library

@CLASS
pfCFile

@auto[]
  $_curlSessionsCnt(0)

  $_baseVars[
    $.name[]
    $.content-type[]
    $.charset[]
    $.response-charset[]

    $.verbose[$.option[verbose] $.type[int] $.default(0)]
    $.stderr[$.option[stderr]]

#   Connection
    $.follow-location[$.option[followlocation] $.type[int] $.default(0)]
    $.max-redirs[$.option[maxredirs] $.type[int] $.default(-1)]
    $.post-redir[$.option[postredir]]
    $.autoreferer[$.option[autoreferer] $.type[int] $.default(0)]
    $.unrestricted-auth[$.option[unrestricted_auth] $.type[int] $.default(0)]
    $.encoding[$.option[encoding]]

#   Proxies
    $.proxy-host[$.option[proxy]]
    $.proxy-port[$.option[proxyport]]
    $.proxy-type[$.option[proxytype] $.type[int] $.default(0)]

#   Headers
    $.headers[$.option[httpheader]]
    $.cookiesession[$.option[cookiesession] $.type[int] $.default(1)]
    $.user-agent[$.option[useragent]]
    $.referer[$.option[referer]]

#   POST body
    $.body[$.option[postfields]]

#   SSL options
    $.ssl-cert[$.option[sslcert]]
    $.ssl-certtype[$.option[sslcerttype]]
    $.ssl-key[$.option[sslkey]]
    $.ssl-keytype[$.option[sslkeytype]]
    $.ssl-keypasswd[$.option[keypasswd]]
    $.ssl-issuercert[$.option[issuercert]]
    $.ssl-crlfile[$.option[crlfile]]
    $.ssl-cainfo[$.option[cainfo]]
    $.ssl-capath[$.option[capath]]
    $.ssl-cipher-list[$.option[ssl_cipher_list]]
    $.ssl-sessionid-cache[$.option[ssl_sessionid_cache] $.type[int] $.default(0)]
  ]

@GET_version[]
  $result[^curl:version[]]

@static:load[aMode;aURL;aOptions]
  ^if(!def $aOptions || $aOptions is string){$aOptions[^hash::create[]]}
    ^try{
      $result[^curl:load[^_makeCurlOptions[$aMode;$aURL;$aOptions]]]
    }{
       ^switch[$exception.type]{
         ^case[curl.host]{$exception.handled(true) ^throw[http.host;$exception.source;$exception.comment]}
         ^case[curl.timeout]{$exception.handled(true) ^throw[http.timeout;$exception.source;$exception.comment]}
         ^case[curl.connect]{$exception.handled(true) ^throw[http.connect;$exception.source;$exception.comment]}
         ^case[curl.status]{$exception.handled(true) ^throw[http.status;$exception.source;$exception.comment]}
       }
     }

@static:session[aCode]
## Организует сессию для запроса
  ^_curlSessionsCnt.inc[]
  $result[^curl:session{$aCode}]
  ^_curlSessionsCnt.dec[]

@static:options[aOptions]
## Задает опции для libcurl, но в формате, поддерживаемом функцией load (вызов curl:options)
## Можно вызывать только внутри сессии
  ^if(!$_curlSessionsCnt){^throw[cfile.options;Вызов метода options вне session.]}
  ^curl:options[^_makeCurlOptions[;;$aOptions]]
  $result[]

@_makeCurlOptions[aMode;aURL;aOptions][k;v;lForm]
## Формирует параметры для curl:load (curl:options)
  $result[^hash::create[]]
  ^if(!def $aOptions || $aOptions is string){$aOptions[^hash::create[]]}

  ^if(def $aURL){$result.url[$aURL]}
  ^if(def $aMode){
    ^if(!($aMode eq "text" || $aMode eq "binary")){^throw[cfile.mode;Mode must be "text" or "binary".]}
    $result.mode[$aMode]
  }

# Connection
  $result.timeout(^aOptions.timeout.int(2))
  ^if(!^aOptions.compressed.bool(true)){$result.encoding[identity]}{$result.encoding[]}

  $result.failonerror(!^aOptions.any-status.int(false))

# Задаем "простые" опции.
  ^_baseVars.foreach[k;v]{
    ^if(^aOptions.contains[$k]){
      ^if($v is hash){
        ^switch[$v.type]{
          ^case[DEFAULT]{
            $result.[$v.option][^if(def $aOptions.[$k]){$aOptions.[$k]}{$v.default}]
          }
          ^case[int;double]{
            $result.[$v.option](^if(def $aOptions.[$k])($aOptions.[$k])($v.default))
          }
        }
      }{
         $result.[$k][$aOptions.[$k]]
       }
    }
  }

# Auth (Basic)
  ^if(def $aOptions.user){
    $result.httpauth(1)
    $result.userpwd[${aOptions.user}:$aOptions.password]
  }

# Method
  ^if(^aOptions.contains[method]){
    ^switch[^aOptions.method.upper[]]{
      ^case[;GET]{$result.httpget(1)}
      ^case[POST]{$result.post(1)}
      ^case[HEAD]{$result.nobody(1)}
      ^case[DEFAULT]{$result.customrequest[^aOptions.method.upper[]]}
    }
  }

# Headers
  ^if(def $aOptions.cookies && $aOptions.cookies is hash){
    $result.cookie[^aOptions.cookies.foreach[k;v]{^taint[uri][$k]=^taint[uri][$v]^;}]
  }

# Form's
  ^if(^aOptions.contains[form]){
    $lForm[^hash::create[$aOptions.form]]
    ^if($lForm){
      ^switch[$aOptions.enctype]{
        ^case[;application/x-www-form-urlencoded]{
          ^switch[^aOptions.method.upper[]]{
            ^case[;GET;HEAD;DELETE]{
              $result.url[$result.url^if(^result.url.pos[?] >= 0){&}{?}^_formUrlencode[$lForm]]
            }
            ^case[POST]{
              $result.postfields[^_formUrlencode[$lForm]]
            }
          }
        }
        ^case[multipart/form-data]{
          $result.httppost[$lForm]
        }
        ^case[DEFAULT]{
          ^throw[cfile.options;Неизвестный enctype: "$aOptions.enctype".]
        }
      }
    }{
       $result.postfields[]
       $result.httppost[]
     }
  }

# Ranges
  ^if(def $aOptions.limit || def $aOptions.offset){
    $result.range[^aOptions.offset.int(0)-^if(def $aOptions.limit){^eval(^aOptions.offset.int(0) + ^aOptions.limit.int[] - 1)}]
  }

# SSL options
  $result.ssl_verifypeer(^aOptions.ssl-verifypeer.int(0))
  $result.ssl_verifyhost(^aOptions.ssl-verifyhost.int(0))

#  ^pfAssert:fail[^result.foreach[k;v]{$k}[, ]]

@_formUrlencode[aForm;aSeparator][k;v]
  $result[^aForm.foreach[k;v]{^switch[$v.CLASS_NAME]{
      ^case[table]{^_tableUrlencode[^taint[uri][$k];$v;$aSeparator]}
      ^case[file]{^taint[uri][$k]=^taint[uri][$v.text]}
      ^case[string;int;double;void]{^taint[uri][$k]=^taint[uri][$v]}
      ^case[bool]{^taint[uri][$k]=^v.int[]}
      ^case[date]{^taint[uri][$k]=^taint[uri][^v.sql-string[]]}
      ^case[DEFAULT]{^throw[cfile.options;Невозможно закодировать параметр $k типа ${v.CLASS_NAME}.]}
    }}[^if(def $aSeparator){$aSeparator}{&}]]

@_tableUrlencode[aName;aTable;aSeparator][lFieldName;lFields]
  $lFields[^aTable.columns[]]
  $lFieldName[^if($lFields){$lFields.column}{0}]
  $result[^aTable.menu{$aName=^taint[uri][$aTable.[$lFieldName]]}[^if(def $aSeparator){$aSeparator}{&}]]

