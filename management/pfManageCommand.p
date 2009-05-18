# PF Library

#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

@CLASS
pfManageCommand

@USE
pf/modules/pfModule.p
pf/io/pfConsole.p

@BASE
pfModule

#----- Constructor -----

@create[aOptions]
  ^BASE:create[]
  
  $_args[^hash::create[]]
  ^defReadProperty[args]
  
  $_help[]
  ^defReadProperty[help]

@write[aLine]
## Выводит строку на терминал.
  ^pfConsole:write[$aLine]

@writeln[aLine]
## Выводит строку на терминал, завершая ее переводом строки.
  ^pfConsole:writeln[$aLine]
  
@writeTimeLine[aLine][lNow]         
## Выводит строку с отметокой времени
  $lNow[^date::now[]]
  ^writeln[[^lNow.sql-string[]] $aLine]

@onDEFAULT[aRequest]
## Основной метод команды, который необходимо перекрыть в наследнике 
  ^_abstractMethod[]

