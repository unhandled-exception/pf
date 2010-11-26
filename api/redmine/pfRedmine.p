# PF Library
#@compat: 3.4.1

## Модуль для работы с системой управления проектами Redmine.
## REST API пока нерабочее, поэтому класс реализует работу с системой через БД.

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
  $_database[^if(def $aOptions.database){$aOptions.database}{redmine}]

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
              ${_validIssueFields.$k} = '$v',
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
      values ^aOptions.custom.foreach[k;v]{('Issue', '$result', '$k', '$v')}[,]
    }
  }
  
  ^if(!def $aOptions.rootID){
    ^CSQL.void{
      update ${_database}.issues
         set root_id = '$result'
       where id = '$result'
    }
  }
  
  