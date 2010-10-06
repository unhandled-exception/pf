# PF Library

## Класс для упрощения работы с тегами в SQL-базах.

@CLASS
pfSQLTags

@USE
pf/types/pfClass.p
pf/types/pfString.p

@BASE
pfClass

@create[aOptions]       
## aOptions.sql - ссылка на sql-класс.
## aOptions.tablesPrefix[] - префикс для таблиц в sql-базе.
## aOptions.tagsSeparator[] - регулярное выражение для разделителя тегов
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]
  
  ^pfAssert:isTrue($aOptions.sql is pfSQL)[SQL-класс должен быть наследником pfSQL. ($aOptions.sql.CLASS_NAME)]
  $_CSQL[$aOptions.sql]
  $_tablesPrefix[$aOptions.tablesPrefix]

  $_tagsTable[${_tablesPrefix}tags]
  $_itemsTable[${_tablesPrefix}tags_items]
  $_countersTable[${_tablesPrefix}tags_counters]

  $_defaultFields[t.parent_id as parentID, t.thread_id as threadID, t.title, t.slug, t.sort_order, t.is_visible as isVisible]
  $_extraFields[t.description]

  $_tagsSeparator[^if(def $aOptions.tagsSeparator){$aOptions.tagsSeparator}{[,|/\\]}]
  
  $_transliter[]
                                      
@GET_CSQL[]
  $result[$_CSQL]
  
@GET_transliter[]
  ^if(!def $_transliter){
    ^use[pf/wiki/pfURLTranslit.p] 
    $_transliter[^pfURLTranslit::create[]]
  } 
  $result[$_transliter]

@tags[aOptions][k;v]
## aOptions.tagID[] - выбрать тег с заданным tagID
## aOptions.title[] - выбрать тег с заданным title. 
##                    title может быть строкой или хешем строк, содержащим в ключах title (то, что приходит от splitTags).
## aOptions.slug[] - выбрать тег с заданным slug
## aOptions.threadID[] - выбрать только ветки с заданным threadID
## aOptions.contentType[] 
## aOptions.onlyVisible(false)
## aOptions.withExtraFields(false)
## aOptions.orderBy[order_title|title|order|count]
  ^cleanMethodArgument[]
  $result[^CSQL.table{
      select t.tag_id as tagID, $_defaultFields, sum(case when tc.count is not null then tc.count else 0 end) as cnt
             ^if(^aOptions.withExtraFields.bool(false) && def $_extraFields){, $_extraFields}
        from $_tagsTable as t
             left join $_countersTable as tc using (tag_id)
#             ^if(def $aOptions.contentID){
#               join $_itemsTable as ti on (t.tag_id = ti.tag_id ^if(def $aOptions.contentType){and ti.content_type_id = '^aOptions.contentType.int(0)'})
#             }
       where 1=1
             ^if(def $aOptions.tagID){
               and t.tag_id = '^aOptions.tagID.int(0)'
             }
             ^if(def $aOptions.title){
               ^if($aOptions.title is hash){
                 and t.title in (^aOptions.title.foreach[k;v]{'$k',} -1)
               }{
                 and t.title = '$aOptions.title'
               }
             }
             ^if(def $aOptions.slug){
               and t.slug = '$aOptions.slug'
             }
             ^if(def $aOptions.threadID){
               and (t.tag_id = '^aOptions.threadID.int(0)' or t.thread_id = '^aOptions.threadID.int(0)')
             }
             ^if(^aOptions.onlyVisible.bool(false)){
               and is_visible = 1
             } 
       group by t.tag_id
       order by
         ^switch[$aOptions.order]{
           ^case[DEFAULT;order_title]{t.sort_order asc, t.title asc}
           ^case[title]{t.title asc}
           ^case[order]{t.sort_order asc}
           ^case[count]{count asc}
           ^case[weight]{}
         }
  }]

@tagsFor[aContent;aOptions][ck;cv]
## Возвращает хеш с тегами для контента
## aContent - id|table|hash
## aOptions.contentTableColumn[contentID] - имя колонки в таблице с контентом, содержащее ID
## aOptions.contentType[] 
## aOptions.onlyVisible(false)
## aOptions.withStandartFields(false) - возвращать стандартные поля. По-умолчанию возвращаем только id тега.
## aOptions.withExtraFields(false)
## aOptions.orderBy[title|title_order|order]
  ^cleanMethodArgument[]
  $result[^CSQL.hash{
      select ti.content_id, t.tag_id as tagID
             ^if(^aOptions.withStandartFields.bool(false)){, $_defaultFields} 
             ^if(^aOptions.withExtraFields.bool(false) && def $_extraFields){, $_extraFields}
        from $_tagsTable as t
             join $_itemsTable as ti on (t.tag_id = ti.tag_id and ti.content_type_id = '^aOptions.contentType.int(0)')
       where 1=1
             ^switch[$aContent.CLASS_NAME]{
               ^case[DEFAULT;string;int]{and ti.content_id = '$aContent'}
               ^case[table]{
                 $lContentTableColumn[^if(def $aOptions.contentTableColumn){$aOptions.contentTableColumn}{contentID}]
                 and ti.content_id in (^aContent.menu{'$aContent.[$lContentTableColumn]',} -1)
               }
               ^case[hash]{
                 and ti.content_id in (^aContent.foreach[ck;cv]{'$ck',} -1)
               }
             }
             ^if(^aOptions.onlyVisible.bool(false)){
               and t.is_visible = 1
             } 
       group by ti.content_id
       order by
         ^switch[$aOptions.order]{
           ^case[DEFAULT;order_title]{t.sort_order asc, t.title asc}
           ^case[title]{t.title asc}
           ^case[order]{t.sort_order asc}
         }
  }[$.type[table] $.distinct(true)]]

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
  ^pfAssert:isTrue(def $aJoinName)[Не задано имя колонки с content_id для join.]
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

@normalizeTagTitle[aTagTitle]
  ^if(def $aTagTitle){
    $aTagTitle[^aTagTitle.match[\s{2,}][g][ ]]
    $aTagTitle[^aTagTitle.trim[both]]
  }
  $result[$aTagTitle]

@splitTags[aTags;aOptions][lTags;lTitle]
## Разбивает строку на отдельные теги, нормализует строки и удаляет повторы
## aOptions.separator[] - регулярное выражение для "разделителя" тегов 
## aOptions.columnTitle[tag]         
  ^cleanMethodArgument[]
  $result[^hash::create[]]
  ^if(def $aTags){
    $lTags[^pfString:rsplit[$aTags;^if(def $aOptions.separator){$aOptions.separator}{$_tagsSeparator}]]
    ^if($lTags){
      ^lTags.menu{
        $lTitle[^normalizeTagTitle[$lTags.piece]]
        ^if(def $lTitle){
          $result.[$lTitle][$.title[$lTitle]]
        }
      }
    }
  }
     
@newTags[aTags;aOptions][lTags;tag;v]
## Создает новый таг в системе, если он не существует.
## aTag - string
## aOptions.slug
## aOptions.description
## aOptions.parentID
## aOptions.threadID
## aOptions.sortOrder
## aOptions.isVisible    
## aOptions.separator
## result[tag]
  ^cleanMethodArgument[]   
  ^pfAssert:isTrue(def $aTags)[На задано имя тега.]

  $lTags[^splitTags[$aTags;$.separator[$aOptions.separator]]]
  ^if($lTags){
    ^CSQL.void{
      insert ignore into $_tagsTable (title, slug, description, parent_id, thread_id, sort_order, is_visible)
      values
      ^lTags.foreach[tag;v]{
          ('$tag', '^if(def $aOptions.slug){$aOptions.slug}{^transliter.toURL[$tag]}', '$aOptions.description',
                  '^aOptions.parentID.int(0)', '^aOptions.threadID.int(0)', '^aOptions.sortOrder.int(0)', '^aOptions.isVisible.int(1)')
      }[, ]
    }                  
  }
  $result[^tags[$.title[$lTags]]]

@deleteTag[aTagID]
## Удаляет таг и все, что им протегировано.
  ^pfAssert:isTrue(^aTagID.int(0))[Не задан ID тега.]
  $result[]          
  ^CSQL.transaction{
    ^CSQL.void{delete from $_countersTable where tag_id = '$aTagID'}
    ^CSQL.void{delete from $_itemsTable where tag_id = '$aTagID'}
    ^CSQL.void{delete from $_tagsTable where tag_id = '$aTagID'}
  }
  
@recountTags[aTags;aOptions][lTagsList;lWhere;lCounters]
## Обновляет счетчики содержимого для тегов  
## aTags[] - табличка, которую возвращает метод tags. Если не заданы теги, то считаем для всех тегов.
## aOptions.contentType      
  ^cleanMethodArgument[]
  $result[]    
  ^CSQL.transaction{
#   В MySQL'е можено все сделать сильно проще (за счет поддержки replace-select), 
#   но для джененрик-класса привязка к одной базе не канает. 
    $lTagsList[^if(def $aTags && $aTags){^aTags.menu{'$aTags.tagID'}[, ],} -1]
    $lWhere[1=1
      ^if(def $lTagsList){
        and tag_id in ($lTagsList)
      }
      ^if(def $aOptions.contentType){ and content_type_id = '$aOptions.contentType'}
    ]
    ^CSQL.void{
      delete from $_countersTable 
      where $lWhere
    }
    $lCounters[^CSQL.table{
      select content_type_id as contentType, tag_id as tagID, count(*) as cnt
        from $_itemsTable
       where $lWhere  
       group by content_type_id, tag_id
    }]      
    ^if($lCounters){
      ^CSQL.void{
        insert into $_countersTable (content_type_id, tag_id, `count`) 
        values ^lCounters.menu{('$lCounters.contentType', '$lCounters.tagID', '$lCounters.cnt')}[,]
      }
    }
  } 

@tagging[aContent;aTags;aOptions][lTags;k;v;ck;cv;lContentType;lContentColumnName;lTagsColumnName]
## Тегирует контент (можно протегировать сразу много объектов по куче тегов)  
## aTags - string|table
## aOptions.tagsTableColumn[tagID] - имя колонки в таблице с тагами, содержащее tagID
## aContent - string|int|hash|table. Для хеша id беерем из ключа, для таблицы из колонки.
## aOptions.contentTableColumn[contentID] - имя колонки в таблице с контентом, содержащее ID
## aOptions.mode[new|append] - заново протегировать контент или добавить теги к уже существующим
## aOptions.contentType
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aContent)[Не заданы объекты для тегирования.]
  $result[]

  ^CSQL.transaction{
    $lContentType[^aOptions.contentType.int(0)]
    $lContentColumnName[^if(def $aOptions.contentTableColumn){$aOptions.contentTableColumn}{contentID}]
    $lTagsColumnName[^if(def $aOptions.tagsTableColumn){$aOptions.tagsTableColumn}{tagID}]

    $lTags[^if($aTags is string){^newTags[$aTags]}{$aTags}] 

    ^if(!def $aOptions.mode || $aOptions.mode eq "new"){
      ^CSQL.void{
        delete from $_itemsTable 
        where 
        ^switch[$aContent.CLASS_NAME]{
          ^case[string;int;double]{content_id = '$aContent'}
          ^case[hash]{content_id in (^if($aContent){^aContent.foreach[ck;cv]{'$ck'}[, ],} -1)}
          ^case[table]{content_id in (^if($aContent){^aContent.menu{'$aContent.[$lContentColumnName]'}[, ],} -1)}
          }
        }
        ^if(def $aOptions.contentType){and content_type_id = '$aOptions.contentType'}
      }
    }

    ^if($lTags){
      ^CSQL.void{
        insert ignore into $_itemsTable (content_type_id, tag_id, content_id)
        values 
        ^lTags.menu{
          ^switch[$aContent.CLASS_NAME]{
            ^case[string;int;double]{
              ('$lContentType', '$lTags.[$lTagsColumnName]', '$aContent')
            }
            ^case[hash]{       
              ^aContent.foreach[ck;cv]{
                ('$lContentType', '$lTags.[$lTagsColumnName]', '$ck')
              }[, ]
            }
            ^case[table]{                                 
              ^aContent.menu{
                ('$lContentType', '$lTags.[$lTagsColumnName]', '$aContent.[$lContentColumnName]')
              }[, ]
            }
          }
        }[, ]
      }
    }
  }

# Это плохой способ (пересчитываем все теги), но при перетегировании ничего не сделаешь.
  ^recountTags[;$.contentType[$lContentType]]
#  ^recountTags[$lTags;$.contentType[$lContentType]]
