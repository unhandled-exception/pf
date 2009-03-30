# PF Library
# Units Test Suite
# Copyright (c) 2006-2007 Oleg Volchkov

#@module   Test Suite Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

@CLASS
pfTestSuite

@USE
pf/tests/pfAssert.p

@create[aSuiteName]
  $_suiteName[$aSuiteName]

  $_casesObjects[^hash::create[]]
  $_casesOrder[^table::create{name}]

  $_stat[
    $.complete(0)
    $.success(0)
    $.fail(0)
    $.pass(0)
    $.error(0)
  ]

#----- Properties -----

@GET_suiteName[]
  $result[$_suiteName]

@GET_testName[]
  $result[$_testName]

@GET_count[]
## Возвращает количество тестов
  $result($_casesOrder)

@GET_stat[]
  $result[$_stat]

#----- Public -----

@addTest[aTestObject;aTestName]
  ^pfAssert:isFalse(^_casesOrder.locate[name;$aTestName])[Тест "$aTestName" уже есть в наборе.]
  ^pfAssert:isTrue($aTestObject is pfTestCase)[Тест должен быть наследником класса pfTestCase.]

  ^if(!def $aTestName){
    $aTestName[$aTestObject.name]
  }

  ^_casesOrder.append{$aTestName}
  ^_casesObjects.add[
    $.[$aTestName][
      $.name[$aTestName]
      $.object[$aTestObject]
      $.result[^hash::create[]]
    ]
  ]

@run[][lTest]
## Выполняет тесты
  ^foreach[lTest]{
    $lTest.result[^lTest.object.run[]]
    ^_updateStat[$lTest]
  }

#----- Iterator's -----

@foreach[aVarName;aCode;aSeparator][result]
## Перебирает все тесты.
## В переменную итератора помещается хэш $.name[] $.result[] $.object[]
  ^pfAssert:isTrue($count)[Нет тестов.]
  ^pfAssert:isTrue(def $aVarName)[Не определено имя переменной для значения.]

  ^_casesOrder.menu{
    $caller.[$aVarName][$_casesObjects.[$_casesOrder.name]]
    $result[${result}$aCode^if(def $aSeparator && ^_casesOrder.line[] < $_casesOrder){$aSeparator}]
  }
  $caller.[$aVarName][]

#----- Private -----

@_updateStat[aTest]
  ^stat.complete.inc[]
  ^switch[$aTest.result.status]{
    ^case[SUCCESS]{^stat.success.inc[]}
    ^case[FAIL]{^stat.fail.inc[]}
    ^case[PASS]{^stat.pass.inc[]}
    ^case[ERROR]{^stat.error.inc[]}
  }
