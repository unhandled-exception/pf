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
## aOptions.tagsSeparator[] - регулярное выражение для разделителя тегов
## aOptions.contentType(0) - стандартный content_type_id
## aOptions.tagsTable[tags] - имя таблицы с тегами
## aOptions.itemsTable[{tagsTable}_items] - имя таблицы с тегированным контентом
## aOptions.countersTable[{tagsTable}_counters] - имя таблицы со счетчиками
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]
  
  ^pfAssert:isTrue($aOptions.sql is pfSQL)[SQL-класс должен быть наследником pfSQL. ($aOptions.sql.CLASS_NAME)]
  $_CSQL[$aOptions.sql]
  $_tablesPrefix[$aOptions.tablesPrefix]

  $_tagsTable[^if(def $aOptions.tagsTable){$aOptions.tagsTable}{tags}]
  $_itemsTable[^if(def $aOptions.itemsTable){$aOptions.itemsTable}{${_tagsTable}_items}]
  $_countersTable[^if(def $aOptions.countersTable){$aOptions.countersTable}{${_tagsTable}_counters}]
  ^defReadProperty[tagsTable]
  ^defReadProperty[itemsTable]
  ^defReadProperty[countersTable]

  $_defaultFields[t.parent_id as parentID, t.thread_id as threadID, t.title, t.slug, t.sort_order, t.is_visible as isVisible]
  $_extraFields[t.description]
  ^defReadProperty[defaultFields]
  ^defReadProperty[extraFields]

  $_defaultContentType(^aOptions.contentType.int(0))
  $_tagsSeparator[^if(def $aOptions.tagsSeparator){$aOptions.tagsSeparator}{[,|/\\]}]
  
  $_transliter[]
  
  $_tagsFields[
    $.title[title]
    $.slug[slug]
    $.description[description]
    $.threadID[thread_id]
    $.parentID[parent_id]
    $.sortOrder[sortOrder]
    $.isVisible[is_visible]
  ]
  
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
## aOptions.onlyVisible(false)
## aOptions.withExtraFields(false)
## aOptions.order[order_title|title|order|count]
  ^cleanMethodArgument[]
  $result[^CSQL.table{
      select t.tag_id as tagID, $_defaultFields, sum(case when tc.count is not null then tc.count else 0 end) as cnt
             ^if(^aOptions.withExtraFields.bool(false) && def $_extraFields){, $_extraFields}
        from $_tagsTable as t
             left join $_countersTable as tc using (tag_id)
       where 1=1
             ^if(def $aOptions.tagID){
               and t.tag_id = "^aOptions.tagID.int(0)"
             }
             ^if(def $aOptions.title){
               ^if($aOptions.title is hash){
                 and t.title in (^aOptions.title.foreach[k;v]{"$k",} -1)
               }{
                 and t.title = "$aOptions.title"
               }
             }
             ^if(def $aOptions.slug){
               and t.slug = "$aOptions.slug"
             }
             ^if(def $aOptions.threadID){
               and (t.tag_id = "^aOptions.threadID.int(0)" or t.thread_id = "^aOptions.threadID.int(0)")
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
## aOptions.order[title|title_order|order]
  ^cleanMethodArgument[]
  $result[^CSQL.hash{
      select ti.content_id, t.tag_id as tagID
             ^if(^aOptions.withStandartFields.bool(false)){, $_defaultFields} 
             ^if(^aOptions.withExtraFields.bool(false) && def $_extraFields){, $_extraFields}
        from $_tagsTable as t
             join $_itemsTable as ti on (t.tag_id = ti.tag_id and ti.content_type_id = "^aOptions.contentType.int($_defaultContentType)")
       where 1=1
             ^switch[$aContent.CLASS_NAME]{
               ^case[DEFAULT;string;int]{and ti.content_id = "$aContent"}
               ^case[table]{
                 $lContentTableColumn[^if(def $aOptions.contentTableColumn){$aOptions.contentTableColumn}{contentID}]
                 and ti.content_id in (^aContent.menu{"$aContent.[$lContentTableColumn]", } -1)
               }
               ^case[hash]{
                 and ti.content_id in (^aContent.foreach[ck;cv]{"$ck",} -1)
               }
             }
             ^if(^aOptions.onlyVisible.bool(false)){
               and t.is_visible = 1
             } 
       order by
         ^switch[$aOptions.order]{
           ^case[DEFAULT;order_title]{t.sort_order asc, t.title asc}
           ^case[title]{t.title asc}
           ^case[order]{t.sort_order asc}
         }
  }[$.type[table] $.distinct(true)]]

@content[aTag;aOptions][k;v]
## aOptions.contentType[] 
## aOptions.limit
## aOptions.offset
## aOptions.tagTableColumn[tagID]
## aOptions.contentColumn[contentID]
  ^cleanMethodArgument[]
  $result[^CSQL.table{
    select content_id as ^if(def $aOptions.contentColumn){$aOptions.contentColumn}{contentID}
      from $_itemsTable
     where 1=1
     ^switch[$aTag.CLASS_NAME]{
       ^case[DEFAULT;string;int]{
         ^if(def $aTag){and tag_id = "$aTag"}
       }
       ^case[table]{                       
         $lTagTableColumn[^if(def $aOptions.tagTableColumn){$aOptions.tagTableColumn}{tagID}]
         and tag_id in (^aTag.menu{"$aTag.[$lTagTableColumn]", } -1)
       }
       ^case[hash]{
         and tag_id in (^aTag.foreach[k;v]{"$k",} -1)
       }
     }
     and content_type_id = "^aOptions.contentType.int($_defaultContentType)"
  }[
    ^if(def $aOptions.limit){$.limit($aOptions.limit)}
    ^if(def $aOptions.offset){$.offset($aOptions.offset)}
  ]]

@sqlJoinForContent[aTagID;aJoinName;aOptions][lAlias]
## Возвращает sql для секции join, который позволяет получить контент для конкретного тега
## aTagID - id тега (строка, таблица с полем "item" или хеш)
## aJoinName - имя колонки, которое чодержит content_id в запросе
## aOptions.contentType
## aOptions.alias - алиас для таблицы с tags_items
## aOptions.type[left|right|...] - тип джоина (дописывается перед ключевым словом "join")
## aOptions.tagsTableColumn - имя колонки в таблице тегов
## aOptions.where - выражение, которое добавляется в секцию on
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aJoinName)[Не задано имя колонки с content_id для join.]
  $lAlias[^if(def $aOptions.alias){$aOptions.alias}{$_itemsTable}]
  $result[$aOptions.type join $_itemsTable $lAlias on (^if(def $aTagID){${lAlias}.tag_id in (^_arrayToSQL[$aTagID;$.column[$aOptions.tagsTableColumn]])}{1=1} and ${lAlias}.content_type_id = "^aOptions.contentType.int($_defaultContentType)" and $aJoinName = ${lAlias}.content_id $aOptions.where)]

@sqlJoinForTags[aJoinName;aOptions][lAlias;lItemsAlias]
## Возвращает sql для секции join, который позволяет получить теги для контента
## (Не забывайте группировать результат по content_id, иначе получите "лишние" строки в ответе).
## aJoinName - имя колонки, которое содержит content_id в запросе
## aOptions.contentType
## aOptions.alias - алиас для таблицы tags
## aOptions.itemsAlias - alias для таблицы items
## aOptions.type[left|right|...] - тип джоина (дописывается перед ключевым словом "join")
## aOptions.where - выражение, которое добавляется в секцию on для таблицы items
## aOptions.itemsWhere - выражение, которое добавляется в секцию on для таблицы tags
## aOptions.withoutTagsTable(false) - не делать джоин на таблицу с тегами
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aJoinName)[Не задано имя колонки с tag_id для join.]
  $lAlias[^if(def $aOptions.alias){$aOptions.alias}{$_tagsTable}]
  $lItemsAlias[^if(def $aOptions.itemsAlias){$aOptions.itemsAlias}{$_itemsTable}]
  $result[$aOptions.type join $_itemsTable $lItemsAlias on ($aJoinName = ${lItemsAlias}.content_id and ${lItemsAlias}.content_type_id = "^aOptions.contentType.int($_defaultContentType)" $aOptions.itemsWhere) ^if(!^aOptions.withoutTagsTable.bool(false)){$aOptions.type join $_tagsTable $lAlias on (${lItemsAlias}.tag_id = ${lAlias}.tag_id $aOptions.where)}]

@count[aTagID;aOptions]
## Возвращает количество элементов в теге, если тег не указан, то возвращает общее количество протегированных элементов
## aOptions.contentType[]
## aOptions.onlyVisible(false)
  ^cleanMethodArgument[]
  ^if(def $aTagID){
    $result(^CSQL.int{
     select sum(`count`) as count
       from $_countersTable
      where tag_id = "$aTagID"
        and content_type_id = "^aOptions.contentType.int($_defaultContentType)"
    })
  }{
     $result(^CSQL.int{
      select count(distinct it.content_id) as count
        from $_itemsTable as it
       where 1=1
         and it.content_type_id = "^aOptions.contentType.int($_defaultContentType)"
         ^if(^aOptions.onlyVisible.bool(false)){
           and it.tag_id in (select tag_id from $_tagsTable where is_visible = 1)
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
## Создает новые теги в системе, если они не существует.
## aTag - string
## aOptions.slug
## aOptions.description
## aOptions.parentID
## aOptions.threadID
## aOptions.sortOrder
## aOptions.isVisible    
## aOptions.separator - разделитель тегов в строке
## result[tag]
  ^cleanMethodArgument[]   
  ^pfAssert:isTrue(def $aTags)[На задано имя тега.]

  $lTags[^splitTags[$aTags;$.separator[$aOptions.separator]]]
  ^if($lTags){
    ^CSQL.void{
      insert ignore into $_tagsTable (title, slug, description, parent_id, thread_id, sort_order, is_visible)
      values
      ^lTags.foreach[tag;v]{
          ("$tag", "^if(def $aOptions.slug){$aOptions.slug}{^transliter.toURL[$tag]}", "$aOptions.description",
                  "^aOptions.parentID.int(0)", "^aOptions.threadID.int(0)", "^aOptions.sortOrder.int(0)", "^aOptions.isVisible.int(1)")
      }[, ]
    }                  
  }
  $result[^tags[$.title[$lTags]]]

@deleteTag[aTagID]
## Удаляет тег и все, что им протегировано.
  ^pfAssert:isTrue(^aTagID.int(0))[Не задан ID тега.]
  $result[]          
  ^CSQL.transaction{
    ^CSQL.void{delete from $_countersTable where tag_id = "$aTagID"}
    ^CSQL.void{delete from $_itemsTable where tag_id = "$aTagID"}
    ^CSQL.void{delete from $_tagsTable where tag_id = "$aTagID"}
  }

@modifyTag[aTagID;aOptions][k;v]
## Редактирует запись о теге в БД
## aOptions.slug
## aOptions.description
## aOptions.parentID
## aOptions.threadID
## aOptions.sortOrder
## aOptions.isVisible
  ^cleanMethodArgument[]
  ^CSQL.void{
    update $_tagsTable
       set ^_tagsFields.foreach[k;v]{
             ^if(^aOptions.contains[$k]){
               $v = "$aOptions.[$k]",
             }
           }
           tag_id = tag_id
     where tag_id = "^aTagID.int(0)"
  }
  
@recountTags[aTags;aOptions][lTagsList;lWhere;lCounters]
## Обновляет счетчики содержимого для тегов  
## aTags[] - табличка, которую возвращает метод tags. Если не заданы теги, то считаем для всех тегов.
## aOptions.contentType      
  ^cleanMethodArgument[]
  $result[]    
  ^CSQL.transaction{
#   В MySQL'е можно все сделать сильно проще (за счет поддержки replace-select), 
#   но для джененрик-класса привязка к одной базе не канает. 
    $lTagsList[^if(def $aTags && $aTags){^aTags.menu{"$aTags.tagID"}[, ], -1}]
    $lWhere[1=1
      ^if(def $aTags){
        and tag_id in ($lTagsList)
      }
      ^if(def $aOptions.contentType){ and content_type_id = "$aOptions.contentType"}
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
        values ^lCounters.menu{("$lCounters.contentType", "$lCounters.tagID", "$lCounters.cnt")}[, ]
      }
    }
  } 

@tagging[aContent;aTags;aOptions][lTags;k;v;ck;cv;lContentType;lContentColumnName;lTagsColumnName;lHTags]
## Тегирует контент (можно протегировать сразу много объектов по куче тегов)  
## aTags - string|table
## aOptions.tagsTableColumn[tagID] - имя колонки в таблице с тегами, содержащее tagID
## aContent - string|int|hash|table. Для хеша id беерем из ключа, для таблицы из колонки.
## aOptions.contentTableColumn[contentID] - имя колонки в таблице с контентом, содержащее ID
## aOptions.mode[new|append] - заново протегировать контент или добавить теги к уже существующим
## aOptions.contentType 
## aOptions.appendParents(false) - добавить родительские теги
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aContent)[Не заданы объекты для тегирования.]
  $result[]

  ^CSQL.transaction{
    $lContentType[^aOptions.contentType.int($_defaultContentType)]
    $lContentColumnName[^if(def $aOptions.contentTableColumn){$aOptions.contentTableColumn}{contentID}]
    $lTagsColumnName[^if(def $aOptions.tagsTableColumn){$aOptions.tagsTableColumn}{tagID}]

    $lTags[^if($aTags is string){^newTags[$aTags]}{$aTags}] 

    ^if(!def $aOptions.mode || $aOptions.mode eq "new"){
      ^CSQL.void{
        delete from $_itemsTable 
        where 
        ^switch[$aContent.CLASS_NAME]{
          ^case[string;int;double]{content_id = "$aContent"}
          ^case[hash]{content_id in (^if($aContent){^aContent.foreach[ck;cv]{"$ck"}[, ],} -1)}
          ^case[table]{content_id in (^if($aContent){^aContent.menu{"$aContent.[$lContentColumnName]"}[, ],} -1)}
          }
        }
        and content_type_id = "$lContentType"
      }
    }

    ^if($lTags){
      $lHTags[^lTags.hash[$lTagsColumnName][$lTagsColumnName][$.type[string] $.distinct(true)]]
      ^if(^aOptions.appendParents.bool(false)){
        ^lHTags.add[^_getTagsParents[$lHTags;^tags[]]]
      }        
      ^CSQL.void{
        insert ignore into $_itemsTable (content_type_id, tag_id, content_id)
        values 
        ^lHTags.foreach[k;v]{
          ^switch[$aContent.CLASS_NAME]{
            ^case[string;int;double]{
              ("$lContentType", "$k", "$aContent")
            }
            ^case[hash]{       
              ^aContent.foreach[ck;cv]{
                ("$lContentType", "$k", "$ck")
              }[, ]
            }
            ^case[table]{                                 
              ^aContent.menu{
                ("$lContentType", "$k", "$aContent.[$lContentColumnName]")
              }[, ]
            }
          }
        }[, ]
      }
    }
  }

# Пересчитывать все теги не лучшая идея, но при перетегировании ничего другого не сделаешь.
# В принципе можно сначала достать старые теги, сложить их с новыми и пересчитывать только сумму:
# это "потоконебезопасно", но для больших деревьев тегов может быть оправдано.
  ^recountTags[;$.contentType[$lContentType]]
#  ^recountTags[$lTags;$.contentType[$lContentType]]

#----- Private -----

@_getTagsParents[aTags;aTree][k;v;lCurTag]
## Ищет для aTags всех родителей по aTree
## aTags[hash] - хеш с тегами
## aTree[table] - таблица с деревом тегов
  $result[^hash::create[]]
  ^aTags.foreach[k;v]{
    $lCurTag[$k]
    ^while(^aTree.locate[tagID;$lCurTag]){
      $result.[$aTree.tagID][$aTree.tagID]
      $lCurTag[$aTree.parentID]
    }
  } 

@_arrayToSQL[aArray;aOptions][lColName;k;v]
## aArray[string|table|hash] 
## aOptions.column[item]
## aOptions.appendNull
  ^cleanMethodArgument[]
  $lColName[^if(def $aOptions.column){$aOptions.column}{item}]
  ^if($aArray is hash){
    $result[^aArray.foreach[k;v]{"^k.trim[both]"}[, ]]
  }($aArray is table){
    $result[^aArray.menu{"^aArray.[$lColName].trim[both]"}[, ]]
  }{
    $result["^aArray.trim[both]"]
   }
  ^if($aOptions.appendNull){
    $result[$result^if(def $result){, }null]
  }
