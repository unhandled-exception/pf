# PF Library

@CLASS
pfAuthDBRolesSecurity

@USE
pf/auth/pfAuthSecurity.p

@BASE
pfAuthSecurity

@create[aOptions]
  ^BASE:create[$aOptions]
  ^pfAssert:isTrue($_storage is pfAuthStorage)[Не задан storage-класс.]
  
  $_loadedUsersPermissions[^hash::create[]]

@can[aUser;aPermission;aOptions]
  ^pfAssert:isTrue(def $aUser.id)[Не задан id пользователя.]
  ^if(!^_loadedUsersPermissions.contains[$aUser.id]){
    ^_appendPermissionsFor[$aUser]
  }        
  $result(^BASE:can[$aUser;$aPermission;$aOptions])


#----- Private -----

@_appendPermissionsFor[aUser][lPermissions;k;v]
  $result[]
  $lPermissions[^_storage.permissionsForUser[$aUser.id]]
  ^if($lPermissions){
    ^lPermissions.foreach[k;v]{
      ^grant[$aUser;$k]
    }
  }                       
  $_loadedUsersPermissions.[$aUser.id][1]

  