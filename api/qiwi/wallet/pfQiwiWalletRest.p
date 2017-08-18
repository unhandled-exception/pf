# PF Library

## Работа с rest-интерфейсом Киви.Кошелька.

@CLASS
pfQiwiWalletRest

@USE
pf/types/pfClass.p
pf/io/pfCFile.p
pf/tests/pfAssert.p

@BASE
pfClass

@create[aOptions]
## aOptions.shopID
## aOptions.apiID
## aOptions.password
## aOptions.timeout(10)
## aOptions.lifetime(45*24) - Время жизни счёта по умолчанию. Задается в часах.
## aOptions.paySource
## aOptions.prvName
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]
  ^pfAssert:isTrue(def $aOptions.shopID)[Не задан shopID (ID проекта) магазина.]
  ^pfAssert:isTrue(def $aOptions.apiID)[Не задат API ID магазина.]
  ^pfAssert:isTrue(def $aOptions.password)[Не задат пароль для магазина.]

  $_shopID[$aOptions.shopID]
  $_apiID[$aOptions.apiID]
  $_password[$aOptions.password]
  $_urlPrefix[https://api.qiwi.com/api/v2/prv]
  $_timeout(^aOptions.timeout.int(10))

  $_options[
    $.lifetime(^aOptions.lifetime.double(45*24))
    $.paySource[$aOptions.paySource]
    $.prvName[$aOptions.prvName]
  ]

  $statuses[
    $.waiting[Счет выставлен, ожидает оплаты]
    $.paid[Счет оплачен]
    $.rejected[Счет отклонен]
    $.unpaid[Ошибка при проведении оплаты. Счет не оплачен]
    $.expired[Время жизни счета истекло. Счет не оплачен]
  ]

  $successStatuses[
    $.paid(true)
    $._default(false)
  ]

  $cancelStatuses[
    $.expired(true)
    $.rejected(true)
    $._default(false)
  ]

  $failStatuses[
    $.unpaid(true)
    $._default(false)
  ]

  $errors[
    $._default[Неизвестная ошибка.]
    $.[0][OK]
    $.[5][Неверные данные в параметрах запроса]
    $.[13][Сервер занят, повторите запрос позже]
    $.[78][Недопустимая операция]
    $.[150][Ошибка авторизации]
    $.[152][Не подключен или отключен протокол]
    $.[155][Данный идентификатор провайдера (API ID) заблокирован]
    $.[210][Счет не найден]
    $.[215][Счет с таким bill_id уже существует]
    $.[241][Сумма слишком мала]
    $.[242][Сумма слишком велика]
    $.[298][Кошелек с таким номером не зарегистрирован]
    $.[300][Техническая ошибка]
    $.[303][Неверный номер телефона]
    $.[316][Попытка авторизации заблокированным провайдером]
    $.[319][Нет прав на данную операцию]
    $.[339][Ваш IP-адрес или массив адресов заблокирован]
    $.[341][Обязательный параметр указан неверно или отсутствует в запросе]
    $.[700][Превышен месячный лимит на операции]
    $.[774][Кошелек временно заблокирован]
    $.[1001][Запрещенная валюта для провайдера]
    $.[1003][Не удалось получить курс конвертации для данной пары валют]
    $.[1019][Не удалось определить сотового оператора для мобильной коммерции]
    $.[1419][Нельзя изменить данные счета – он уже оплачивается или оплачен]
  ]

#----- Public -----

@_formatQiwiDate[aDate][locals]
  $d[^date::create[$aDate]]
  $result[^d.year.format[%04d]-^d.month.format[%02d]-^d.day.format[%02d]T^d.hour.format[%02d]:^d.minute.format[%02d]:^d.month.second.format[%02d]]

@createBill[aBill;aOptions][locals] -> [$.result_code $.bill[hash]]
## Создание счёта.
## aBill.phone - номер телефона того, кому выставляется счёт. 10 цифр, без +7 или 8 вначале.
## aBill.amount - сумма выставляемого счёта.
## aBill.comment - комментарий.
## aBill.txnID - номер счёта ("уникальный" номер, например, номер заказа в интернет-магазине).
## aOptions - если не указывать, будут использоваться соответствующие параметры из конструктора.
  ^cleanMethodArgument[aBill]
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aBill.phone)[Не задан номер телефона.]
  ^pfAssert:isTrue(def $aBill.txnID)[Не задан номер транзакции (счета).]
  ^pfAssert:isTrue($aBill.amount > 0)[Сумма счета должна быть положительной.]

  $result[]
  $lOptions[^hash::create[$_options]]
  ^lOptions.add[$aOptions]

  $lResponse[^pfCFile:load[text;$_urlPrefix/^taint[uri][${_shopID}]/bills/^taint[uri][${aBill.txnID}];
    $.method[PUT]
    $.charset[utf-8]
    $.content-type[application/x-www-form-urlencoded]
    $.user[$_apiID]
    $.password[$_password]
    $.headers[
      $.Accept[text/json]
    ]
    $.timeout($_timeout)
    $.any-status(true)
    $.form[
      $.user[tel:+7$aBill.phone]
      $.amount[$aBill.amount]
      $.ccy[RUB]
      $.comment[$aBill.comment]
      $.lifetime[^_formatQiwiDate[^date::create(^date::now[] + ($lOptions.lifetime/24))]]
    ]
  ]]

  ^if($lResponse.status ne "200"){
    ^throw[pfQiwiWallet.fail;HTTP error $lResponse.status;$lResponse.text]
  }
  $result[^json:parse[^taint[as-is][$lResponse.text]]]

@cancelBill[aTxnID;aOptions][lResponse;lDoc;lOptions]
## Отмена счета.
## aTxnID - номер счета
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aTxnID)[Не задан номер транзакции (счета).]
  $result[]
  $lOptions[^hash::create[$_options]]
  ^lOptions.add[$aOptions]

  $lResponse[^pfCFile:load[text;$_urlPrefix/^taint[uri][${_shopID}]/bills/^taint[uri][${aTxnID}];
    $.method[PATCH]
    $.charset[utf-8]
    $.content-type[application/x-www-form-urlencoded]
    $.user[$_apiID]
    $.password[$_password]
    $.headers[
      $.Accept[text/json]
    ]
    $.form[
      $.status[rejected]
    ]
    $.timeout($_timeout)
    $.any-status(true)
  ]]

  $result[^unsafe{^json:parse[^taint[as-is][$lResponse.text]]}]

  ^if(!def $result
      || $result.response.result_code ne 0
      || $result.response.result_code ne 210
      || ($result.response.result.code eq 0 && $result.response.bill.status ne "rejected")
  ){
    ^throw[pfQiwiWallet.fail;HTTP error $lResponse.status;$lResponse.text]
  }

@billStatus[aTxnID;aOptions][lOptions;lResponse;lDoc;k;v;i;lNodes;lID]
## Проверка статуса счетов.
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aTxnID)[Не задан номер транзакций (счета).]

  $result[^hash::create[]]
  $lOptions[^hash::create[$_options]]
  ^lOptions.add[$aOptions]

  $lResponse[^pfCFile:load[text;$_urlPrefix/^taint[uri][${_shopID}]/bills/^taint[uri][${aTxnID}];
    $.method[GET]
    $.user[$_apiID]
    $.password[$_password]
    $.headers[
      $.Accept[text/json]
    ]
    $.timeout($_timeout)
    $.any-status(true)
  ]]

  $result[^unsafe{^json:parse[^taint[as-is][$lResponse.text]]}]
  ^if(def $result && $result.response.result_code eq "210"){
    ^throw[pfQiwiWallet.bill.not.found;$result.response.description;$lResponse.text]
  }
  ^if($lResponse.status ne "200"){
    ^throw[pfQiwiWallet.fail;HTTP error $lResponse.status;$lResponse.text]
  }

