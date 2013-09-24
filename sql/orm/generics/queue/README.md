pfSQLQueue
==========

Класс, наследник pfSQLTable, который реализует очередь для асинхронной обработки в СУБД MySQL. Реализовано на основе идей из статьи Якова Сироткина [«Асинхронная обработка задач»](http://telamon.ru/articles/async.html). Очень советую перед началом использования прочитать её.

Пример
------

Представим, что нам надо отправлять письма пользователям. У нас есть табличка с сообщениями и мы хотим реализовать асинхронную обработку.

Для начала работы создаем в базе данных табличку для очереди:

    CREATE TABLE `queue` (
      `task_id` bigint(20) NOT NULL AUTO_INCREMENT,
      `task_type` int(10) unsigned NOT NULL DEFAULT '0',
      `entity_id` int(10) unsigned NOT NULL,
      `process_time` datetime NOT NULL,
      `attempt` int(10) unsigned DEFAULT '0',
      `created_at` datetime DEFAULT NULL,
      PRIMARY KEY (`task_id`),
      UNIQUE KEY `uq_tt_eid` (`task_type`,`entity_id`),
      KEY `idx_pt` (`process_time`)
    ) ENGINE=InnoDB CHARSET=utf8;

Создаем классы:

      $sql[^pfMySQL[$MAIN:connect-string]]
     
    # Сообщения храним в отдельно табличке (messageIВ, address, subject, body)
    # Реализацию этого класса не привожу :)
      $messages[^messagesTable::create[messages;$.sql[$sql]]]
     
    # Очередь
      $queue[^pfSQLQueue::create[queue;$.sql[$sql]]]

Добавляем сообщение и ставим его в очередь:

      $messageID[^messages.new[
        $.address[some@domain.com]
        $.subject[Mail from site.com]
        $.body[Hello world!]
      ]]
      $taskID[^queue.new[$.entityID[$messageID]]]

Теперь в кроне обрабатываем задачу:

    # Достаем одну задачу
      $task[^queue.fetchOne[]]
      
    # Обрабатываем задачу
      ^try{
        $message[^messages.one[$.messageID[$task.entityID]]]
        ^mail:send[
          $.from[my@site.com]
          $.to[$message.address]
          $.subject[$message.subject]
          $.text[$message.body]
        ]
        ^queue.accept[$task.entityID]
      }{
    #    Если произошла ошибка, то ничего страшного — отправим при следующей попытке.
         $exception.handled(true)
       }

Если мы хотим обработать несколько задач сразу, то код немного усложнится. Нам надо будет достать несколько задач методом fetch с параметром $.limit и после каждой удачной обработки вызывать метод accept.

Важные детали
-------------

* Класс — наследник pfSQLTable, поэтому вы легко можете добавить в табличку поля для хранения дополнительных данных о задачах.
* Вы можете хранить в одной очереди разные типы задач. Для этого при создании и выборке из таблицы необходимо указать поле typeID.
* При обработке задач надо использовать именно методы fetchOne и fetch, а не all или one, поскольку в первых двух реализована логика транзакции с необходимыми блокировками.
* Очень важно использовать для таблички транзакционный энжин MySQL. Хорошее решение —  Innodb. Использовать MyIsam не нужно.
