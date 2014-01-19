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
## aOptions.itemsModel
## aOptions.countersModel
  ^cleanMethodArgument[]

  $_CSQL[$aOptions.sql]
  ^defReadProperty[CSQL]

  $_tablesPrefix[$aOptions.tablesPrefix]

  $_contentType[^aOptions.contentType.int(0)]
  ^defReadProperty[contentType]

# Переменные с моделями, но они нужны только для работы свойств
  $__tags[$aOptions.tagsModel]
  $__items[$aOptions.itemsModel]
  $__counters[$aOptions.countersModel]

@GET_tags[]
  ^if(!def $__tags){
    $__tags[^pfSQLCTTagsModel::create[${_tablesPrefix}tags;
      $.sql[$CSQL]
      $.tagging[$self]
    ]]
  }
  $result[$__tags]

@GET_items[]
  ^if(!def $__items){
    $__items[^pfSQLCTItemsModel::create[${_tablesPrefix}tags_items;
      $.sql[$CSQL]
      $.tagging[$self]
    ]]
  }
  $result[$__items]

@GET_counters[]
  ^if(!def $__counters){
    $__counters[^pfSQLCTCountersModel::create[${_tablesPrefix}tags_counters;
      $.sql[$CSQL]
      $.tagging[$self]
    ]]
  }
  $result[$__counters]

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
    $.tagID[$.dbField[tag_id] $.processor[uint] $.primary(true) $.widget[none]]
    $.parentID[$.dbField[parent_id] $.processor[uint] $.label[]]
    $.threadID[$.dbField[thread_id] $.processor[uint] $.label[]]
    $.title[$.label[]]
    $.slug[$.label[]]
    $.description[$.label[]]
    $.sortOrder[$.dbField[sort_order] $.processor[int] $.label[]]
    $.isActive[$.dbField[is_active] $.processor[bool] $.default(1) $.widget[none]]
    $.createdAt[$.dbField[created_at] $.processor[auto_now] $.skipOnUpdate(true) $.widget[none]]
    $.updatedAt[$.dbField[updated_at] $.processor[auto_now] $.widget[none]]
  ]

  $_defaultOrderBy[$.tagID[asc]]

@delete[aTagID]
  $result[^modify[$aTagID;$.isActive(false)]]

@restore[aTagID]
  $result[^modify[$aTagID;$.isActive(true)]]


@CLASS
pfSQLCTItemsModel

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
    $.contentTypeID[$.dbField[content_type_id] $.processor[uint] $.label[]]
    $.tagID[$.dbField[tag_id] $.processor[uint] $.label[]]
    $.contentID[$.dbField[content_id] $.processor[uint] $.label[]]
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
    $.contentTypeID[$.dbField[content_type_id] $.processor[int] $.label[]]
    $.tagID[$.dbField[tag_id] $.processor[uint] $.label[]]
    $.count[$.processor[uint] $.label[]]
    $.createdAt[$.dbField[created_at] $.processor[auto_now] $.skipOnUpdate(true) $.widget[none]]
    $.updatedAt[$.dbField[updated_at] $.processor[auto_now] $.widget[none]]
  ]

