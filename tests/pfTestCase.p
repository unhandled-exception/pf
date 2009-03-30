# PF Library
# Units Test Suite
# Copyright (c) 2006-2007 Oleg Volchkov

#@module   Test Case Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

@CLASS
pfTestCase

@USE
pf/tests/pfAssert.p

#----- Constructor -----

@create[aTestName]
  ^pfAssert:isTrue(def $aTestName)[Не задано имя теста.]
  ^pfAssert:isTrue($$aTestName is junction)[Не найден тест "$aTestName".]

  $_testName[$aTestName]
  $_result[^hash::create[]]

#----- Properties -----
@GET_result[]
# Возвращает хэш с информацией о выполненном тесте
  $result[$_result]

@GET_testName[]
  $result[$_testName]

#----- Public -----
@setUp[]
# Вызывается перед тестом

@tearDown[]
# Вызывается после теста

@run[][lTestCall]
  ^try{
    ^setUp[]

    $lTestCall[$$testName]
    ^lTestCall[]

    ^tearDown[]

    $result[
      $.status[SUCCESS]
      $.exception[^hash::create[]]
    ]
  }{
     $exception.handled(true)

     ^switch[$exception.type]{
       ^case[assert.fail]{
          $result[$.status[FAIL] $.exception[$exception]]
       }
       ^case[assert.pass]{
          $result[$.status[PASS]]
       }
       ^case[DEFAULT]{
          $result[$.status[ERROR] $.exception[$exception]]
       }
     }
   }

  