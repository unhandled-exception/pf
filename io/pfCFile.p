# PF Library

@CLASS
pfCFile

@auto[]
  $_curlSessionsCnt(0)

@load[aMode;aURL;aOptions]
  ^if(^reflection:dynamical[]){^throw[dynamic.call;Динамический вызов статического метода.]}
  ^if(!def $aOptions || $aOptions is string){$aOptions[^hash::create[]]}
  ^session{
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
  }

@session[aCode]
## Организует сессию для запроса   
  ^if(^reflection:dynamical[]){^throw[dynamic.call;Динамический вызов статического метода.]}
  ^_curlSessionsCnt.inc[]
  $result[^if($_curlSessionsCnt > 1){$aCode}{^curl:session{$aCode}}]
  ^_curlSessionsCnt.dec[]

@options[aOptions]
## Задает опции для libcurl (вызов curl:options)
## Можно вызывать только внутри сессии
  ^if(^reflection:dynamical[]){^throw[dynamic.call;Динамический вызов статического метода.]}
  ^if(!$_curlSessionsCnt){^throw[cfile.options;Вызов вне session.]}
  $result[]
  ^curl:options[$aOptions]

@_makeCurlOptions[aMode;aURL;aOptions][k;v]
## Формирует параметры для curl:load (curl:options) 
  $result[^hash::create[]]
  ^if(!($aMode eq "text" || $aMode eq "binary")){^throw[cfile.mode;Mode must be "text" or "binary".]}

  $result.url[$aURL]
  $result.mode[$aMode]
  ^if(def $aOptions.name){$result.name[$aOptions.name]}
  ^if(def ${aOptions.content-type}){$result.content-type[$aOptions.content-type]}
  ^if(def $aOptions.charset){$result.charset[$aOptions.charset]}

# Connection
  $result.timeout(^aOptions.timeout.int(2))
  ^if(!^result.compressed.bool(true)){$result.encoding[identity]}{$result.encoding[]}

  $result.failonerror(!^aOptions.any-status.int(0))
  ^if(def ${aOptions.follow-location}){$result.followlocation(^aOptions.follow-location.int(0))}
  ^if(def ${aOptions.max-redirs}){$result.maxredirs(^aOptions.max-redirs.int(-1))}
  ^if(def ${aOptions.post-redir}){$result.postredir(${aOptions.post-redir})}
  ^if(def ${aOptions.autoreferer}){$result.autoreferer(^aOptions.autoreferer.int(0))}
  ^if(def ${aOptions.urestricted-auth}){$result.urestricted_auth(^aOptions.urestricted-auth.int(0))}
  
# Proxies
  ^if(def ${aOptions.proxy-host}){$result.proxy[$aOptions.proxy-host]}
  ^if(def ${aOptions.proxy-port}){$result.proxyport($aOptions.proxy-port)}
  ^if(def ${aOptions.proxy-type}){$result.proxytype($aOptions.proxy-type)}

# Auth
  ^if(def $result.user){$result.userpwd[${aOptions.user}:$aOptions.password]}

# Method
  ^switch[^if(def $aOptions.method){^aOptions.method.upper[]}]{
    ^case[;GET]{$result.httpget(1)}
    ^case[POST]{$result.post(1)}
    ^case[HEAD]{$result.nobody(1)}
    ^case[DEFAULT]{$result.customrequest[^aOptions.method.upper[]]}
  }

# Headers  
  ^if(def $aOptions.headers){$result.httpheader[$aOptions.headers]}
  ^if(def $aOptions.cookies && $aOptions.cookies is hash){
    $result.cookie[^aOptions.cookies.foreach[k;v]{$k=$v^;}]
  }                           
  ^if(def $aOptions.cookiesession){$result.cookiesession(^aOptions.cookiesession.int(1))}
  ^if(def ${aOptions.user-agent}){$result.useragent[$aOptions.user-agent]}
  ^if(def $aOptions.referer){$result.referer[$aOptions.referer]}

# POST body
  ^if(def $aOptions.form){$result.httppost[$aOptions.form]}
  ^if(def $aOptions.body){$result.postfields[$aOptions.body]}

# Ranges
  ^if(def $aOptions.limit || def $aOptions.offset){
    $result.range[^aOptions.offset.int(0)-^if(def $aOptions.limit){^eval(^aOptions.offset.int(0) + ^aOptions.limit.int[] - 1)}]
  }
  
# SSL options
  $result.ssl_verifypeer(^aOptions.ssl-verifypeer.int(0))
  $result.ssl_verifyhost(^aOptions.ssl-verifyhost.int(0))
  ^if(def ${aOptions.ssl-cert}){$result.sslcert[$aOptions.ssl-cert]}
  ^if(def ${aOptions.ssl-certtype}){$result.sslcerttype[$aOptions.ssl-certtype]}
  ^if(def ${aOptions.ssl-key}){$result.sslkey[$aOptions.ssl-key]}
  ^if(def ${aOptions.ssl-keytype}){$result.sslkeytype[$aOptions.ssl-keytype]}
  ^if(def ${aOptions.ssl-keypasswd}){$result.keypasswd[$aOptions.ssl-keypasswd]}
  ^if(def ${aOptions.ssl-issuercert}){$result.issuercert[$aOptions.ssl-issuercert]}
  ^if(def ${aOptions.ssl-crlfile}){$result.crlfile[$aOptions.ssl-crlfile]}
  ^if(def ${aOptions.ssl-cainfo}){$result.cainfo[$aOptions.ssl-cainfo]}
  ^if(def ${aOptions.ssl-capath}){$result.capath[$aOptions.ssl-capath]}
  ^if(def ${aOptions.ssl-cipher-list}){$result.ssl_cipher_list[$aOptions.ssl-cipher-list]}
  ^if(def ${aOptions.ssl-sessionid-cache}){$result.ssl_sessionid_cache(^aOptions.ssl-sessionid-cache.int(0))}
  
  