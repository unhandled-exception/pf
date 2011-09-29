# PF Library
#@compat: 3.4.1

# Интерфейс для sms-шлюза компании «Связной Загрузка» — http://www.zagruzka.com/

@CLASS
pfZagruzkaSMSGate

@USE
pf/types/pfClass.p
pf/io/pfCFile.p

@BASE
pfClass

@create[aOptions]      
## aOptions.serviceId[] — service_id
## aOptions.password[]
## aOptions.url[https://smsinfo.zagruzka.com/aggrweb]
## aOptions.shortNumber[]
## aOptions.timeout(30)
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aOptions.serviceId)[Не задано имя пользователя (serviceId).]

  ^BASE:create[$aOptions]
  $_serviceId[$aOptions.serviceId]
  $_password[$aOptions.password]
  $_url[^if(def $aOptions.url){$aOptions.url}{https://smsinfo.zagruzka.com/aggrweb}]
  $_shortNumber[$aOptions.shortNumber]

  $_timeout(^aOptions.timeout.int(30))
  
  $_requestCharset[utf-8]
  $_responseCharset[utf-8]      
  $_maxMessageLength(480)

@send[aPhone;aMessage;aOptions][lResp]
## aPhone - номер телефона (для россии номер должен быть в формате 7xxxxxxxxxx)
## aMessage
## result[$.status[bool] $.smsID[table] $.comment[]] - результат операции
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aMessage)[Не задан текст сообщения.]
  ^pfAssert:isTrue(def $aPhone)[Не задан получатель сообщения.]
  $result[]
  ^try{
    $lResp[^pfCFile:load[text;$_url;
      $.method[post]
      $.charset[$_requestCharset]
      $.response-charset[$_responseCharset]
      $.any-status(false)
      $.form[      
        $.clientId[$aPhone]
        $.message[$aMessage]
        $.serviceId[$_serviceId]
        $.pass[$_password]        
        ^if(def $_shortNumber){
          $.shortNumber[$_shortNumber]
        }
      ]
    ]]                      
    ^switch[$lResp.status]{
      ^case[200;DEFAULT]{
        $result[
          $.status(true)
          $.smsID[^lResp.text.match[^^(\d+)^$][gm]]
        ]            
      }
      ^case[500;408]{
        $result[
          $.status(false) 
          $.comment[$lResp.text]
        ]
      }
      ^case[401]{^throw[sms.gate.unauthorized;Доступ к серису запрещен (неверные serviceId и password).]}
      ^case[403;406]{^throw[sms.gate.bad_phone;Невозможно отправить сообщение на номер "$aOptions.phone".]}
    }
  }{
     ^if(^exception.type.match[^^(?:http|cfile)\.][n]){
       ^throw[${self.CLASS_NAME}.fail;Ошибка при работе с смс-шлюзом;${exception.type}: $exception.comment]
     }
   }
   
@session[aCode]
## Организует единую сессию для работы с сервисом.
## Нужно только для массовой работы.
  $result[^pfCFile:session{$aCode}]
