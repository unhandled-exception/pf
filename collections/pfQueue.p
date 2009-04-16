# PF Library

#@module   Queue Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

## Коллекция "очередь". Певый вошел - первый вышел.

@CLASS
pfQueue

@USE
pf/collections/pfCollection.p

@BASE
pfCollection

#----- Constructor -----

@create[aValues;aOptions]
## Создает коллекцию. 
## aValues - таблица, хэш или коллекция, содержимое которой копируется в новую коллекцию.
  ^clear[]
  ^reset[]
  ^BASE:create[$aValues;$aOptions]

@clear[]
## Удаляет все элементы из коллекции
  $_queue[^hash::create[]]
  $_first(0)

#----- Properties -----

@GET_count[]
  $result(^_queue._count[])

#----- Public -----

@add[aItem]
## Добавляет элемент в конец очереди.
  ^enqueue[$aItem]

@enqueue[aItem]
## Добавляет элемент в конец очереди.
  $_queue.[$count][$aItem]
  ^reset[]

@dequeue[]
## Извлекает элемент из начала очереди.
  ^pfAssert:isTrue($count)[Очередь пуста.]
  $result[$_queue.[$_first]]
  ^_queue.delete[$_first]
  ^_first.inc[]
  ^reset[]

@peek[]
## Извлекает элемент из вершины стека, но не удаляет его.
  ^pfAssert:isTrue($count)[Очередь пуста.]
  $result[$_queue.[$_first]]

@reverse[][result;lNew;it]
## Меняет порядок элементов на обратный
  ^if($count){
  	$lNew[^hash::create[]]
    ^foreach[it]{
    	$lNew.[^eval($count - $lNew - 1)][$it]
    }
    $_queue[$lNew]
    $_first(0)
  }
  ^reset[]
  
#----- Iterator's -----

@GET_currentItem[]
## Текущий элемент коллекции c порядкоовым номером $currentIndex
  $result[$_queue.[^eval($_first + $currentIndex)]]


