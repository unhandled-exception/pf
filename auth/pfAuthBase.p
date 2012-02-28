# PF Library

#@info     Базовый модуль для авторизации
#@author   Oleg Volchkov <oleg@volchkov.net>                                                                                                          
#@web      http://oleg.volchkov.net

@CLASS
pfAuthBase

@USE
pf/types/pfClass.p

@BASE
pfClass

#----- Constructor -----

@create[aOptions]
## aOptions.storage - объект-хранилище данных аутентификации
## aOptions.security - объект, реализующий контроль доступа
## aOptions.formPrefix[auth.] - префикс для переменных форм и кук. 
  ^cleanMethodArgument[]

  ^if(def $aOptions.storage && $aOptions.storage is pfAuthStorage){
    $_storage[$aOptions.storage]
  }{
     ^use[pf/auth/pfAuthStorage.p]
     $_storage[^pfAuthStorage::create[]]
   }

  ^if(def $aOptions.security && $aOptions.security is pfAuthSecurity){
    $_security[$aOptions.security]
  }{
     ^use[pf/auth/pfAuthSecurity.p]
     $_security[^pfAuthSecurity::create[]]
   }

  ^if(def $aOptions.formPrefix){$_formPrefix[$aOptions.formPrefix]}{$_formPrefix[auth.]}
  

  $_isUserLogin(false)  
  $_user[^hash::create[]]
#  $_user[
#    $.id[guest]
#    $.password[]
#    $.active(true)
#    $.roles[guest]
#  ] 

#----- Properties -----

@GET_user[]
## Свойство. Возвращает хэш с данными о пользователе.
  $result[$_user]

@GET_isUserLogin[]
## Свойство. Залогинен ли пользователь?
  $result($_isUserLogin)

@GET_security[]
  $result[$_security]
  
@GET_storage[]
  $result[$_storage]

#----- Public -----

@identify[aOptions]
## Пытаемся определить пользователя сами, или зовем логин
  $result(false)
  
@login[aOptions]
## Принудительный логин. Текущие сессии игнорируются
  $result(false)

@logout[aOptions]
## Принудительный логаут пользователя
  $result(true)
  
@checkLoginAndPassword[aLogin;aPassword]
## Проверяет логин и пароль.
  $result(false)

@makeRandomPassword[][passwd_length;vowels;consonants]
  $passwd_length(10)
  $vowels[aeiouy]
  $consonants[bcdfghklmnprstvxz]
  $result[^for[i](1;$passwd_length){^if($i % 2 ){^consonants.mid(^math:random(^consonants.length[] );1)}{^vowels.mid(^math:random(^vowels.length[]);1)}}]

@can[aPermission]
## Интерфейс к AuthSecurity для текущего пользователя
  $result(^security.can[$user;$aPermission])

@grant[aPermission]
## Интерфейс к AuthSecurity для текущего пользователя
  $result[^security.grant[$user;$aPermission]]
