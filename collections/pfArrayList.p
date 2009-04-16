# PF Library

#@module   ArrayList Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

## Алиас на pfList. Нужен для совместимости старого кода.

@CLASS
pfArrayList

@USE
pf/collections/pfList.p

@BASE
pfList


@create[aValues;aOptions]
  ^BASE:create[$aValues;$aOptions]
