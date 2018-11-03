# PF Library
#@compat: 3.4.1

## Модуль для работы с системой управления проектами Redmine.
## REST API пока нерабочее, поэтому класс реализует работу с системой через БД.
## Redmine >= 3.2, MySQL only

@CLASS
pfRedmine

@USE
pf/types/pfClass.p
pf/io/pfCFile.p

@BASE
pfClass

@create[aOptions]
## aOptions.sql
## aOptions.database
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aOptions.sql)[Не задан sql-класс для работы с редмайном.]

  $_sql[$aOptions.sql]
  $_database[`^taint[^if(def $aOptions.database){$aOptions.database}{redmine}]`]

  $ISSUE_STATUS_ID_NEW[1]
  $ISSUE_STATUS_ID_RESOLVED[3]
  $ISSUE_STATUS_ID_CLOSED[5]

  $PRIORITY_NORMAL[4]

  $_validIssueFields[
    $.subject[subject]
    $.description[description]
    $.trackerID[tracker_id]
    $.categoryID[category_id]
    $.statusID[status_id]
    $.assignedTo[assigned_to_id]
    $.prority[priority_id]
    $.versionID[fixed_version_id]
    $.lockVersion[lock_version]
    $.startDate[start_date]
    $.dueDate[due_date]
    $.authorID[author_id]
    $.parentID[parent_id]
    $.rootID[root_id]
  ]

@GET_CSQL[]
  $result[$_sql]

@newIssue[aProjectID;aOptions][k;v]
## Создает новый тикет и возвращает идентификатор задачи.
## aOptions.custom[$.id[value]]
  ^cleanMethodArgument[]
  ^CSQL.void{
    insert into ${_database}.issues
      set project_id = '$aProjectID',
          ^aOptions.foreach[k;v]{
            ^if(def $_validIssueFields.$k){
              ${_validIssueFields.$k} = '^taint[$v]',
            }
          }
          ^if(!def $aOptions.startDate){start_date = ^CSQL.today[],}
          ^if(!def $aOptions.authorID){author_id = '1',}
          ^if(!def $aOptions.trackerID){tracker_id = '3',}
          ^if(!def $aOptions.statusID){status_id = '$ISSUE_STATUS_ID_NEW',}
          ^if(!def $aOptions.priority){priority_id = '$PRIORITY_NORMAL',}
          created_on = ^CSQL.now[], updated_on = ^CSQL.now[],
          lft = 1, rgt = 2
  }
  $result[^CSQL.lastInsertId[]]

  ^if($aOptions.custom){
    ^CSQL.void{
      insert into ${_database}.custom_values (customized_type, customized_id, custom_field_id, value)
      values ^aOptions.custom.foreach[k;v]{('Issue', '$result', '^taint[$k]', '^taint[$v]')}[,]
    }
  }

  ^if(!def $aOptions.rootID){
    ^CSQL.void{
      update ${_database}.issues
         set root_id = '$result'
       where id = '$result'
    }
  }

@users[aOptions]
## Возвращает всех пользователей редмайна
## aOptions.login
  ^cleanMethodArgument[]
  $result[^CSQL.table{
    select u.id,
           u.login,
           u.firstname as firstName,
           u.lastname as lastName,
           group_concat(distinct e.address separator ', ') as mail,
           admin as isAdmin,
           language,
           type,
           identity_url as identityURL
      from ${_database}.users as u
           left join ${_database}.email_addresses as e on u.id = e.user_id
     where 1=1
           ^if(^aOptions.contains[login]){
             and login = '$aOptions.login'
           }
  group by u.id
  }]

@findUser[aUserName]
## Возвращает данные пользователя
  $result[^users[$.login[$aUserName]]]

@activateUser[aUserID]
  $result[]
  ^CSQL.void{update ${_database}.users set status = 1 where id = '^aUserID.int(-1)'}

@deactivateUser[aUserID]
  $result[]
  ^CSQL.void{update ${_database}.users set status = 3 where id = '^aUserID.int(-1)'}

@createUser[aOptions]
## aOptions.salt[uuid]
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aOptions.login)[На задан логин.]
  ^pfAssert:isTrue(def $aOptions.password)[На задан пароль.]

  ^CSQL.transaction{
    ^CSQL.void{
      insert into ${_database}.users
         set login = "$aOptions.login",

#            The hashed password is stored in the following form: SHA1(salt + SHA1(password))
             $lSalt[^ifdef[$aOptions.salt]{^math:uuid[]}]
             hashed_password = '^math:sha1[${lSalt}^math:sha1[$aOptions.password]]',
             salt = '$lSalt',

             firstname = '$aOptions.firstname',
             lastname = '$aOptions.lastname',
             type = 'User',
             language = 'ru',
             status = 1,
             created_on = ^CSQL.now[]
    }
    $result[^CSQL.lastInsertId[]]
    ^if(^aOptions.contains[mail]){
      ^_updateUserEmail[$result;$aOptions.mail]
    }
    ^_updateUserPermissions[$result;$aOptions.group]
  }[$.isNatural(true)]

@updateUser[aUserID;aOptions][locals]
## aOptions.salt[uuid]
  $result[]
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def ^aUserID.int(0))[На задан id пользователя.]

  ^CSQL.transaction{
    ^CSQL.void{
      update ${_database}.users
         set ^if(^aOptions.contains[login]){login = '$aOptions.login',}
             ^if(def $aOptions.password){
#              The hashed password is stored in the following form: SHA1(salt + SHA1(password))
               $lSalt[^ifdef[$aOptions.salt]{^math:uuid[]}]
               hashed_password = '^math:sha1[${lSalt}^math:sha1[$aOptions.password]]',
               salt = '$lSalt',
             }
             ^if(^aOptions.contains[firstname]){firstname = '$aOptions.firstname',}
             ^if(^aOptions.contains[lastname]){lastname = '$aOptions.lastname',}
             updated_on = ^CSQL.now[]
       where id = '^aUserID.int(-1)'
    }
    ^if(^aOptions.contains[mail]){
      ^_updateUserEmail[$aUserID;$aOptions.mail]
    }
    ^_updateUserPermissions[$aUserID;$aOptions.group]
  }[$.isNatural(true)]

@_updateUserEmail[aUserID;aEmail]
  ^CSQL.void{delete from ${_database}.email_addresses where user_id = '^aUserID.int(-1)'}
  ^if(def $aEmail){
    ^CSQL.void{
      insert into ${_database}.email_addresses
        (`user_id`, `address`, `is_default`, `notify`, `created_on`, `updated_on`)
      values
        ('$aUserID', '^taint[$aEmail]', 1, 'only_my_events', now(), now())
    }
  }

@_updateUserPermissions[aUserID;aGroup]
  $result[]
  ^if(^aUserID.int(0) && ^aGroup.int(0)){
    ^CSQL.void{insert ignore into ${_database}.groups_users (group_id, user_id) values ('^aGroup.int(0)', '^aUserID.int(0)')}
    ^CSQL.void{insert ignore into ${_database}.members (user_id, project_id, mail_notification, created_on)
                 select ^aUserID.int(0), project_id, mail_notification, ^CSQL.now[]
                   from ${_database}.members
                  where user_id = ^aGroup.int(0)
              }
    ^CSQL.void{insert ignore into ${_database}.member_roles (member_id, role_id, inherited_from)
                 select m1.id, mr.role_id, mr.inherited_from
                 from ${_database}.members as m1
                      join ${_database}.members as m2 on (m1.user_id = ^aUserID.int(0) and m1.project_id = m2.project_id and m2.user_id = ^aGroup.int(0))
                      join ${_database}.member_roles as mr on (mr.member_id = m2.id)
              }
  }


