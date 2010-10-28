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
## aOptions.cryptType[crypt|md5|mysql|old_mysql] - тип хеширования пароля (default: crypt)
  ^cleanMethodArgument[]
  ^pfAssert:isTrue($aOptions.sql is pfSQL)[SQL-класс должен быть наследником pfSQL.]

  $_sql[$aOptions.sql]
  ^if(def $aOptions.usersTable){$_usersTable[$aOptions.usersTable]}{$_usersTable[users]}  
  ^if(def $aOptions.sessionsTable){$_sessionsTable[$aOptions.sessionsTable]}{$_sessionsTable[sessions]}  

  $_cryptType[$aOptions.cryptType]
  $_extraFields[^hash::create[]]

#----- Properties -----   

@GET_CSQL[]
  $result[$_sql]


#----- Public -----

@addUserExtraField[aField;aDBField]
## Определяет дополнительное поле, которое надо достать из таблицы с пользователями
## aField - имя поля, которое будет в хеше с пользователем.
## aDBField - имя поля в БД.
  ^pfAssert:isTrue(def $aField)[Не задано имя дополительного поля.]
  $_extraFields.[$aField][$aDBField]

@getUser[aID][k;v]
## Загрузить данные о пользователе по ID (по-умолчанию логину)
  $result[^CSQL.table{select id, login, password
                             ^if($_extraFields){
                               , ^_extraFields.foreach[k;v]{^if(def $v){$v}{$k} as $k}[,]
                             }
                        from $_usersTable
                       where login = '$aID'
                             and is_active = '1'
                   }[][$.isForce(true)]]
  $result[^if($result){$result.fields}{^hash::create[]}]
                   
  
@getSession[aOptions]
## Загрузить сессию 
## aOptions.uid - первый идентификатор сессии (пользовательский)
## aOptions.sid - второй идентификатор сессии (сессионный)
  ^cleanMethodArgument[]                              
  ^if(def $aOptions.uid && def $aOptions.sid){
    $result[^CSQL.table{select uid, sid, login, is_persistent, dt_create, dt_access, dt_close
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
  ^CSQL.void{insert into $_sessionsTable (uid, sid, login, dt_access, dt_create, is_persistent, ip)
             values ('$aSession.uid', '$aSession.sid', '$aSession.login',
                      ^if(def $aSession.dt_access){'$aSession.dt_create'}{^CSQL.now[]},  
                      ^if(def $aSession.dt_login){'$aSession.dt_login'}{^CSQL.now[]},  
                      ^if(def $aSession.is_persistent && $aSession.is_persistent){'1'}{'0'},
                      inet_aton('$env:REMOTE_ADDR')                    
                     )
  }     
  $result(true)
  
@updateSession[aSession;aNewSession]
## Обновить данные о сессии в хранилище
  ^CSQL.void{update $_sessionsTable
                set uid = '$aNewSession.uid',
                    sid = '$aNewSession.sid',
                    ^if(def $aNewSession.is_persistent){is_persistent = '$aNewSession.is_persistent',}
                    dt_access = ^if(def $aNewSession.dt_access){'$aNewSession.dt_access'}{^CSQL.now[]}
              where uid = '$aSession.uid'
                    and sid = '$aSession.sid'
  }     
  $result(true)

@deleteSession[aSession]
## Удалить сессию из хранилища
  ^CSQL.void{update $_sessionsTable
             set is_active = '0',
                 dt_close = ^CSQL.now[]
           where uid = '$aSession.uid'
                 and sid = '$aSession.sid'
  }     
  $result(true)

@isValidPassword[aPassword;aCrypted]
  $result(false)
  ^if(def $aPassword && def $aCrypted){
    ^switch[^_cryptType.lower[]]{
      ^case[mysql]{$result(^CSQL.int{select '$aCrypted' = PASSWORD('$aPassword')})}
      ^case[old_mysql]{$result(^CSQL.int{select '$aCrypted' = OLD_PASSWORD('$aPassword')})}
      ^case[crypt;DEFAULT]{$result(^math:crypt[$aPassword;$aCrypted] eq $aCrypted)}
    }
  }

@passwordHash[aPassword;aOptions][lSalt]
## aOptions.type - перекрывает тип, заданный в классе
## aOptions.salt[$apr1$] - salt для метода crypt    
  ^cleanMethodArgument[]
  ^switch[^if(def $aOptions.type){$aOptions.type}{^_cryptType.lower[]}]{
    ^case[crypt;DEFAULT]{
      $lSalt[^if(def $aOptions.salt){$aOptions.salt}{^$apr1^$}]
      $result[^math:crypt[$aPassword;$lSalt]]
    }
    ^case[md5]{$result[^math:md5[$aPassword]]}
    ^case[mysql]{$result[^CSQL.string{select PASSWORD('$aPassword')}]}
    ^case[mysql_old]{$result[^CSQL.string{select OLD_PASSWORD('$aPassword')}]}
  }

@clearSessionsForLogin[aLogin]
  ^CSQL.void{
     delete from $_sessionsTable
      where login = '$aLogin'
  }
  