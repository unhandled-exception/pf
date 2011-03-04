# PF Library

#@info     Модуль для работы с Апачевской авторизацией 
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

@CLASS
pfAuthApache

@USE
pf/auth/pfAuthBase.p

@BASE
pfAuthBase

#----- Constructor -----

@create[aOptions]
## aOptions.security - объект, реализующий контроль доступа
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]
  $_isUserLogin(false)  
  $_user[^hash::create[]]

#----- Public -----

@identify[aOptions]
## Пытаемся определить пользователя сами, или зовем логин
  $result(false)
  ^if(def $env:REMOTE_USER || def $env:REDIRECT_REMOTE_USER){
    $_user[
      $.id[^if(def $env:REMOTE_USER){$env:REMOTE_USER}{$env:REDIRECT_REMOTE_USER}]
      $.ip[$env:REMOTE_ADDR]
    ]                                             
    $_user.login[$_user.id]
    $result(true)
  }
  $_isUserLogin($result)
  
@login[aOptions]
## Принудительный логин. Текущие сессии игнорируются
  $result(^identify[])

@logout[aOptions]
## Принудительный логаут пользователя
  ^_user{^hash::create[]}
  ^_isUserLogin(false)
  $result(true)
  

