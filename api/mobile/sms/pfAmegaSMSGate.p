# PF Library
#@compat: 3.4.1

# Интерфейс для http://www.amegainform.ru/usl_sms/index.html

@CLASS
pfAmegaSMSGate

@USE
pf/types/pfClass.p
pf/io/pfCFile.p

@BASE
pfClass

@create[aOptions]
## aOptions.user[]
## aOptions.password[]
## aOptions.url[https://beeline.amega-inform.ru/sendsms/]
## aOptions.comment[]
## aOptions.clientIP[]
## aOptions.timeout(10)
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aOptions.user)[Не задано имя пользователя]

  ^BASE:create[$aOptions]
  $_user[$aOptions.user]
  $_password[$aOptions.password]
  $_url[^if(def $aOptions.url){$aOptions.url}{https://beeline.amega-inform.ru/sendsms/}]

  $_comment[$aOptions.comment]
  $_clientIP[$aOptions.ip]
  $_timeout(^aOptions.timeout.int(30))

  $_requestCharset[windows-1251]
  $_responseCharset[utf-8]
  $_maxMessageLength(480)

@send[aMessage;aOptions][lResp]
## aOptions.phones - список телефонов, через запятую (валидность телефонов проверяется на стороне сервиса).
## aOptions.codename - кодовое имя контакт-листа в системе (если задано, то список телефонов не передается)
## aOptions.sender - имя отправителя зарегистрированного для вас, в системе beeline.amega-inform.ru
## result[hash] - результат разбора xml-ответа сервиса
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aMessage)[Не задан текст сообщения.]
  ^pfAssert:isTrue(^aMessage.length[] < $_maxMessageLength)[Превышена максимальная длина сообщения.]
  ^pfAssert:isTrue(def $aOptions.phones || def $aOptions.codename)[Не задан получатель сообщения.]
  $result[]
  ^try{
    $lResp[^pfCFile:load[text;$_url;
      $.method[post]
      $.charset[$_requestCharset]
      $.response-charset[$_responseCharset]
      $.any-status(false)
      $.form[
        $.action[post_sms]
        $.user[$_user]
        $.pass[$_password]
        $.message[$aMessage]
        ^if(def $_clientIP){$.CLIENTADR[$_clientIP]}
        ^if(def $_comment){$.comment[$_clientIP]}
        ^if(def $aOptions.codename){
          $.phl_codename[$aOptions.codename]
        }{
           $.target[$aOptions.phones]
         }
      ]
    ]]
    $result[^_parseResponse[$lResp.text]]
  }{
     ^if(^exception.type.match[^^(?:http|cfile)\.][n]){
       ^throw[${self.CLASS_NAME}.fail;Ошибка при работе с смс-шлюзом;${exception.type}: $exception.comment]
     }
   }

@status[aType;aOptions][lResp]
## $aType[sms|group|period] - информация о статусе сообщений для одной смс, группы или за период
## sms - aOptions.smsID
## group - aOptions.groupID
## period - aOptions.from && aOptions.to
## result[hash] - результат разбора xml-ответа сервиса
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aType)[Не задан тип запроса.]
  ^try{
    $lResp[^pfCFile:load[text;$_url;
      $.method[post]
      $.charset[$_requestCharset]
      $.response-charset[$_responseCharset]
      $.any-status(false)
      $.form[
        $.action[status]
        $.user[$_user]
        $.pass[$_password]
        ^if(def $_clientIP){$.CLIENTADR[$_clientIP]}
        ^if(def $_comment){$.comment[$_clientIP]}

        ^switch[$aType]{
          ^case[sms]{
            ^pfAssert:isTrue(^aOptions.smsID.int[] >= 0)[Неверный идентификатор смс.]
            $.sms_id[$aOptions.smsID]
          }
          ^case[group]{
            ^pfAssert:isTrue(^aOptions.groupID.int[] >= 0)[Неверный идентификатор группы.]
            $.sms_group_id[$aOptions.groupID]
          }
          ^case[period]{
            ^pfAssert:isTrue(def $aOptions.from && def $aOptions.to)[Не задан период.]
            $.date_from[^formatDate[$aOptions.from]]
            $.date_to[^formatDate[$aOptions.to]]
          }
          ^case[DEFAUT]{
            ^pfAssert:fail[Неизвестный тип запроса: "$aType".]
          }
        }
      ]
    ]]
    $result[^_parseResponse[^taint[as-is][$lResp.text]]]
  }{
     ^if(^exception.type.match[^^(?:http|cfile)\.][n]){
       ^throw[${self.CLASS_NAME}.fail;Ошибка при работе с смс-шлюзом;${exception.type}: $exception.comment]
     }
   }


@session[aCode]
## Организует единую сессию для работы с сервисом.
## Нужно только для массовой работы.
   $result[^pfCFile:session{$aCode}]

@formatDate[aDate]
## Форматирует дату в формат, используемый шлюзом
## aDate - [строка|date]
  ^if(!($aDate is date)){
    $aDate[^date::create[^date::create[$aDate]]]
  }
  $result[^aDate.day.format[%02d].^aDate.month.format[%02d].^aDate.year.format[%04d] ^aDate.hour.format[%02d]:^aDate.minute.format[%02d]:^aDate.second.format[%02d]]

@_parseResponse[aResponse][lDoc;lList;lNode;lSubList;lSubNode;lItem;i;k;n;lID]
## $.result[$.result[$.groupID $.<sms_id1> $.<sms_id2> ...] $.errors[$.0 $.1 ...] $.messages[$.id $.smstype $.field1 $.field2 [..]]]
  $result[$.validXML(true) $.result[^hash::create[]] $.errors[^hash::create[]] $.messages[^hash::create[]]]
  ^try{
    $lDoc[^xdoc::create{$aResponse}]
    $lList[$lDoc.documentElement.childNodes]
    ^for[i](0;$lList - 1){
      $lNode[$lList.$i]
      ^switch[$lNode.nodeName]{
        ^case[result]{
          $result.groupID[^lNode.getAttribute[sms_group_id]]
          $lSubList[^lNode.getElementsByTagName[sms]]
          ^for[k](0;$lSubList - 1){
            $result.result.[$k][
              $.text[$lSubList.[$k].firstChild.nodeValue]
              $.id[^lSubList.[$k].getAttribute[id]]
              $.phone[^lSubList.[$k].getAttribute[phone]]
              $.smstype[^lSubList.[$k].getAttribute[smstype]]
            ]
          }
        }
        ^case[errors]{
          $lSubList[^lNode.getElementsByTagName[error]]
          ^for[k](0;$lSubList - 1){
            $lSubNode[$lSubList.[$k]]
            $result.errors.[$k][$lSubNode.firstChild.nodeValue]]
          }
        }
        ^case[MESSAGES]{
##        Для секции MESSAGE запихиваем в хеш все поля,
##        при этом названия тегов переводим в нижний регистр.
          $lSubList[^lNode.getElementsByTagName[MESSAGE]]
          ^for[k](0;$lSubList - 1){
            $lSubNode[$lSubList.[$k]]
            $lID[^lSubNode.getAttribute[SMS_ID]]
            $result.messages.[$lID][
              $.id[$lID]
              $.smstype[^lSubNode.getAttribute[SMSTYPE]]
            ]
            ^for[n](0;$lSubNode.childNodes - 1){
              $lItem[$lSubNode.childNodes.$n]
              ^if($lItem.nodeType == $xdoc:ELEMENT_NODE){
                $result.messages.[$lID].[^lItem.nodeName.lower[]][$lItem.firstChild.nodeValue]
              }
            }
          }
        }
      }
    }

  }{
     ^if($exception.type eq "xml"){
       $result.validXML(false)
       $exception.handled(true)
     }
   }

