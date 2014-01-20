@CLASS
pfTagging

@USE
pf/sql/orm/pfSQLTable.p

@BASE
pfClass

@create[aOptions]
## aOptions.sql - ссылка на sql-класс.
## aOptions.tagsSeparator[] - регулярное выражение для разделителя тегов
## aOptions.contentType(0) - стандартный content_type_id
## aOptions.tablesPrefix
## aOptions.tagsModel
## aOptions.contentModel
## aOptions.countersModel
  ^cleanMethodArgument[]

  $_CSQL[$aOptions.sql]
  ^defReadProperty[CSQL]

  $_tablesPrefix[$aOptions.tablesPrefix]

  $_contentType[^aOptions.contentType.int(0)]
  ^defReadProperty[contentType]

# Переменные с моделями, но они нужны только для работы свойств
  $_tags[$aOptions.tagsModel]
  $_content[$aOptions.contentModel]
  $_counters[$aOptions.countersModel]

@GET_tags[]
  ^if(!def $_tags){
    $_tags[^pfSQLCTTagsModel::create[${_tablesPrefix}tags;
      $.sql[$CSQL]
      $.tagging[$self]
    ]]
  }
  $result[$_tags]

@GET_content[]
  ^if(!def $_content){
    $_content[^pfSQLCTContentModel::create[${_tablesPrefix}tags_content;
      $.sql[$CSQL]
      $.tagging[$self]
    ]]
  }
  $result[$_content]

@GET_counters[]
  ^if(!def $_counters){
    $_counters[^pfSQLCTCountersModel::create[${_tablesPrefix}tags_counters;
      $.sql[$CSQL]
      $.tagging[$self]
    ]]
  }
  $result[$_counters]

@tagging[aContent;aTags;aOptions][locals]
## Тегирует контент (можно протегировать сразу много объектов по куче тегов)
## aContent — string|int|hash|table. Для хеша id берем из ключа, для таблицы из колонки.
## aOptions.contentTableColumn[contentID] — имя колонки в таблице с контентом, содержащее ID
## aTags — string|table|hash
## aOptions.tagsTableColumn[tagID] — имя колонки в таблице с тегами, содержащее tagID
## aOptions.mode[new|append] — заново протегировать контент или добавить теги к уже существующим
## aOptions.contentType
## TODO:
## aOptions.appendParents(false) - добавить родительские теги


#----- Таблички в БД -----

@CLASS
pfSQLCTTagsModel

@BASE
pfSQLTable

@create[aTableName;aOptions]
  ^cleanMethodArgument[]
  ^BASE:create[$aTableName;
    $.sql[$aOptions.sql]
    $.allAsTable(true)
  ]

  $_tagging[$aOptions.tagging]
  ^defReadProperty[tagging]

  ^addFields[
    $.tagID[$.dbField[tag_id] $.plural[tags] $.processor[uint] $.primary(true) $.widget[none]]
    $.parentID[$.dbField[parent_id] $.plural[parents] $.processor[uint] $.label[]]
    $.threadID[$.dbField[thread_id] $.plural[threads] $.processor[uint] $.label[]]
    $.title[$.label[]]
    $.slug[$.label[]]
    $.description[$.label[]]
    $.sortOrder[$.dbField[sort_order] $.processor[int] $.label[]]
    $.isActive[$.dbField[is_active] $.processor[bool] $.default(1) $.widget[none]]
    $.createdAt[$.dbField[created_at] $.processor[auto_now] $.skipOnUpdate(true) $.widget[none]]
    $.updatedAt[$.dbField[updated_at] $.processor[auto_now] $.widget[none]]
  ]

  $_defaultOrderBy[$.sortOrder[asc] $.title[asc] $.tagID[asc]]

  $_transliter[]

@GET_transliter[]
  ^if(!def $_transliter){
    ^use[pf/wiki/pfURLTranslit.p]
    $_transliter[^pfURLTranslit::create[]]
  }
  $result[$_transliter]

@delete[aTagID]
  $result[^modify[$aTagID;$.isActive(false)]]

@restore[aTagID]
  $result[^modify[$aTagID;$.isActive(true)]]


@CLASS
pfSQLCTContentModel

@BASE
pfSQLTable

@create[aTableName;aOptions]
  ^cleanMethodArgument[]
  ^BASE:create[$aTableName;
    $.sql[$aOptions.sql]
    $.allAsTable(true)
  ]

  $_tagging[$aOptions.tagging]
  ^defReadProperty[tagging]

  ^addFields[
    $.contentTypeID[$.dbField[content_type_id] $.plural[contentTypes] $.processor[uint] $.default($_tagging.contentType) $.label[]]
    $.tagID[$.dbField[tag_id] $.plural[tags] $.processor[uint] $.label[]]
    $.contentID[$.dbField[content_id] $.plural[content] $.processor[uint] $.label[]]
    $.createdAt[$.dbField[created_at] $.processor[auto_now] $.skipOnUpdate(true) $.widget[none]]
    $.updatedAt[$.dbField[updated_at] $.processor[auto_now] $.widget[none]]
  ]


@CLASS
pfSQLCTCountersModel

@BASE
pfSQLTable

@create[aTableName;aOptions]
  ^cleanMethodArgument[]
  ^BASE:create[$aTableName;
    $.sql[$aOptions.sql]
    $.allAsTable(true)
  ]

  $_tagging[$aOptions.tagging]
  ^defReadProperty[tagging]

  ^addFields[
    $.contentTypeID[$.dbField[content_type_id] $.plural[contentTypes] $.default($_tagging.contentType) $.processor[int] $.label[]]
    $.tagID[$.dbField[tag_id] $.plural[tags] $.processor[uint] $.label[]]
    $.count[$.processor[uint] $.label[]]
    $.createdAt[$.dbField[created_at] $.processor[auto_now] $.skipOnUpdate(true) $.widget[none]]
    $.updatedAt[$.dbField[updated_at] $.processor[auto_now] $.widget[none]]
  ]

