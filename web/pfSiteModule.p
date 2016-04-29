# PF Library

@CLASS
pfSiteModule

@USE
pf/modules/pfModule.p
pf/web/pfHTTPRequest.p
pf/web/pfHTTPResponse.p

@BASE
pfModule

#----- Constructor -----

@create[aOptions]
## Создаем модуль. Если нам передали объекты ($.sql, $.cache и т.п.),
## то используем их, иначе вызываем соотвествующие фабрики и передаем
## им параметры xxxType, xxxOptions.
## aOptions.asManager(false) — использовать модуль как менеджер.
## aOptions.passDefaultPost(!asManager) — пропустить постобработку.
## aOptions.cache
## aOptions.cacheType - не используется
## aOptions.cacheOptions
## aOptions.sql
## aOptions.sqlConnectString[$MAIN:SQL.connect-string]
## aOptions.sqlOptions
## aOptions.auth
## aOptions.authType
## aOptions.authOptions
## aOptions.templet
## aOptions.templetOptions
## aOptions.templatePrefix
## aOptions.request
## aOptions.uriProtocol
## aOptions.uriServerName
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]

  $_asManager(^aOptions.asManager.bool(false))
  $_passDefaultPost(^aOptions.passDefaultPost.bool(!$_asManager))

  $_redirectExceptionName[pf.site.module.redirect]
  $_permanentRedirectExceptionName[pf.site.module.permanent_redirect]

  $_responseType[html]
  $_createOptions[$aOptions]

  $templatePath[^if(^aOptions.contains[templatePrefix]){$aOptions.templatePrefix}{$mountPoint}]

  $_sql[^if(def $aOptions.sql){$aOptions.sql}]
  $_auth[^if(def $aOptions.auth){$aOptions.auth}]
  $_cache[^if(def $aOptions.cache){$aOptions.cache}]
  $_templet[^if(def $aOptions.templet){$aOptions.templet}]

  $_templateVars[^hash::create[]]

# Метод display лучше не использовать (deprecated).
  ^alias[display;$render]

# Переменные для менеджера
  $_REQUEST[$aOptions.request]
  $_uriProtocol[$aOptions.uriProtocol]
  $_uriServerName[$aOptions.uriServerName]


@auto[]
# Дополнительная таблица mime-типов
# Можно расширить в наследниках для поддержки нужных типов.
  $_PFSITEMODULE_EXT_MIME[
    $.css[text/css]
    $.csv[text/csv]
    $.docx[application/vnd.openxmlformats-officedocument.wordprocessingml.document]
    $.flv[video/x-flv]
    $.gz[application/x-gzip]
    $.json[application/json]
    $.js[application/javascript]
    $.odc[application/vnd.oasis.opendocument.chart]
    $.odf[application/vnd.oasis.opendocument.formula]
    $.odg[application/vnd.oasis.opendocument.graphics]
    $.odi[application/vnd.oasis.opendocument.image]
    $.odp[application/vnd.oasis.opendocument.presentation]
    $.ods[application/vnd.oasis.opendocument.spreadsheet]
    $.odt[application/vnd.oasis.opendocument.text]
    $.ogg[audio/ogg]
    $.pptx[application/vnd.openxmlformats-officedocument.presentationml.presentation]
    $.rar[application/x-rar-compressed]
    $.rdf[application/rdf+xml]
    $.rss[application/rss+xml]
    $.tar[application/x-tar]
    $.woff[application/font-woff]
    $.xlsx[application/vnd.openxmlformats-officedocument.spreadsheetml.sheet]
    $.xul[application/vnd.mozilla.xul+xml]
  ]
# Стандартный mime-тип
  $_PFSITEMODULE_DEFAULT_MIME[application/octet-stream]


#----- Public -----

@assignModule[aName;aOptions][lArgs]
# Если нам не передали aOptions.args, то формируем штатный заменитель.
  ^cleanMethodArgument[]
  $lArgs[
    $.sql[$CSQL]
    $.auth[$AUTH]
    $.cache[$CACHE]
    $.templetOptions[$_createOptions.templetOptions]
    $.templet[$TEMPLET]
  ]
  ^if(!def $aOptions.args){
    $aOptions.args[$lArgs]
  }{
     $aOptions.args[^aOptions.args.union[$lArgs]]
   }
  ^BASE:assignModule[$aName;$aOptions]

@processAction[aAction;aRequest;aPrefix;aOptions][lRedirectPath]
## aOptions.passWrap(false) - не формировать объект вокруг ответа из строк и чисел.
## aOptions.passRedirect(false) - не обрабатывать эксепшн от редиректа.
  ^cleanMethodArgument[]
  ^try{
    ^if(def $aOptions.render && def $aOptions.render.template){
      $result[^render[$aOptions.render.template;$.vars[$aOptions.render.vars]]]
    }{
       $result[^BASE:processAction[$aAction;$aRequest;$aPrefix;$aOptions]]
     }

    ^if(!^aOptions.passWrap.bool(false)){
      ^switch(true){
        ^case($result is hash){
          ^if(!def $result.type){$result.type[$_responseType]}
          ^if(!def $result.status){$result.status[200]}
          ^if(!def $result.headers){$result.headers[^hash::create[]]}
          ^if(!def $result.cookie){$result.cookie[^hash::create[]]}
        }
        ^case($result is string || $result is double){
          $result[^pfHTTPResponse::create[$result;$.type[$responseType]]]
        }
      }
    }

  }{
    ^if(!^aOptions.passRedirect.bool(false)){
      ^switch[$exception.type]{
        ^case[$_redirectExceptionName;$_permanentRedirectExceptionName]{
          $exception.handled(true)
          $lRedirectPath[^if(^exception.comment.match[^^https?://][n]){$exception.comment}{^aRequest.buildAbsoluteUri[$exception.comment]}]
          ^if($exception.type eq $_permanentRedirectExceptionName){
            $result[^pfHTTPResponsePermanentRedirect::create[$lRedirectPath]]
          }{
             $result[^pfHTTPResponseRedirect::create[$lRedirectPath]]
           }
        }
      }
    }
  }

@processResponse[aResponse;aAction;aRequest;aOptions][lPostDispatch]
## aOptions.passPost(false) - не делать постобработку запроса.
  ^cleanMethodArgument[]
  $result[^BASE:processResponse[$aResponse;$aAction;$aRequest;$aOptions]]

  ^if(!^aOptions.passPost.bool(false)){
    $lPostDispatch[post^result.type.upper[]]
    ^if($self.[$lPostDispatch] is junction){
      $result[^self.[$lPostDispatch][$result]]
    }{
       ^if($postDEFAULT is junction){
         $result[^postDEFAULT[$result]]
       }
     }
  }

@render[aTemplate;aOptions][lTemplatePrefix;lVars]
## Вызывает шаблон с именем "путь/$aTemplate[.pt]"
## Если aTemplate начинается со "/", то не подставляем текущий перфикс.
## Если переменная aTemplate не задана, то зовем шаблон default.
## aOptions.vars - переменные, которые добавляются к тем, что уже заданы через assignVar.
  ^cleanMethodArgument[]
  ^if(!def $aTemplate || ^aTemplate.left(1) ne "/"){
     $lTemplatePrefix[$templatePath]
  }

  $lVars[^hash::create[$_templateVars]]
  $lVars[^lVars.union[^templateDefaults[]]]
  ^if(def $aOptions.vars){^lVars.add[$aOptions.vars]}

  $result[^TEMPLET.render[${lTemplatePrefix}^if(def $aTemplate){$aTemplate^if(!def ^file:justext[$aTemplate]){.pt}}{default.pt};
    $.vars[$lVars]
    $.force($aOptions.force)
    $.engine[$aOptions.engine]
  ]]

@templateDefaults[]
## Задает переменные шаблона по умолчанию.
  $result[
    $.REQUEST[$REQUEST]
    $.ACTION[$ACTION]
    $.linkTo[$linkTo]
    $.redirectTo[$redirectTo]
    $.linkFor[$linkFor]
    $.redirectFor[$redirectFor]
  ]

@assignVar[aVarName;aValue]
## Задает переменную для шаблона
  $_templateVars.[$aVarName][$aValue]
  $result[]

@multiAssignVar[aVars]
## Задает сразу несколько переменных в шаблон.
  ^aVars.foreach[k;v]{
    ^assignVar[$k;$v]
  }

@redirectTo[aAction;aOptions;aAnchor;aIsPermanent]
  ^throw[^if(^aIsPermanent.bool(false)){$_permanentRedirectExceptionName}{$_redirectExceptionName};$action;^if(^aAction.match[^^https?://][n]){$aAction}{^linkTo[$aAction;$aOptions;$aAnchor]}]

@redirectFor[aAction;aObject;aOptions]
## aOptions - аналогично linkFor
## aOptions.permanent(false)
  ^cleanMethodArgument[]
  ^throw[^if(^aOptions.permanent.bool(false)){$_permanentRedirectExceptionName}{$_redirectExceptionName};$action;^if(^aAction.match[^^https?://][n]){$aAction}{^linkFor[$aAction;$aObject;$aOptions]}]


#----- Методы менеджера -----

@run[aOptions][lRequest;lResult;lAction]
## Основной процесс обработки запроса (как правило перекрывать не нужно).
## Не забудьте задать в кончтрукторе параметр asManager, чтобы сработала постобработка.
  $lRequest[$REQUEST]
  $lAction[$lRequest._action]
  ^authenticate[$lAction;$lRequest]
  $result[^dispatch[$lAction;$lRequest]]

@authenticate[aAction;aRequest]
## Производит авторизацию.
  ^if(^AUTH.identify[$aRequest]){
    $result[^onAUTHSUCCESS[$aRequest]]
   }{
      $result[^onAUTHFAILED[$aRequest]]
    }

#----- Properties -----

@GET_asManager[]
  $result($_asManager)

@GET_AUTH[]
  ^if(!def $_auth){
  	 $_auth[^authFactory[$_createOptions.authType;$_createOptions.authOptions]]
  }
  $result[$_auth]

@GET_CSQL[]
  ^if(!def $_sql){
      $_sql[^sqlFactory[^if(def $_createOptions.sqlConnectString){$_createOptions.sqlConnectString}{$MAIN:SQL.connect-string};$_createOptions.sqlOptions]]
  }
  $result[$_sql]

@GET_CACHE[]
  ^if(!def $_cache){
  	 $_cache[^cacheFactory[$_createOptions.cacheType;$_createOptions.cacheOptions]]
  }
  $result[$_cache]

@GET_TEMPLET[]
  ^if(!def $_templet){
  	 $_templet[^templetFactory[$_createOptions.templetOptions]]
  }
  $result[$_templet]

@SET_templatePath[aPath]
  $_templatePath[^if(def $aPath){^aPath.trim[both;/]}/]

@GET_templatePath[]
  $result[$_templatePath]

@GET_responseType[]
  $result[$_responseType]

@SET_responseType[aValue]
  $_responseType[$aValue]

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

# Обработчик ответа будет вызываться после диспатча по следующему алгоритму:
# сначала пытаемся вызвать обработчик postTYPE, а если его нет, то зовем
# postDEFAULT.

#@postHTML[aResponse]
#@postXML[aResponse]
#@postTEXT[aResponse]
#@postREDIRECT[aResponse]
#@postDEFAULT[aResponse]

# aResponse[$.type[as-is|html|xml|file|text|...|redirect] $.body[] ...] - хэш с данными ответа.
# Поля, которые могут быть обработаны контейнерами:
# $.content-type[] $.charset[] $.headers[] $.status[] $.cookie[]
# Для типа "file" можно положить ответ не в поле body, а в поле download.

@onNOTFOUND[aRequest]
## Переопределить, если необходима отдельная обработка неизвестного экшна (аналог "404").
  $result[]
  ^if($self.onINDEX is junction || $self.onDEFAULT is junction){
    ^redirectTo[/]
  }{
     ^throw[pfSiteModule.action.not.found;Action "$action" not found.]
   }

@onAUTHSUCCESS[aRequest]
## Вызывается при удачной авторизации.
  ^if($_asManager && $self.onAuthSuccess is junction){
    $result[^onAuthSuccess[$aRequest]]
  }{
     $result[]
  }

@onAUTHFAILED[aRequest]
## Вызывается при неудачной авторизации
  ^if($_asManager && $self.onAuthFailed is junction){
    $result[^onAuthFailed[$aRequest]]
  }{
     $result[]
  }


# Пост-обработчики для менеджера

@postDEFAULT[aResponse]
  $result[$aResponse]
  ^if(!$_passDefaultPost){
    ^throw[pfSiteManager.postDEFAULT;Unknown response type "$aResponse.type".]
  }

@postAS-IS[aResponse]
  ^if($_passDefaultPost){
    $result[^postDEFAULT[$aResponse]]
  }{
    $result[]
    ^_setResponseHeaders[$aResponse]
    ^if(def $aResponse.download){
      $response:download[$aResponse.download]
    }{
       $response:body[$aResponse.body]
     }
  }

@postHTML[aResponse]
  ^if($_passDefaultPost){
    $result[^postDEFAULT[$aResponse]]
  }{
    ^if(!def $aResponse.[content-type]){
      $aResponse.content-type[text/html]
    }
    ^_setResponseHeaders[$aResponse]
    $result[$aResponse.body]
  }

@postXML[aResponse]
  ^if($_passDefaultPost){
    $result[^postDEFAULT[$aResponse]]
  }{
    ^if(!def $aResponse.[content-type]){
     $aResponse.content-type[text/xml]
    }
    ^_setResponseHeaders[$aResponse]
    $result[^untaint[xml]{$aResponse.body}]
  }

@postTEXT[aResponse]
  ^if($_passDefaultPost){
    $result[^postDEFAULT[$aResponse]]
  }{
    ^if(!def $aResponse.[content-type]){
      $aResponse.content-type[text/plain]
    }
    ^_setResponseHeaders[$aResponse]
    $result[^untaint[as-is]{$aResponse.body}]
  }

@postFILE[aResponse]
  ^if($_passDefaultPost){
    $result[^postDEFAULT[$aResponse]]
  }{
    $result[]
    ^if(!def $aResponse.[content-type]){
      $aResponse.content-type[application/octet-stream]
    }
    ^if(def $aResponse.download){
      $response:download[$aResponse.download]
    }{
       $response:body[$aResponse.body]
     }
    ^_setResponseHeaders[$aResponse]
  }

@postREDIRECT[aResponse]
  ^if($_passDefaultPost){
    $result[^postDEFAULT[$aResponse]]
  }{
    $result[]
    ^_setResponseHeaders[$aResponse]
  }

#----- Private -----

@_getMimeByExt[aExt]
## Возвращает mime-тип для файла.
## Полезно, если нужно сделать выдачу файлов в браузер.
  ^if(^MAIN:MIME-TYPES.locate[ext;$aExt]){
    $result[$MAIN:MIME-TYPES.mime-type]
  }(^_PFSITEMODULE_EXT_MIME.contains[$aExt]){
     $result[$_PFSITEMODULE_EXT_MIME.[$aExt]]
#    Хак: добавляем тип в MAIN:MIME-TYPES, чтобы он работал для файлов в response:body
     ^MAIN:MIME-TYPES.append{$aExt	$result}
  }{
     $result[$_PFSITEMODULE_DEFAULT_MIME]
   }

@_findHandler[aAction;aRequest][lActionName;lMethod]
## Ищет и возвращает имя функции-обработчика для экшна.
  $result[^BASE:_findHandler[$aAction;$aRequest]]

# Ищем onActionHTTPMETHOD-обработчик
  $lMethod[^if(def $aRequest.METHOD){^aRequest.METHOD.upper[]}]
  ^if(def $lMethod){
    $lActionName[^_makeActionName[$aAction]]
    ^if(def $lActionName && $self.[${lActionName}$lMethod] is junction){$result[${lActionName}$lMethod]}
  }

# Если не определен onDEFAULT, то зовем onNOTFOUND.
  ^if(!def $result && $onNOTFOUND is junction){$result[onNOTFOUND]}

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

#----- Fabriques -----

@sqlFactory[aConnectString;aSqlOptions]
# Возвращает sql-объект исходя из $MAIN:SQL.connect-string
# Проверка на правильность строки не производится
  ^switch[^aConnectString.left(^aConnectString.pos[://])]{
    ^case[mysql]{
      ^use[pf/sql/pfMySQL.p]
      $result[^pfMySQL::create[$aConnectString;$aSqlOptions]]
    }
    ^case[sqlite]{
      ^use[pf/sql/pfSQLite.p]
      $result[^pfSQLite::create[$aConnectString;$aSqlOptions]]
    }
    ^case[DEFAULT]{
      ^if(def $aConnectString){
        ^throw[pfSiteModule.bad.connect.string;Bad connect-string: "$aConnectString".]
      }{
         $result[]
       }
    }
  }

@authFactory[aAuthType;aAuthOptions]
# Возвращает auth-объект на основании aAuthType
  ^switch[$aAuthType]{
    ^case[base;DEFAULT]{
      ^use[pf/auth/pfAuthBase.p]
        $result[^pfAuthBase::create[$aAuthOptions]]
    }
    ^case[apache]{
      ^use[pf/auth/pfAuthApache.p]
        $result[^pfAuthApache::create[$aAuthOptions]]
    }
    ^case[cookie]{
      ^use[pf/auth/pfAuthCookie.p]
        $result[^pfAuthCookie::create[$aAuthOptions]]
    }
  }

@cacheFactory[aCacheType;aCacheOptions]
# Возвращает cache-объект
  ^use[pf/cache/pfCache.p]
  $result[^pfCache::create[$aCacheOptions]]

@templetFactory[aTempletOptions]
# Возвращает temple-объект
  ^use[pf/templet/pfTemple.p]
  $result[^pfTemple::create[$aTempletOptions]]
