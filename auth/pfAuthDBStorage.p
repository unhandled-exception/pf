# PF Library

#@info     Модуль для работы с хранилищем данных аутентификации, хранящимся в БД
#@author   Oleg Volchkov <oleg@volchkov.net>                                                                                                          
#@web      http://oleg.volchkov.net

@CLASS
pfAuthDBStorage

@USE
pf/auth/pfAuthStorage.p

@BASE
pfAuthStorage

#----- Constructor -----

@create[aOptions]
## aOptions.sql - объект для доступа к БД
## aOptions.usersTable[sessions] - имя таблицы с пользователем
## aOptions.sessionsTable[sessions] - имя таблицы сессий
  ^cleanMethodArgument[]

  ^if($aOptions.sql is pfSQL){
  	$_sql[$aOptions.sql]
  }{
  	 ^throw[pfAuthDBStorage.create;SQL must be pfSQL.]
   }

  ^if(def $aOptions.usersTable){$_usersTable[$aOptions.usersTable]}{$_usersTable[users]}  
  ^if(def $aOptions.sessionsTable){$_sessionsTable[$aOptions.sessionsTable]}{$_sessionsTable[sessions]}  

  $_extraFields[^table::create{field	dbField}]

#----- Properties -----
@GET_CSQL[]
  $result[$_sql]

#----- Public -----

@addUserExtraField[aField;aDBField]
## Определяет дополнительное поле, которое надо достать из таблицы с пользователями
## aField - имя поля, которое будет в хеше с пользователем.
## aDBField - имя поля в БД.
  ^pfAssert:isTrue(def $aField)[Не задано имя дополительного поля.]
  ^_extraFields.append{$aField	$aDBField}

@getUser[aID]
## Загрузить данные о пользователе по ID (по-умолчанию логину)
  $result[^CSQL.table{select id,
                             login,
                             password
                             ^if($_extraFields){
                               , ^_extraFields.menu{^if(def $_extraFields.dbField){$_extraFields.dbField}{$_extraFields.field} as $_extraFields.field}[,]
                             }
                        from $_usersTable
                       where login = '$aID'
                             and is_active = '1'
                   }[][$.isForce(true)]]
                   
  
@getSession[aOptions]
## Загрузить сессию 
## aOptions.uid - первый идентификатор сессии (пользовательский)
## aOptions.sid - второй идентификатор сессии (сессионный)
  ^cleanMethodArgument[]
  ^if(def $aOptions.uid && def $aOptions.sid){
    $result[^CSQL.table{select uid, sid,
                               login,
                               is_persistent,
    	                         dt_create, 
    	                         dt_access,
    	                         dt_close
     	                    from $_sessionsTable
    	                   where uid = '$aOptions.uid'
    	                         and sid = '$aOptions.sid'
                               and is_active = '1'
    	     }[][$.isForce(true)]]
    $result[^if($result){$result.fields}{^hash::create[]}]
  }{
    $result[^hash::create[]]
  }               
  
@addSession[aSession]
## Добавляем сессию в хранилище
  ^try{
    ^CSQL.void{insert into $_sessionsTable
                      (uid, sid, login, 
    	                dt_access,
    	                dt_create,    	                 
                      is_persistent, 
                      ip)
              values ('$aSession.uid', '$aSession.sid', '$aSession.login',
                      ^if(def $aSession.dt_access){'$aSession.dt_create'}{^CSQL.now[]},  
                      ^if(def $aSession.dt_login){'$aSession.dt_login'}{^CSQL.now[]},  
                      ^if(def $aSession.is_persistent && $aSession.is_persistent){'1'}{'0'},
                      inet_aton('$env:REMOTE_ADDR')                    
                     )
    }     
 	  $result(true)
  }{
   	 $exception.handled(false)
  	 $result(false)
   }
  
@updateSession[aSession;aNewSession]
## Обновить данные о сессии в хранилище
  ^try{
    ^CSQL.void{update $_sessionsTable
                 set uid = '$aNewSession.uid',
     	               sid = '$aNewSession.sid',
     	               ^if(def $aNewSession.is_persistent){is_persistent = '$aNewSession.is_persistent',}
     	               dt_access = ^if(def $aNewSession.dt_access){'$aNewSession.dt_access'}{^CSQL.now[]}
     	         where uid = '$aSession.uid'
     	               and sid = '$aSession.sid'
    }     
 	  $result(true)
  }{
   	 $exception.handled(false)
  	 $result(false)
   }

@deleteSession[aSession]
## Удалить сессию из хранилища
  ^try{
    ^CSQL.void{update $_sessionsTable
    	           set is_active = '0',
    	               dt_close = ^CSQL.now[]
     	         where uid = '$aSession.uid'
     	               and sid = '$aSession.sid'
    }     
 	  $result(true)
  }{
   	 $exception.handled(false)
  	 $result(false)
   }

@isValidPassword[aPassword;aCrypted]
^try{
	^if(def $aPassword && def $aCrypted && ^_sql.int{select '$aCrypted' = PASSWORD('$aPassword')}){
		$result(1)
	}{
		$result(0)
	}
}{
#	$exception.handled(1)
	$result(0)
}

@clearSessionsForLogin[aLogin]
  ^CSQL.void{
     delete from $_sessionsTable
      where upper(login) = upper('$aLogin')
  }
  