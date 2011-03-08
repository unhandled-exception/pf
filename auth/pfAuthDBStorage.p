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
## aOptions.cryptType[crypt|md5|sha1|mysql|old_mysql] - тип хеширования пароля (default: crypt)
## aOptions.salt
  ^cleanMethodArgument[]
  ^pfAssert:isTrue($aOptions.sql is pfSQL)[SQL-класс должен быть наследником pfSQL.]

  $_sql[$aOptions.sql]
  ^if(def $aOptions.usersTable){$_usersTable[$aOptions.usersTable]}{$_usersTable[users]}  
  ^if(def $aOptions.sessionsTable){$_sessionsTable[$aOptions.sessionsTable]}{$_sessionsTable[sessions]}  

  $_cryptType[$aOptions.cryptType] 
  $_salt[^if(def $aOptions.salt){$aOptions.salt}{^$apr1^$}]
  
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

@getUser[aID;aOptions][k;v]
## Загрузить данные о пользователе по ID (по-умолчанию логину)
## aOptions.active[active|inactive|any]
  ^cleanMethodArgument[]
  $result[^CSQL.table{select id, login, password
                             ^if($_extraFields){
                               , ^_extraFields.foreach[k;v]{^if(def $v){$v}{$k} as $k}[,]
                             }
                        from $_usersTable
                       where login = "$aID"
                             ^switch[$aOptions.active]{
                               ^case[DEFAULT;active]{and is_active = "1"}
                               ^case[inactive]{and is_active = "0"}
                               ^case[any]{}
                             }
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
                         where uid = "$aOptions.uid"
                               and sid = "$aOptions.sid"
                               and is_active = "1"
    }[][$.isForce(true)]]
    $result[^if($result){$result.fields}{^hash::create[]}]
  }{
    $result[^hash::create[]]
  }               
  
@addSession[aSession]
## Добавляем сессию в хранилище
  ^CSQL.void{insert into $_sessionsTable (uid, sid, login, dt_access, dt_create, is_persistent, ip)
             values ("$aSession.uid", "$aSession.sid", "$aSession.login",
                      ^if(def $aSession.dt_access){"$aSession.dt_create"}{^CSQL.now[]},  
                      ^if(def $aSession.dt_login){"$aSession.dt_login"}{^CSQL.now[]},  
                      ^if(def $aSession.is_persistent && $aSession.is_persistent){"1"}{"0"},
                      inet_aton("$env:REMOTE_ADDR")                    
                     )
  }     
  $result(true)
  
@updateSession[aSession;aNewSession]
## Обновить данные о сессии в хранилище
  ^CSQL.void{update $_sessionsTable
                set uid = "$aNewSession.uid",
                    sid = "$aNewSession.sid",
                    ^if(def $aNewSession.is_persistent){is_persistent = "$aNewSession.is_persistent",}
                    dt_access = ^if(def $aNewSession.dt_access){"$aNewSession.dt_access"}{^CSQL.now[]}
              where uid = "$aSession.uid"
                    and sid = "$aSession.sid"
  }     
  $result(true)

@deleteSession[aSession]
## Удалить сессию из хранилища
  ^CSQL.void{update $_sessionsTable
             set is_active = "0",
                 dt_close = ^CSQL.now[]
           where uid = "$aSession.uid"
                 and sid = "$aSession.sid"
  }     
  $result(true)

@isValidPassword[aPassword;aCrypted]
  $result(false)
  ^if(def $aPassword && def $aCrypted){
    ^switch[^_cryptType.lower[]]{
      ^case[crypt;DEFAULT]{$result(^math:crypt[$aPassword;$aCrypted] eq $aCrypted)}
      ^case[md5]{$result(^math:md5[$aPassword] eq $aCrypted)}
      ^case[sha1]]{$result(^math:sha1[$aPassword] eq $aCrypted)}
      ^case[mysql]{$result(^CSQL.int{select "$aCrypted" = PASSWORD("$aPassword")})}
      ^case[old_mysql]{$result(^CSQL.int{select "$aCrypted" = OLD_PASSWORD("$aPassword")})}
    }
  }

@passwordHash[aPassword;aOptions]
## aOptions.type - перекрывает тип, заданный в классе
## aOptions.salt[$apr1$] - salt для метода crypt    
  ^cleanMethodArgument[]
  ^switch[^if(def $aOptions.type){$aOptions.type}{^_cryptType.lower[]}]{
    ^case[crypt;DEFAULT]{
      $result[^math:crypt[$aPassword;^if(def $aOptions.salt){$aOptions.salt}{$_salt}]]
    }
    ^case[md5]{$result[^math:md5[$aPassword]]}
    ^case[sha1]{$result[^math:sha1[$aPassword]]}
    ^case[mysql]{$result[^CSQL.string{select PASSWORD("$aPassword")}]}
    ^case[mysql_old]{$result[^CSQL.string{select OLD_PASSWORD("$aPassword")}]}
  }

@clearSessionsForLogin[aLogin]
  $result[]
  ^CSQL.void{
     delete from $_sessionsTable
      where login = "$aLogin"
  }
   
@userAdd[aOptions][k;v]
## Добавляет пользователя
## aOptions.login
## aOptions.password
## aOptions.isActive
## aOptions.<> - поля из _extraFields
## result[id пользователя] 
  $result[]
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aOptions.login)[Не задан login.]
  ^CSQL.void{
    insert into $_usersTable (^_extraFields.foreach[k;v]{^if(^aOptions.contains[$k]){`^if(def $v){$v}{$k}`, }} login, password, is_active)
    values (^_extraFields.foreach[k;v]{^if(^aOptions.contains[$k]){"$aOptions.[$k]", }} "$aOptions.login", "^passwordHash[$aOptions.password]", "^aOptions.isActive.int(1)")
  }
  $result[^CSQL.lastInsertId[]]

@userModify[aUserID;aOptions]
## Изменяет данные пользователя
## aOptions.login
## aOptions.password
## aOptions.isActive
## aOptions.<> - поля из _extraFields
  $result[]
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(^aUserID.int(0) > 0)[Не задан userID.]
  ^CSQL.void{
    update $_usersTable
       set ^if(^aOptions.contains[login]){login = "",}
           ^if(^aOptions.contains[password]){password = "^passwordHash[$aOptions.password]",}
           ^if(^aOptions.contains[isActive]){is_active = "^aOptions.isActive.int(1)",}
           ^_extraFields.foreach[k;v]{^if(^aOptions.contains[$k]){ `^if(def $v){$v}{$k}` = "$aOptions.[$k]",}}
           id = id
     where id = "^aUserID.int(0)"
  }

@userDelete[aUserID;aOptions]
## Удаляет пользователя                          
## По-умолчанию делает пользователя неактивным
## aOptions.force(false) - удаляет запись и сессии
## aOptions.cleanSessions(false) - удалить сессии
  $result[]                                      
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(^aUserID.int(0) > 0)[Не задан userID.]

  ^if(^aOptions.force.bool(false)){
    ^CSQL.void{delete from $_usersTable where id = "^aUserID.int(0)"}
  }{
     ^CSQL.void{update $_usersTable set is_active = "0" where id = "^aUserID.int(0)"}
   }

  ^if(^aOptions.cleanSessions.bool(false) || ^aOptions.force.bool(false)){
    ^CSQL.void{delete from s 
                     using $_sessionsTable as s 
                           join $_usersTable as u 
                     where s.login = u.login 
                           and u.id = "^aUserID.int(0)"
              }
  }

@allUsers[aOptions][k;v]
## Таблица со всеми пользователями
## aOptions.active[active|inactive|any]
## aOptions.limit
## aOptions.offset   
## aOptions.sort[id|login]
  ^cleanMethodArgument[]
  $result[^CSQL.table{select id, login, password, is_active as isActive
                             ^if($_extraFields){
                               , ^_extraFields.foreach[k;v]{^if(def $v){$v}{$k} as $k}[,]
                             }
                        from $_usersTable
                       where 1=1
                             ^switch[$aOptions.active]{
                               ^case[DEFAULT;active]{and is_active = "1"}
                               ^case[inactive]{and is_active = "0"}
                               ^case[any]{}
                             }
                   order by ^switch[$aOptions.sort]{
                               ^case[DEFAULT;id]{id asc}
                               ^case[login]{login asc}
                            }
  }[
     ^if(^aOptions.contains[limit]){$.limit($aOptions.limit)}
     ^if(^aOptions.contains[offset]){$.offset($aOptions.offset)}
   ][$.isForce(true)]]

