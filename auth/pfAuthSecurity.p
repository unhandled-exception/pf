# PF Library

#@info     Модуль реализующий контроль доступа
#@author   Oleg Volchkov <oleg@volchkov.net>                                                                                                          
#@web      http://oleg.volchkov.net

@CLASS
pfAuthSecurity

@USE
pf/types/pfClass.p

@BASE
pfClass

#----- Constructor -----

@create[aOptions]
## aOptions.storage
  ^cleanMethodArgument[]

  $_storage[$aOptions.storage]
  
  $_permissions[^hash::create[]]
  $_groups[
    $.DEFAULT[$.title[] $.permissions[^hash::create[]]]
  ]
  $_grants[^hash::create[]]

  $_pnRegex1[^regex::create[\s*:\s+][]]
  $_pnRegex2[^regex::create[\s+][g]]

#----- Properties -----

@GET_permissions[]
  $result[$_permissions]

@GET_groups[]
  $result[$_groups]


#----- Methods -----

@can[aUser;aPermission;aOptions][lHasPermission]
## aOptions.ignoreNonExists(false) - не выдает ошибку, если права нет в системе
  ^pfAssert:isTrue(def $aUser.id)[Не задан id пользователя.]
  
  $aPermission[^_processName[$aPermission]]
  $lHasPermission(^_permissions.contains[$aPermission])
  ^pfAssert:isTrue(!^aOptions.ignoreNonExists.bool(false) || $lHasPermission)[Неизвестное право "$aPermission".]
#  ^pfAssert:fail[$aPermission ... ^_grants.[$aUser.id].foreach[k;v]{$k}[, ] ... ^_permissions.foreach[k;v]{$k}[, ]]

  $result(^_grants.contains[$aUser.id] && ^_grants.[$aUser.id].contains[$aPermission])

@newPermission[aName;aTitle;aOptions][lPermission]
## Добавляет право в систему
## aPermission[[group:]permission]  
  $result[]
  $aName[^_processName[$aName]]
  ^pfAssert:isTrue(def $aName)[Не задано имя права.]
  ^pfAssert:isFalse(^_permissions.contains[$aName])[Право "$aName" уже создано.]
  
  $lPermission[^_parsePermisson[$aName]]
  $_permissions.[$aName][$.title[^if(def $aTitle){$aTitle}{$aName}]]
  
  ^pfAssert:isTrue(!def $lPermission.group || ^_groups.contains[$lPermission.group])[Неизвестная группа прав "$lPermission.group".]
  $_groups.[^if(def $lPermission.group){$lPermission.group}{DEFAULT}].permissions.[$aName][1]

@newGroup[aName;aTitle;aOptions]
## Добавляет в систему группу
  $result[]
  $aName[^_processName[$aName]]
  ^pfAssert:isTrue(def $aName)[Не задано имя группы прав.]
  ^pfAssert:isFalse(^_groups.contains[$aName])[Группа прав "$aName" уже создана.]
  
  $_groups.[$aName][$.title[^if(def $aTitle){$aTitle}{$aName}] $.permissions[^hash::create[]]]

@grant[aUser;aPermission;aOptions][lHasPermission;lIgnoreNonExists]
## Разрешает пользователю воспользоваться правом aPermission.
## aOptions.ignoreNonExists(false) - не выдает ошибку, если права нет в системе
  $result[]
  $aPermisson[^_processName[$aPermission]]
  $lHasPermission(^_permissions.contains[$aPermission])
  $lIgnoreNonExists(^aOptions.ignoreNonExists.bool(false))
  ^pfAssert:isTrue(def $aUser.id)[Не задан id пользователя.]
  ^pfAssert:isTrue(!$lIgnoreNonExists || $lHasPermission)[Неизвестное право "$aPermission".]
  ^if($lHasPermission){
    ^if(!^_grants.contains[$aUser.id]){
      $_grants.[$aUser.id][^hash::create[]]
    }
    $_grants.[$aUser.id].[$aPermission][1]
  }

#----- Private -----

@_processName[aName]
  $result[^aName.trim[both]]
  $result[^result.lower[]]
  $result[^result.match[$_pnRegex1][][:]]
  $result[^result.match[$_pnRegex2][][_]]
  
@_parsePermisson[aName][lPos]
  $lPos(^aName.pos[:])
  $result[
    ^if($lPos > 0){
      $.group[^aName.mid(0;$lPos)]
      $.permission[^aName.mid($lPos+1)]
    }{
       $.permission[$aName] 
     }
  ]
  