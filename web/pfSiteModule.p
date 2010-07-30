# PF Library

@CLASS
pfSiteModule

@USE
pf/modules/pfModule.p
pf/web/pfHTTPResponse.p

@BASE
pfModule

#----- Constructor -----

@create[aOptions]
## Создаем модуль. Если нам передали объекты ($.sql, $.cache и т.п.),
## то используем их, иначе вызываем соотвествующие фабрики и передаем 
## им параметры xxxType, xxxOptions.
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
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]
  
  $_redirectExceptionName[pf.site.module.redirect]

  $_responseType[html] 
  $_createOptions[$aOptions]

  $templatePath[$uriPrefix]
  
  $_sql[^if(def $aOptions.sql){$aOptions.sql}]
  $_auth[^if(def $aOptions.auth){$aOptions.auth}]
  $_cache[^if(def $aOptions.cache){$aOptions.cache}]
  $_templet[^if(def $aOptions.templet){$aOptions.templet}] 
  
  $_templateVars[^hash::create[]]
  
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

@dispatch[aAction;aRequest;aOptions][lResult;lPostDispatch]
  ^cleanMethodArgument[]

  ^try{
    $result[^BASE:dispatch[$aAction;$aRequest;$aOptions]]
  }{
    ^if($exception.type eq $_redirectExceptionName){
      $exception.handled(true)
      $result[^pfHTTPResponseRedirect::create[^aRequest.buildAbsoluteUri[$exception.comment]]]
    } 
  } 
  
  ^switch(true){
    ^case($result is hash){
      ^if(!def $result.type){$result.type[$_responseType]}
      ^if(!def $result.headers){$result.headers[^hash::create[]]}
      ^if(!def $result.cookie){$result.cookie[^hash::create[]]}
    }
    ^case($result is string || $result is double){
      $result[^pfHTTPResponse::create[$result;$.type[$responseType]]]
    }
  }

  $lPostDispatch[post^result.type.upper[]]
  ^if($self.[$lPostDispatch] is junction){
    $result[^self.[$lPostDispatch][$result]]
  }{
     ^if($postDEFAULT is junction){
       $result[^postDEFAULT[$result]]
     }
   }
  
@render[aTemplate;aOptions][lTemplatePrefix]
## Вызывает шаблон с именем "путь/$aTemplate[.pt]"
## Если aTemplate начинается со "/", то не подставляем текущий перфикс.
## Если переменная aTemplate не задана, то зовем шаблон default. 
  ^cleanMethodArgument[]
  ^if(!def $aTemplate || ^aTemplate.left(1) ne "/"){
     $lTemplatePrefix[$templatePath]
  }
  $result[^TEMPLET.render[${lTemplatePrefix}^if(def $aTemplate){$aTemplate^if(!def ^file:justext[$aTemplate]){.pt}}{default.pt};
    $.vars[^if(def $aOptions.vars){$aOptions.vars}{$_templateVars}]
    $.force($aOptions.force)
    $.engine[$aOptions.engine]
  ]]

@display[aTemplate;aOptions]
## DEPRECATED!
  $result[^render[$aTemplate;$aOptions]]

@assignVar[aVarName;aValue]
## Задает переменную для шаблона
#  ^TEMPLET.assign[$aVarName;$aValue]
  $_templateVars.[$aVarName][$aValue]
  $result[]

@redirectTo[aAction;aOptions;aAnchor]  
  ^throw[$_redirectExceptionName;$action;^linkTo[$aAction;$aOptions;$aAnchor]]

#----- Properties -----

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
  }
  
#----- Private -----

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
      ^pfAssert:fail[pfSiteModule.sqlFactory. Bad connect-string.]
    }
  }

@authFactory[aAuthType;aAuthOptions]
# Возвращает auth-объект на основании aAuthType
  ^switch[$aAuthType]{
    ^case[base;DEFAULT]{
      ^use[pf/auth/pfAuthBase.p]
        $result[^pfAuthBase::create[$aAuthOptions]]
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
