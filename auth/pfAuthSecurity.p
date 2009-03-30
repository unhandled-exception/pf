# PF Library

#@info     Модуль реализующий контроль доступа
#@author   Oleg Volchkov <oleg@volchkov.net>                                                                                                          
#@web      http://oleg.volchkov.net

@CLASS
pfAuthSecurity

@USE
pf/types/pfClass.p

@BASE
pfClass

#----- Constructor -----

@create[aOptions]
  ^cleanMethodArgument[]

@can[aWho;aWhat]
  $result(false)
  