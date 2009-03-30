# PF Library

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
  
  $_args[]
  ^defReadProperty[args]
  
  $_help[]
  ^defReadProperty[help]
  

@onDEFAULT[aRequest]
## Основной метод команды, который необходимо перекрыть в наследнике 
  ^_abstractMethod[]


