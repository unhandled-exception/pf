# PF Library

#@info     Авторизация на базе cookies.
#@author   Oleg Volchkov <oleg@volchkov.net>                                                                                                          
#@web      http://oleg.volchkov.net

@CLASS
pfAuthCookie

@USE
pf/auth/pfAuthBase.p

@BASE
pfAuthBase

#----- Constructor -----

@create[aOptions]
## aOptions.storage - объект-хранилище данных аутентификации
## aOptions.security - объект, реализующий контроль доступа
## aOptions.formPrefix[auth.] - префикс для переменных форм и кук. 
## aOptions.timeout(60) - время (в минутах) текущей сессии
## aOptions.persistentSessionLifetime(14) - время (в днях) на которое ставится сессионная кука,
##                                           если нам нужно поставить сессионную куку. 
## aOptions.debugMode(0) - в этом режиме разработчик может войти под любым логином,
##                         использовать крайне осторожно!
## aOptions.secureCookie(false) - куки будут установлены пользователю только при работе через
##                                защищенное соединение.

  ^BASE:create[$aOptions]
  ^cleanMethodArgument[]

  $_debugMode(^aOptions.debugMode.int(0))
  $_secureCookie(^aOptions.secureCookie.bool(false))

  ^if(def $aOptions.formPrefix){$_formPrefix[$aOptions.formPrefix]}{$_formPrefix[auth.]}

  ^if(def $aOptions.timeout){$_timeout[$aOptions.timeout]}{$_timeout(60)}
  ^if(def $aOptions.persistentSessionLifetime){
    $_persistentSessionLifetime[$aOptions.persistentSessionLifetime]
  }{
     $_persistentSessionLifetime(14)
   }
  $_UIDLifetime(365)

  $_now[^date::now[]]  
  
# Данные сессии
  $_session[^hash::create[]]
  

#----- Properties -----

@GET_formPrefix[]
  $result[$_formPrefix]

#----- Public -----

@identify[aOptions;aCanUpdateSession][lSession;lNewSession;lSID;lUser]
## Пытаемся определить пользователя сами, или зовем логин
## Если пользователь хочет залогинится, то зовем ^login[]
## aOptions - данные для авторизации (если не заданы, то берем из form и cookie).
## aCanUpdateSession(true) - можно ли обновить сессию.
  ^cleanMethodArgument[]
  ^if(!$aOptions){$aOptions[$form:fields]}

  ^if(def $aOptions.[${_formPrefix}dologin]){
    $result(^login[$aOptions])
  }{
#   Иначе пытаемся залогинить юзера по сессии
     $lSession[^storage.getSession[ 
                 ^if(def $aOptions.[${_formPrefix}uid] && def $aOptions.[${_formPrefix}sid]){
                     $.uid[$aOptions.[${_formPrefix}uid]]] 
                     $.sid[$aOptions.[${_formPrefix}sid]]] 
                 }{
                     $.uid[$cookie:[${_formPrefix}uid]] 
                     $.sid[$cookie:[${_formPrefix}sid]] 
                  }
              ]]

#    Если найдена сессия то пытаемся получаем данные о пользователе 
     ^if($lSession){
     	 $lUser[^storage.getUser[$lSession.login]]

#      Если с момента последнего доступа прошло больше $_temout минут,
#      то обновляем данные сессии
	 		 ^if(^aCanUpdateSession.bool(true) && ^date::create[$lSession.dt_access] < ^date::create($_now-($_timeout/(24*60)))){

#	 		 ^pfAssert:fail[update session ^aCanUpdateSession.int[] $form:_action]

         $lNewSession[
           $.uid[$lSession.uid]
           $.sid[^_makeUID[]]
           $.dt_access[^_now.sql-string[]]
           $.is_persistent[$lSession.is_persistent]
         ]
         ^if(^storage.updateSession[$lSession;$lNewSession]){
           $lSession[^hash::create[$lNewSession]]
           ^_saveSession[$lSession]
         }
       }
 
       ^if($lUser){
          $_isUserLogin(true)
          $_session[$lSession]
          $_user[$lUser]
          $_user.ip[$env:REMOTE_ADDR]
       }
     }{
#@TODO: Возможно стоит вставить guest'а     	
        $_isUserLogin(false)
        $_user[^hash::create[]]
        $_session[^hash::create[]]
     	}
   }

   $result($_isUserLogin)

@login[aOptions][lUser;lSession]
## Принудительный логин. Текущие сессии игнорируются
  ^cleanMethodArgument[]
  $result(false)

# Пробуем найти пользователя по имени
  $lUser[^storage.getUser[$aOptions.[${_formPrefix}login]]]

  ^if($lUser && ($_debugMode || ^storage.isValidPassword[$aOptions.[${_formPrefix}password];$lUser.password])
     ){
#   Если пароль верен, то логиним

    $lSession[
      $.uid[^_makeUID[]]
      $.sid[^_makeUID[]]
      $.login[$aOptions.[${_formPrefix}login]]
      $.is_persistent[^if(def $aOptions.[${_formPrefix}persistent]){1}{0}]
    ]                                      
    
    ^if(^storage.addSession[$lSession]){
      ^_saveSession[$lSession]            
      $_isUserLogin(true)
      $_session[$lSession]
      $_user[$lUser]
      $_user.ip[$env:REMOTE_ADDR]
      $result(true)
    }
  }{
    $_session[^hash::create[]]
    $_user[^hash::create[]]
    $_isUserLogin(false)
  }

@logout[aOptions]
## Принудительный логаут пользователя
  ^cleanMethodArgument[]
  ^if(^storage.deleteSession[^storage.getSession[ 
                     $.uid[$cookie:[${_formPrefix}uid]] 
                     $.sid[$cookie:[${_formPrefix}sid]] 
           ]]){
     ^_clearSession[]
  }  

  $_session[^hash::create[]]
  $_user[^hash::create[]]
  $_isUserLogin(false)

  $result(true)
  
@checkLoginAndPassword[aLogin;aPassword]
## Проверяет логин и пароль.
  $result(^storage.isValidPassword[$aLogin;$aPassword])

#----- Private -----

@_makeUID[]
  $result[^math:uid64[]^math:uid64[]]

@_saveSession[aSession]
# Сохраняет данные сессии в куках
  ^_saveParam[${_formPrefix}uid;$aSession.uid;$_UIDLifetime]
  ^_saveParam[${_formPrefix}sid;$aSession.sid;^if(^aSession.is_persistent.int(0)){$_persistentSessionLifetime}{0}]
  
@_saveParam[aName;aValue;aExpires]
## Метод, через который пишем пользователю куки. если нужно писать это куда-то еще, перекрываем.
^if(def $aName){
	$cookie:[$aName][
		$.value[$aValue]
		^if($aExpires){
			$.expires($aExpires)
		}{
			$.expires[session]
		}
		$.secure($_secureCookie)
	]
}
  
@_clearSession[]
  ^_deleteParam[${_formPrefix}uid]
  ^_deleteParam[${_formPrefix}sid]

@_deleteParam[aName]
  ^if(def $aName){
    $cookie:[$aName][$.value[] $.expires[session]]
  }
