# PF Library

#@info     Модуль для работы с хранилищем данных аутентификации
#@author   Oleg Volchkov <oleg@volchkov.net>                                                                                                          
#@web      http://oleg.volchkov.net

@CLASS
pfAuthStorage

@USE
pf/types/pfClass.p

@BASE
pfClass

#----- Constructor -----

@create[aOptions]
  ^cleanMethodArgument[]

#----- Public -----

@getUser[aID]
## Загрузить данные о пользователе по ID (как правило логину)
## Возвращает хэш с параметрами.
  $result[^hash::create[]]
  
@getSession[aOptions]
## Загрузить сессию по UID и SID
  $result[^hash::create[]]

@addSession[aOptions]
## Добавляем сессию в хранилище
  $result(false)
  
@updateSession[aOptions]
## Обновить данные о сессии в хранилище
  $result(false)

@deleteSession[aOptions]
## Удалить сессию из хранилища
  $result(false)

@isValidPassword[aID;aPassword]
## Возвращает true, если пароль для пользователя с aID правильный.
  $result(false)
  
