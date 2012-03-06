# PF Library

@CLASS
pfAuthDBRolesStorage

@USE
pf/auth/pfAuthDBStorage.p

@BASE
pfAuthDBStorage

@create[aOptions]
## aOptions.sql - объект для доступа к БД
## aOptions.rolesTable[roles] - имя таблицы с пользователем
## aOptions.rolesToUsersTable[roles_to_users] - имя таблицы сессий  
  ^cleanMethodArgument[]
  ^pfAssert:isTrue($aOptions.sql is pfSQL)[SQL-класс должен быть наследником pfSQL.]

  ^BASE:create[$aOptions]

  $_sql[$aOptions.sql]
  $_rolesTable[^if(def $aOptions.rolesTable){$aOptions.rolesTable}{roles}]  
  $_rolesToUsersTable[^if(def $aOptions.rolesToUsersTable){$aOptions.rolesToUsersTable}{roles_to_users}]  

  $_roleExtraFields[^hash::create[]]         
  

#----- Methods -----

@addRoleExtraField[aField;aDBField]
## Определяет дополнительное поле, которое надо достать из таблицы с ролями
## aField - имя поля, которое будет в хеше с пользователем.
## aDBField - имя поля в БД.
  ^pfAssert:isTrue(def $aField)[Не задано имя дополительного поля.]
  $_roleExtraFields.[$aField][$aDBField]

@allRoles[aOptions][k;v]
## Хеш со всеми ролями.
## aOptions.active[active|inactive|any]
## aOptions.limit
## aOptions.offset   
## aOptions.roleID[]
## aOptions.sort[order|id|name]  
## result[hash[$.roleID[fields $.permissions[hash]]]]
  ^cleanMethodArgument[]
  $result[^CSQL.hash{select role_id,
                            role_id as roleID, 
                            name, 
                            permissions, 
                            description,
                            is_active as isActive,
                            sort_order as sortOrder
                            ^if($_roleExtraFields){
                              , ^_roleExtraFields.foreach[k;v]{^if(def $v){$v}{$k} as $k}[, ]
                            }
                       from $_rolesTable
                      where 1=1
                            ^switch[$aOptions.active]{
                              ^case[DEFAULT;active]{and is_active = "1"}
                              ^case[inactive]{and is_active = "0"}
                              ^case[any]{}
                            }             
                            ^if(def $aOptions.roleID){
                              and role_id = "^aOptions.roleID.int(0)"
                            }
                  order by ^switch[$aOptions.sort]{
                              ^case[DEFAULT;order]{sort_order asc, name asc}
                              ^case[name]{name asc}
                              ^case[id]{id asc}
                           }
  }[
     $.type[hash]
     ^if(^aOptions.contains[limit]){$.limit($aOptions.limit)}
     ^if(^aOptions.contains[offset]){$.offset($aOptions.offset)}
   ]]

# Преобразовываем поле с ролями в хеш  
  ^result.foreach[k;v]{
    $v.permissions[^_parsePermissions[$v.permissions]]
  }

@getRole[aRoleID;aOptions]
## Возвращает роль с aRoleID
  ^cleanMethodArgument[]
  $aRoleID[^aRoleID.int(0)]
  ^if($aRoleID){
    $result[^allRoles[$.roleID[$aRoleID] $.active[$aOptions.active]]]
    ^if(^result.contains[$aRoleID]){
      $result[$result.[$aRoleID]]
    }
  }{
     $result[^hash::create[]] 
   }

@rolesForUsers[aUsers;aOptions][k;v;lColName]
## Возвращает все роли для пользователей.
## aUsers[string|table|hash]
## aOptions.columnName[roleID]
## aOptions.active[active|inactive|any]
## aOptions.sort[order|id|name]
## result[hash of tables]
  ^cleanMethodArgument[]
  $result[^CSQL.hash{
    select ru.user_id as userID, 
           ru.role_id as roleID
      from $_rolesToUsersTable as ru
           join $_rolesTable as r using (role_id)
     where 1=1
           ^switch[$aUsers.CLASS_NAME]{
             ^case[string]{
               and user_id = "^aUsers.int(-1)"
             }
             ^case[table]{
               $lColName[^if(def $aOptions.columnName){$aOptions.columnName}{roleID}]
               and user_id in (^aUsers.menu{"^aUsers.[$lColName].int(-1)", } -1)
             }
             ^case[hash]{
               and user_id in (^aUsers.foreach[k;v]{"^k.int(-1)", } -1)
             }
           }  
           ^switch[$aOptions.active]{
             ^case[DEFAULT;active]{and r.is_active = "1"}
             ^case[inactive]{and r.is_active = "0"}
             ^case[any]{}
           }
  order by ^switch[$aOptions.sort]{
              ^case[DEFAULT;order]{r.sort_order asc, r.name asc}
              ^case[name]{r.name asc}
              ^case[id]{r.id asc}
           }
  }[$.type[table] $.distinct(true)]]

@permissionsForUser[aUserID;aOptions][lRaw]
## Возвращает хеш со всеми провами из всех ролей пользователя.
## aOptions.active[active|inactive|any]
## result[hash[$.permission_name(1)]]
  ^cleanMethodArgument[]
  $lRaw[^CSQL.string{
    select group_concat(r.permissions separator "\n")
      from $_rolesTable as r
           join $_rolesToUsersTable as ru using (role_id)
     where ru.user_id = "^aUserID.int(-1)"
           ^switch[$aOptions.active]{
             ^case[DEFAULT;active]{and r.is_active = "1"}
             ^case[inactive]{and r.is_active = "0"}
             ^case[any]{}
           }
  group by ru.user_id
  }[$.default{}]]  
  $result[^_parsePermissions[$lRaw]]

@assignRoles[aUserID;aRoles;aOptions][lUserID;k;v]
## Прописывает пользователю aUserID роли aRoles.
## Все старые роли удаляются.
## aOptions.columnName[roleID]
  $result[]                                                       
  ^cleanMethodArgument[]
  $lUserID[^aUserID.int(0)]             
  ^if($lUserID){
    ^CSQL.naturalTransaction{
      ^CSQL.void{delete from $_rolesToUsersTable where user_id = "$lUserID"}
      ^if($aRoles){
        ^CSQL.void{
           insert ignore into $_rolesToUsersTable (user_id, role_id)
                values 
                ^switch[$aRoles.CLASS_NAME]{
                  ^case[string]{
                    ("$lUserID", "^aRoles.int(0)")
                  }
                  ^case[table]{
                    $lColName[^if(def $aOptions.columnName){$aOptions.columnName}{roleID}]
                    ^aRoles.menu{("$lUserID", "^aRoles.[$lColName].int(-1)")}[, ]
                  }
                  ^case[hash]{
                    ^aRoles.foreach[k;v]{("$lUserID", "^k.int(-1)")}[, ]
                  }
                }  
        }
      }
    }
  }

@roleAdd[aOptions][k;v]
## Добавляет роль
## aOptions.name
## aOptions.permissions
## aOptions.permissionsColumn
## aOptions.description
## aOptions.isActive   
## aOptions.sortOrder
## aOptions.<> - поля из _extraFields
## result[id роли] 
  $result[]
  ^cleanMethodArgument[]
  ^CSQL.void{
    insert into $_rolesTable (
      ^_roleExtraFields.foreach[k;v]{^if(^aOptions.contains[$k]){`^if(def $v){$v}{$k}`, }} 
      name, description, permissions, is_active, sort_order)
    values (
      ^_roleExtraFields.foreach[k;v]{^if(^aOptions.contains[$k]){"$aOptions.[$k]", }} 
      "^taint[^if(def ^aOptions.name.trim[both]){$aOptions.name}{Новая роль}]", 
      "^taint[$aOptions.description]",
      "^taint[^_permissionsToString[$aOptions.permissions;$.column[$aOptions.permissionsColumn]]]", 
      "^aOptions.isActive.int(1)",
      "^aOptions.sortOrder.int(0)"
    )          
  }
  $result[^CSQL.lastInsertId[]]

@roleModify[aRoleID;aOptions][k;v]
## Изменяет данные роли
## aOptions.name
## aOptions.permissions
## aOptions.permissionsColumn
## aOptions.description
## aOptions.isActive   
## aOptions.sortOrder
## aOptions.<> - поля из _extraFields
  $result[]
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(^aRoleID.int(0) > 0)[Не задан roleID.]
  ^CSQL.void{
    update $_rolesTable
       set ^if(^aOptions.contains[name]){name = "^taint[$aOptions.name]",}
           ^if(^aOptions.contains[permissions]){permissions = "^taint[^_permissionsToString[$aOptions.permissions;$.column[$aOptions.permissionsColumn]]]",}
           ^if(^aOptions.contains[description]){description = "^taint[$aOptions.description]",}
           ^if(^aOptions.contains[isActive]){is_active = "^aOptions.isActive.int(1)",}
           ^if(^aOptions.contains[sortOrder]){sort_order = "^aOptions.sortOrder.int(0)",}
           ^_roleExtraFields.foreach[k;v]{^if(^aOptions.contains[$k]){ `^if(def $v){$v}{$k}` = ^if(def $aOptions.[$k]){"^taint[$aOptions.[$k]]"}{null}, }}
           role_id = role_id
     where role_id = "^aRoleID.int(0)"
  }

@roleDelete[aRoleID]
## Удаляет роль и все привязки к пользователям
  $result[]
  ^if($aRoleID){
    ^CSQL.naturalTransaction{
      ^CSQL.void{delete from $_rolesToUsersTable where role_id = "^aRoleID.int(-1)"}
      ^CSQL.void{delete from $_rolesTable where role_id = "^aRoleID.int(-1)"}
    }
  }

@userModify[aUserID;aOptions]
## aOptions.roles
## aOptions.rolesColumn[roleID]
  $result[]
  ^cleanMethodArgument[]
  ^BASE:userModify[$aUserID;$aOptions]

  ^if(^aOptions.contains[roles]){
    ^assignRoles[$aUserID;$aOptions.roles;$.columnName[$aOptions.rolesColumn]]
  }

@userAdd[aOptions][k;v]
## aOptions.roles
## aOptions.rolesColumn[roleID]
  ^cleanMethodArgument[]
  $result[^BASE:userAdd[$aOptions]]

  ^if($result && ^aOptions.contains[roles]){
    ^assignRoles[$result;$aOptions.roles;$.columnName[$aOptions.rolesColumn]]
  }

#----- Private -----

@_parsePermissions[aRawPermissions][lParsed]
  $result[^hash::create[]]
  $lParsed[^aRawPermissions.match[^^\+(.+)^$][gm]]
  ^lParsed.menu{$result.[$lParsed.1][1]}

@_permissionsToString[aPermissions;aOptions][lColumn;k;v]
## aPermissions[string|table|hash]
## aOptions.column[permission]
  ^switch[$aPermissions.CLASS_NAME]{
    ^case[DEFAULT;string]{$result[$aPermissions]}
    ^case[table]{
      $lColumn[^if(def $aOptions.column){$aOptions.column}{permission}]
      $result[^aPermissions.menu{+$aPermissions.[$lColumn]^#0A}]
    }
    ^case[hash]{
      $result[^aPermissions.foreach[k;v]{+${k}^#0A}]
    }
  }
