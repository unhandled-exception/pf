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
## aValues - таблица, хэш или коллекция, содержимое которой копируется в новую коллекцию.
  ^clear[]
  ^reset[]
  ^BASE:create[$aValues;$aOptions]

@clear[]
  $_queue[^hash::create[]]
  $_first(0)
  $_last(0)

#----- Properties -----

@GET_count[]
  $result(^_queue._count[])

#----- Public -----

@add[aItem]
## Добавляет элемент в конец очереди.
  ^enqueue[$aItem]

@enqueue[aItem]
## Добавляет элемент в конец очереди.
  $_queue.[$_last][$aItem]
  ^_last.inc[]
  ^reset[]

@dequeue[]
## Извлекает элемент из начала очереди.
  ^pfAssert:isTrue($count)[Очередь пуста.]
  $result[$_queue.[$_first]]
  ^_queue.delete[$_first]
  ^_first.inc[]
  ^reset[]

@peek[]
## Извлекает элемент из начала очереди, но не удаляет его.
  ^pfAssert:isTrue($count)[Очередь пуста.]
  $result[$_queue.[$_first]]

@reverse[][result;lNew;it;lCount]
  $lCount($count)
  ^if($lCount){
  	$lNew[^hash::create[]]
    $i($lCount - 1)
    ^_queue.foreach[_;v]{
    	$lNew.[$i][$v]
      ^i.dec[]
    }
    $_queue[$lNew]
    $_first(0)
    $_last($lNew - 1)
  }
  ^reset[]

#----- Iterator's -----

@GET_currentItem[]
  $result[$_queue.[^eval($_first + $currentIndex)]]
