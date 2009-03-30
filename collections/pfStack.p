# PF Library

#@module   Stack Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

## Стековая коллекция. Певый вошел - последний вышел.

@CLASS
pfStack

@USE
pf/collections/pfCollection.p

@BASE
pfCollection

#----- Constructor -----

@create[aValues]
## Создает коллекцию. 
## aValues - таблица, хэш или коллекция, содержимое которой копируется в новую коллекцию.
  ^clear[]
  ^BASE:create[$aValues]

@clear[]
## Удаляет все элементы из коллекции
  $_stack[^hash::create[]]

#----- Properties -----

@GET_count[]
  $result(^_stack._count[])

#----- Public -----

@add[aItem]
## Добавляет элемент в вершину стека.
  ^push[$aItem]

@push[aItem]
## Добавляет элемент в вершину стека.
  $_stack.[$count][$aItem]
  ^reset[]

@pop[]
## Извлекает элемент из вершины стека.
  ^pfAssert:isTrue($count)[Стек пустой.]
  $result[$_stack.[^eval($count - 1)]]
  ^_stack.delete[^eval($count - 1)]
  ^reset[]

@peek[]
## Извлекает элемент из вершины стека, но не удаляет его.
  ^pfAssert:isTrue($count)[Стек пустой.]
  $result[$_stack.[^eval($count-1)]]

@reverse[][result;lNew;it]
## Меняет порядок элементов на обратный
  ^if($count){
  	$lNew[^hash::create[]]
    ^foreach[it]{
    	$lNew.[^eval($lNew)][$it]
    }
    $_stack[$lNew]
  }
  ^reset[]
  
#----- Iterator's -----

@GET_currentItem[]
## Текущий элемент коллекции c порядкоовым номером $currentIndex
## В порядке работы команды pop.
  $result[$_stack.[^eval($count - $currentIndex - 1)]]



  