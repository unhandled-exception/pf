@CLASS
pfSQLQueue

## Класс для работы с очередью в MySQL-сервере.
## На основе статьи Якова Сироткина — http://telamon.ru/articles/async.html

@USE
pf/sql/orm/pfSQLTable.p

@BASE
pfSQLTable

@create[aTableName;aOptions]
## aOptions.defaultTaskType[0] — значение типа задачи по-умолчанию
## aOptions.interval(0.0) — интервал в минутах между попытками обработки задач.
##                          Если ноль, то используем 2**attempt.
  ^BASE:create[$aTableName;$aOptions]
  ^pfAssert:isTrue($CSQL is pfMySQL)[Очередь поддерживает работу только с MySQL.]

  $_defaultResultType[table]

  ^addFields[
    $.taskID[$.dbField[task_id] $.plural[tasks] $.primary(true) $.widget[none]]
    $.taskType[$.dbField[task_type] $.default(^aOptions.defaultTaskType.int(0)) $.processor[uint] $.label[]]
    $.entityID[$.dbField[entity_id] $.plural[entities] $.processor[uint] $.label[]]
    $.processTime[$.dbField[process_time] $.processor[now] $.label[]]
    $.attempt[$.processor[uint] $.default(0) $.label[]]
    $.createdAt[$.dbField[created_at] $.processor[auto_now] $.skipOnUpdate(true) $.widget[none]]
  ]

  $_defaultOrderBy[$.taskID[asc]]

  $_interval(^aOptions.interval.double(0.0))

@fetchOne[aOptions]
## Достает из базы ровно одну задачу
  $result[^fetch[^hash::create[$aOptions] $.limit(1) $.asHash(true)]]
  $result[^result._at[first]]

@fetch[aOptions][locals]
## Достает из базы таблицу с задачами и сдвигает время очередной обработки.
## aOptions — параметры как для pfSQLTable.all
## aOptions.limit(1)
  ^cleanMethodArgument[]
  ^CSQL.naturalTransaction{
    $lConds[^hash::create[$aOptions]]
    $result[^all[
      $lConds
      $.[processTime <][$_now]
    ][
      $.tail[for update]
    ]]
    ^result.foreach[k;v]{
      ^modify[$v.taskID;
        $.attempt($v.attempt + 1)
        ^if($_interval > 0){
          $.processTime[^date::create($_now + ($_interval/1440))]
        }{
          $.processTime[^date::create($_now + ^math:pow(2;$v.attempt)/1440)]
        }
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
