# PF Library

@CLASS
pfSiteModule

@USE
pf/modules/pfModule.p

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
## aOptions.
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]
  
  $_redirectExceptionName[pf.site.module.redirect]

# Тип ответа, возвращаемый модулем
  $_responseType[html] 

  $templatePath[$uriPrefix]
  
  $_createOptions[$aOptions]
  
  ^if(def $aOptions.sql && $aOptions.sql is pfSQL){
    $_sql[$aOptions.sql]
  }{
     $_sql[]
   }

  ^if(def $aOptions.auth && $aOptions.auth is pfAuthBase){
    $_auth[$aOptions.auth]
  }{
     $_auth[]
   }

  ^if(def $aOptions.cache && $aOptions.cache is pfCache){
    $_cache[$aOptions.cache]	
  }{
     $_cache[]
   }

  ^if(def $aOptions.templet && $aOptions.templet is pfTemplet){
    $_templet[$aOptions.templet]	
  }{
     $_templet[]
   }

#----- Public -----  

@assignModule[aName;aOptions][lArgs]
# Если нам не передали aOptions.args, то формируем штатный заменитель.
  ^cleanMethodArgument[]
  $lArgs[
        $.sql[$CSQL]
        $.auth[$AUTH]
        $.cache[$CACHE]
#        $.templet[$TEMPLET]
	$.templetOptions[$_createOptions.templetOptions]
  ]
  ^if(!def $aOptions.args){
    $aOptions.args[$lArgs]
  }{
     $aOptions.args[^aOptions.args.union[$lArgs]]
   }
  ^BASE:assignModule[$aName;$aOptions]

@dispatch[aAction;aRequest;aOptions][lResult;lPostDispatch]
  ^cleanMethodArgument[]
  $result[^BASE:dispatch[$aAction;$aRequest;$aOptions]]

  ^if($result is hash){
    ^if(!def $result.type){
      $result.type[$_responseType]
    }
  }{
     $result[
       $.type[^if($result is string || $result is double){$responseType}{Unknown result type: $result.CLASS_NAME}]
       $.body[$result]
     ]
   }

  $lPostDispatch[post^result.type.upper[]]
  $lPostDispatch[$$lPostDispatch]
  ^if($lPostDispatch is junction){
    $result[^lPostDispatch[$result]]
  }{
     ^if($postDEFAULT is junction){
       $result[^postDEFAULT[$result]]
     }
   }
  
@render[aTemplate;aOptions][lTemplatePrefix]
## Вызывает шаблон с именем "путь/$aTemplate[.pt]"
## Если aTemplate начинается со "/", то не подставляем текущий перфикс.
## Если переменная aTemplate не задана, то зовем шаблон default.
  ^if(!def $aTemplate || ^aTemplate.left(1) ne "/"){
     $lTemplatePrefix[$templatePath]
  }
  $result[^TEMPLET.render[${lTemplatePrefix}^if(def $aTemplate){$aTemplate^if(!def ^file:justext[$aTemplate]){.pt}}{default.pt};$aOptions]]

@display[aTemplate;aOptions]
## DEPRECATED!
  $result[^render[$aTemplate;$aOptions]]

@assignVar[aVarName;aValue]
## Задает переменную для шаблона
  ^TEMPLET.assign[$aVarName;$aValue]

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
#@postDEFAULT[aResponse]

# aResponse[$.type[html|xml|file|text|...] $.body[] ...] - хэш с данными ответа.
# Поля, которые могут быть обработаны контейнерами:
# $.content-type[] $.charset[] $.headers[] $.status[] $.cookie[]
# Для типа "file" можно положить ответ не в поле body, а в поле download.

@onDEFAULT[aRequest]
  ^if($onNOTFOUND is junction && def $action){
    $result[^onNOTFOUND[$aRequest]]
  }{
    $result[^onINDEX[$aRequest]]
   }

@onINDEX[aRequest]
  $result[]

##@onNOTFOUND[aRequest]
## Определить, если необходима обработка "404" ошибки. 

#----- Fabriques -----

@sqlFactory[aConnectString;aSqlOptions]
# Возвращает sql-объект исходя из $MAIN:SQL.connect-string
# Проверка на правильность строки не производится
  ^switch[^aConnectString.left(^aConnectString.pos[://])]{
    ^case[mysql]{
      ^use[pf/sql/pfMySQL.p]
      $result[^pfMySQL::create[$aConnectString;$aSqlOptions]]
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
# Возвращает templet-объект
  ^use[pf/templet/pfTemplet.p]
  $result[^pfTemplet::create[$aTempletOptions]]
