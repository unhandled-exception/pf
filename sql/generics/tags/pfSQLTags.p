# PF Library

## Класс для упрощения работы с тегами в SQL-базах.

@CLASS
pfSQLTags

@USE
pf/types/pfClass.p

@BASE
pfClass

@create[aOptions]       
## aOptions.sql - ссылка на sql-класс.
## aOptions.tablesPrefix[] - префикс для таблиц в sql-базе.
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]
  
  ^pfAssert:isTrue($aOptions.sql is pfSQL)[SQL-класс должен быть наследником pfSQL. ($aOptions.sql.CLASS_NAME)]
  $_CSQL[$aOptions.sql]
  $_tablesPrefix[$aOptions.tablesPrefix]

  $_tagsTable[${_tablesPrefix}tags]
  $_itemsTable[${_tablesPrefix}tags_items]
  $_countersTable[${_tablesPrefix}tags_counters]

  $_defaultFields[t.tag_id as tagID, t.parent_id as parentID, t.thread_id as threadID, t.title, t.slug, t.is_visible as isVisible]
  $_extraFields[t.description]
  
  $_transliter[]
                                      
@GET_CSQL[]
  $result[$_CSQL]
  
@GET_tranlister[]
  ^if(!def $_transliter){
    ^use[pf/wiki/pfURLTranslit.p] 
    $_transliter[^pfURLTranslit::create[]]
  } 
  $result[$_transliter]

@tags[aOptions]             
## aOptions.tagID[] - выбрать только дин тап с tagID
## aOptions.threadID[] - выбрать только ветки с заданным threadID
## aOptions.onlyVisible(false)
## aOptions.withExtraFields(false)
## aOptions.contentID[]
  ^cleanMethodArgument[]
  $result[^CSQL.table{
      select $_defaultFields, tc.count as count
             ^if(^aOptions.withExtraFields.bool(false) && def $_extraFields){, $_extraFields}
        from $_tagsTable as t
             left join $_countersTable as tc using (tag_id)
             ^if(def $aOptions.contentID){
               join $_itemsTable on (t.tag_id = ${_itemsTable}.tag_id and ${_itemsTable}.content_id = '$aOptions.contentID')
             }
       where 1=1
             ^if(def $aOptions.tagID){
               and t.tag_id = '^aOptions.tagID.int(0)'
             }
             ^if(def $aOptions.threadID){
               and (t.tag_id = '^aOptions.threadID.int(0)' or t.thread_id = '^aOptions.threadID.int(0)')
             }
             ^if(^aOptions.onlyVisible.bool(false)){
               and is_visible = 1
             }
  }]

@content[aTagID;aOptions]
## aOptions.contentType[] 
## aOptions.limit
## aOptions.offset
  ^cleanMethodArgument[]
  $result[^CSQL.table{
    select content_id as contentID 
      from $_itemsTable
     where tag_id = '$aTagID'
     ^if(def $aOptions.contentType){
       and content_type_id = '$aOptions.contentType'
     }
  }[
    ^if(def $aOptions.limit){$.limit($aOptions.limit)}
    ^if(def $aOptions.offset){$.offset($aOptions.offset)}
  ]]

@sqlJoinForContent[aTagID;aJoinName;aOptions][lAlias]
## Возвращает sql для секции join, который позволяет получить контент для конкретного тега
## aTagID - id тега
## aJoinName - имя колонки, которое чодержит content_id в запросе
## aOptions.contentType
## aOptions.alias - алиас для таблицы с tags_items
## aOptions.type[left|right|...] - тип джоина (дописывается перед ключевым словом "join")
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aJoinName)[Не задано имя колонки для джоина]
  $lAlias[^if(def $aOptions.alias){$aOptions.alias}{^math:uid64[]}]
  $result[$aOptions.type join $_itemsTable $lAlias on (${lAlias}.tag_id = '$aTagID' ^if(def $aOptions.contentType){and ${lAlias}.content_type_id = '$aOptions.contentType'} and $aJoinName = ${lAlias}.content_id)]

@count[aTagID;aOptions]
## Возвращает количество элементов в теге, если тег не указан, то возвращает общее количество протегированных элементов
## aOptions.contentType[]
  ^cleanMethodArgument[]
  ^if(def $aTagID){
    $result(^CSQL.int{
     select sum(`count`) as count
       from $_countersTable
      where tag_id = '$aTagID'
      ^if(def $aOptions.contentType){
        and content_type_id = '$aOptions.contentType'
      }
    })
  }{
     $result(^CSQL.int{
      select count(distinct content_id) as count
        from $_itemsTable
       where 1=1
       ^if(def $aOptions.contentType){
         and content_type_id = '$aOptions.contentType'
       }
     })
   }

