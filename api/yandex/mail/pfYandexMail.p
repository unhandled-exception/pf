# PF Library
#@compat: 3.4.1

# API "почты для домена" - http://pdd.yandex.ru/help/section72/

@CLASS
pfYandexMail

@USE
pf/types/pfClass.p
pf/io/pfCFile.p

@BASE
pfClass

@create[aOptions]
## aOptions.url
## aOptions.token
## aOptions.timeout(60)
  ^cleanMethodArgument[]
  
  $_apiURL[^if(def $aOptions.url){$aOptions.url}{https://pddimp.yandex.ru/}]
  $_token[$aOptions.token]
  $_timeout(^aOptions.timeout.int(60))

@session[aCode]
## Организуем сессию, если нам необходимо обработать несколько запросов подряд
  $result[^pfCFile:session{$aCode}]

@checkError[aHTTPStatus;aXML;aHandlerName;aParams][lError]
  ^if($aHTTPStatus < 200 || $aHTTPStatus >= 300){
    ^throw[pfYandexMail.fail;$aHandlerName fail ($aHTTPStatus)]
  }
  $lError[^aXML.selectString[string(//page/error/@reason)]]
  ^if(def $lError){
    ^throw[pfYandexMail.fail;$aHandlerName fail;Error: $lError]
  }
  $result(true)

@checkOK[aXML]
  $result(^aXML.selectSingle[//page/ok])

  ^if(!$result){
    ^pfAssert:fail[stop]
  }

@_invokeHandler[aHandlerName;aParams;aOptions][lResponse]
## aHandlerName - имя обработчика
## aParams - хеш с переменными запроса
## aOptions.method[get]
  ^cleanMethodArgument[]
  ^cleanMethodArgument[aParams]
  ^pfAssert:isTrue(def $aHandlerName)[Не задано имя обработчика.]

  $lResponse[^pfCFile:load[text;${_apiURL}${aHandlerName}.xml][
    $.any-status(true)
    $.ssl-verifypeer(false)
    $.ssl-verifyhost(false)
    $.timeout($_timeout)
    $.method[^if(def $aOptions.method){$aOptions.method}{get}]
    $.form[$aParams ^if(!def $aParams.token){$.token[$_token]}]
  ]]

  $result[^xdoc::create{^taint[as-is][$lResponse.text]}]
  ^checkError[$lResponse.status;$result;$aHandlerName;$aParams]

@createUser[aLogin;aPassword]
  ^pfAssert:isTrue(def $aLogin && def $aPassword)[Не заданы логин и пароль.]
  $result(^checkOK[^_invokeHandler[reg_user_token;
    $.u_login[$aLogin]
    $.u_password[$aPassword]
  ]])

@deleteUser[aLogin]
  ^pfAssert:isTrue(def $aLogin)[Не задан логин.]
  $result(^checkOK[^_invokeHandler[delete_user;
    $.login[$aLogin]
  ]])
  
@editUserDetails[aLogin;aOptions]
## aOptions.password – пароль пользователя
## aOptions.firstName – имя пользователя
## aOptions.lastName – фамилия пользователя
## aOptions.sex – пол пользователя (1 – мужской, 2 – женский)
  ^pfAssert:isTrue(def $aLogin)[Не задан логин.]
  ^cleanMethodArgument[]
  $result(^checkOK[^_invokeHandler[edit_user;
    $.login[$aLogin]
    $.password[$aOptions.password]
    $.iname[$aOptions.firstName]
    $.fname[$aOptions.lastName]
    $.sex[$aOptions.sex]
  ]])

@setImportSettings[aOptions]
## aOptions.method – pop3 или imap
## aOptions.server – доменное имя pop3 или imap сервера-источника
## aOptions.port – (optional) порт на сервере-источнике, 
##                 параметр нужен только если номер порта отличается от стандартного 
##                 для данного протокола стандартные порты: 110 – POP3 без SSL, 995 – POP3 с SSL
## aOptions.isSSL(false) – (optional) значение “no”, если данный сервер не поддерживает SSL, 
##                      если соединяемся по SSL, указывать данный параметр не надо
## aOptions.callback – (optional) если параметр не пустой, то по окончании импорта пользовательского ящика, 
##                     будет сделан http запрос по этому адресу с параметром login="логин импортированного пользователя". 
##                     Вызов должен возвращать XML вида: <page><status>moved</status></page>", 
##                     в случае, если подтверждено, что ящик корректно перенесся  
  ^cleanMethodArgument[]
  $result(^checkOK[^_invokeHandler[set_domain;
    $.method[$aOptions.method]
    $.ext_serv[$aOptions.server]
    ^if(def $aOptions.port){$.ext_port[$aOptions.port]}
    ^if(def $aOptions.isSSL){$.isssl[^if(!^aOptions.isSSL.bool(false)){no}]}
    ^if(def $aOptions.callback){$.callback[$aOptions.callback]}
  ]])

@startImport[aLogin;aExtLogin;aExtPassword]
  ^pfAssert:isTrue(def $aLogin)[Не задан логин.]
  ^pfAssert:isTrue(def $aExtLogin)[Не задан логин на внешнем сервере.]
  ^pfAssert:isTrue(def $aExtPassword)[Не задан пароль.]
  $result(^checkOK[^_invokeHandler[start_import;
    $.login[$aLogin]
    $.ext_login[$aExtLogin]
    $.password[$aExtPassword]
  ]])

