# PF Library
# Copyright (c) 2007 Oleg Volchkov

#@module   Validate Class
#@version  1.0
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

## Класс для проверки данных на различные условия.

@CLASS
pfValidate

@isEmpty[aString]
## Строка пустая или содержит только пробельные символы.
  $result(!def $aString || ^aString.match[^^\s+^$])

@isNotEmpty[aString]
## Строка не пустая.
  $result(!^isEmpty[$aString])

@isAlphaNumeric[aString]
## Строка содержит только буквы, цифры и знак подчеркивания. 
  $result(def $aString && ^aString.match[^^[\p{L}\p{Nd}_]+^$])

@isSlug[aString]
## Строка содержит только буквы, цифры, знак подчеркивания и дефис.
  $result(def $aString && ^aString.match[^^[\p{L}\p{Nd}_-]+^$])

@isLowerCase[aString]
## Строка содержит буквы только нижнего регистра.
  $result(def $aString && ^aString.lower[] eq $aString) 

@isUpperCase[aString]
## Строка содержит буквы только верхнего регистра.
  $result(def $aString && ^aString.upper[] eq $aString) 

@isOnlyLetters[aString]
## Строка содержит только буквы.
## Проверяются только буквы.
  $result(def $aString && ^aString.match[^^\p{L}+^$][i])

@isOnlyDigits[aString]
## Строка содержжит только цифры.
  $result(def $aString && ^aString.match[^^\p{Nd}+^$])

@isHEXDecimal[aString]
## Строка содержит шестнадцатиричное число (парами!).
## Пары символов [0-9A-F] (без учета регистра).
  $result(def $aString && ^aString.match[^^(?:[0-9A-F]{2})+^$][i])

@isValidDecimal[aString;aMaxDigits;aDecimalPlaces]
## Число содежит вещественное число.
## aMaxDigits(12) - максимальное количество цифр в числе
## aDecimalPlaces(2) - Максимальное количество символов после точки
  $result(def $aString && ^aString.match[^^[+\-]?\d{1,^eval(^aMaxDigits.int(12)-^aDecimalPlaces.int(2))}(?:\.\d{^aDecimalPlaces.int(2)})?^$])

@isValidIPV4Address[aString]
## Строка содержит корректный ip-адрес
  $result(def $aString && ^aString.match[^^(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}^$])

@isValidEmail[aString]
## Строка содержит корректный e-mail.
  $result(def $aString 
     && ^aString.match[
      (?:^^[-!\#^$%&'*+/=?^^_`{}|~0-9A-Z]+(?:\.[-!\#^$%&'*+/=?^^_`{}|~0-9A-Z]+)*  # dot-atom
       |^^"(?:[\001-\010\013\014\016-\037!\#-\[\]-\177]|\\[\001-011\013\014\016-\177])*" # quoted-string
      )@(?:[A-Z0-9-]+\.)+[A-Z]{2,6}^$
         ][xi])
  )

@isValidURL[aString;aOnlyHTTP]
## Строка содержит синтаксически-правильный URL.
## aOnlyHTTP - строка может содержать только URL с протоколом http
  $result(def $aString && ^aString.match[^^(?:[A-Z\-0-9]+?\:(?://)?)(?:\S+?(?:\:\S+)?@)?[A-Z0-9\-\.]+\.[A-Z]{2,5}(?:\:\d+)?(?:(?:/|\?)\S*)?^$][i])
  ^if($result && (($aOnlyHTTP is bool && $aOnlyHTTP) || ^aOnlyHTTP.int(0))){
    $result(^aString.match[^^http://])
  }

@isExistingURL[aString][lFile]
## Строка содержит работающий http-url.
  $result(false)
  ^if(^isValidURL[$aString](true)){
    ^try{
      $lFile[^file::load[text;^untaint[as-is]{$aString}][
        $.method[HEAD]
        $.any-status(true)
        $.charset[utf-8]
        $.headers[
           $.Accept-Charset[utf-8]
           $.Connection[close]
        ]
      ]]
      $result($lFile.status eq "200" || $lFile.status eq "401" || $lFile.status eq "301" || $lFile.status eq "302")
    }{
        $exception.handled(true)
     }
  }

@isWellFormedXML[aString][lDoc]
## Строка содержит валидный XML.
  $result(false)
  ^if(def $aString){
    ^try{
      $lDoc[^xdoc::create{$aString}]
      $result(true)
    }{
       $exception.handled(true)
     }
  }

@isWellFormedXMLFragment[aString]
## Строка содержит валидный кусок XML'я.
  $result(def $aString && ^isWellFormedXML[<?xml version="1.0" encoding="$request:charset" ?>
    <root>$aString</root>
  ])

@isValidANSIDatetime[aString][lDate]
## Строка содержит дату в ANSI-формате, допустимую в Парсере.
  $result(false)
  ^if(def $aString){
    ^try{
      $lDate[^date::create[$aString]]
      $result(true)
    }{
       $exception.handled(true)
     }
  }
