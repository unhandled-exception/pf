# PF Library
# Units Test Suite
# Copyright (c) 2006-2007 Oleg Volchkov

#@module   Text Test Runner Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

## Консольный класс-декоратор для тест сайта

@CLASS
pfTestsTextRunner

@USE
pf/tests/pfAssert.p
pf/io/pfConsole.p

#----- Static constructor -----

@auto[]
  $_statusColors[
    $.SUCCESS[$.f[green]]
    $.FAIL[$.f[red]]
    $.PASS[$.f[cyan]]
    $.ERROR[$.f[red]]
    $._default[gray]
  ]

 $_suiteNameColors[$.f[yellow]]

#----- Public -----

@run[aTestSuite][lTest;lCount]
  ^pfAssert:isTrue($aTestSuite is pfTestSuite)[Класс с тестами должен быть наследником pfTestSuite]

  ^pfConsole:setColor[$_suiteNameColors.f;$_suiteNameColors.b]
  ^pfConsole:writeln[$aTestSuite.suiteName]
  ^pfConsole:resetColor[]

  $lCount(0)
  ^aTestSuite.run[]
  ^aTestSuite.foreach[lTest]{
    ^lCount.inc[]
    ^pfConsole:write[^lCount.format[ %03d]: $lTest.name ^[]
     
    ^pfConsole:setColor[$_statusColors.[$lTest.result.status].f;$_statusColors.[$lTest.result.status].b]
    ^pfConsole:write[$lTest.result.status]
    ^pfConsole:resetColor[]
    ^pfConsole:writeln[^]]

    ^if($lTest.result.exception){
      ^_printException[$lTest.result.exception]
    }
  }  

  ^_printStat[$aTestSuite.stat]

#----- Private -----

@_printException[aException]
    ^pfConsole:writeln[  Проблема: $aException.comment]
    ^pfConsole:writeln[  Источник: $aException.source]
    ^pfConsole:writeln[       Тип: $aException.type]
    ^if(!^aException.type.match[^^assert\.] && def $aException.file){
      ^pfConsole:writeln[       Где: $aException.file (${aException.lineno}:$aException.colno)]
    }

@_printStat[aStat]
  ^pfConsole:writeln[Выполено тестов: $aStat.complete (s: $aStat.success, f: $aStat.fail, p: $aStat.pass, e: $aStat.error).]
