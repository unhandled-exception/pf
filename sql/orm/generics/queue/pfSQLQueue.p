@CLASS
pfSQLQueue

## Класс для работы с очередью в MySQL-сервере.
## На основе статьи Якова Сироткина — http://telamon.ru/articles/async.html

@USE
pf/sql/orm/pfSQLTable.p

@BASE
pfSQLTable

@create[aTableName;aOptions]
## aOptions.defaultTaskType[0]
  ^BASE:create[$aTableName;$aOptions]
  ^pfAssert:isTrue($CSQL is pfMySQL)[Очередь поддерживает работу только с MySQL.]

  ^addFields[
    $.taskID[$.dbField[task_id] $.plural[tasks] $.primary(true) $.widget[none]]
    $.taskType[$.dbField[task_type] $.default(^aOptions.defaultTaskType.int(0)) $.processor[uint] $.label[]]
    $.entityID[$.dbField[entity_id] $.plural[entities] $.processor[uint] $.label[]]
    $.processTime[$.dbField[process_time] $.processor[now] $.label[]]
    $.attempt[$.processor[uint] $.default(0) $.label[]]
    $.createdAt[$.dbField[created_at] $.processor[auto_now] $.skipOnUpdate(true) $.widget[none]]
  ]

  $_defaultOrderBy[$.taskID[asc]]

@fetch[aOptions][locals]
## Достает из базы задачи и сдвигает время очередной обработки.
## aOptions — параметры как для pfSQLTable.all
## aOptions.limit(1)
  ^cleanMethodArgument[]
  ^CSQL.naturalTransaction{
    $lConds[^hash::create[$aOptions]]

    $lLimit(^aOptions.limit.int(1))
    $lOffset(^aOptions.offset.int(0))
    ^lConds.delete[limit]
    ^lConds.delete[offset]

    $result[^all[
      $lConds
      $.[processTime <][$_now]
    ][
      $.tail[
#       Хак с ручным заданием limit/offset для того,
#       чтобы можно было использовать "for update" в MySQL.
        limit $lLimit
        ^if($lOffset > 0){
          offset $lOffset
        }
        for update
      ]
    ]]
    ^result.foreach[k;v]{
      ^modify[$v.taskID;
        $.attempt($v.attempt + 1)
        $.processTime[^date::create($_now + ^math:pow(2;$v.attempt)/1440)]
      ]
    }
  }

@accept[aTasks]
## Удаляет из очереди все обработанные задачи.
## aTasks[taskID|table|hash]
  $result[]
  ^BASE:deleteAll[
    $.tasks[$aTasks]
  ]
