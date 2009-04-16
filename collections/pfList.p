# PF Library

#@module   ArrayList Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

## Проиндексированная коллекция.

@CLASS
pfList

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
  $_array[^hash::create[]]
  ^reset[]

#----- Properties -----

@GET_count[]
## Возвращает количество элементов в коллекции.
  $result(^_array._count[])

@GET_DEFAULT[aIndex]
  ^if(^aIndex.int(-1) >= 0){
    $result[^at[$aIndex]]
  }{
     $result[]
  }
  
@GET_indexes[]
## Возвращает таблицу с единственной колонкой "index", 
## в которой перечислены все доступные индексы.
  $result[^_array._keys[index]]
  ^result.sort($result.index)[asc]

@GET_firstIndex[]
## Возвращает минимальное значение индекса коллекции.
  ^if($count > 0){
    $result($indexes.index)
  }{
     $result(-1)
   }

@GET_lastIndex[]
## Возвращает максимальное значение индекса коллекции.
  ^if($count > 0){
    $result[$indexes]
    ^result.offset(-1)
    $result[$result.index]
  }{
     $result(-1)
   }

#----- Public -----

@contains[aIndex][lKeys]
## Проверяет есть ли в коллекци элемент с индексом aIndex
  $result(^_array.contains[$aIndex])

@at[aIndex]
## Возвращает элемент с индексом aIndex
  ^pfAssert:isTrue(^contains[$aIndex])[Элемента с номером $aIndex нет в коллеции.]
  $result[$_array.[$aIndex]]

@add[aItem][result]
## Добавляем элемент в коллекцию
  $_array.[^eval($lastIndex + 1)][$aItem]
  ^reset[]

@addRange[aCollection][result;it]
## Добавляет коллекцию aCollection в конец текуще коллекции
  ^_importFromCollection[$aCollection]

@insert[aIndex;aItem][result]
## Вставляет элемент в позицию aIndex.
  ^pfAssert:isTrue(^aIndex.int(-1) >= 0)[Неверный индекс коллекции ($aIndex).]
  $_array.[$aIndex][$aItem]
  ^reset[]

@removeAt[aIndex][result]
## Удаляет элемент с индексом aIndex из коллекции.
  ^pfAssert:isTrue(^aIndex.int(-1) >= 0)[Неверный индекс коллекции ($aIndex).]
  ^if($count){
    ^_array.delete[$aIndex]
    ^reset[]
  }
  
@optimize[][result;lNew;it]
## Оптимизирует коллекцию, удаляя пробелы в нумерации. [1,4,18] -> [0,1,2]
  ^if($count){
  	$lNew[^hash::create[]]
    ^foreach[it]{
    	$lNew.[^eval($lNew)][$it]
    }
    $_array[$lNew]
  }
  ^reset[]

@reverse[][result;lNew;it]
## Меняет порядок элементов на обратный
  ^if($count){
  	$lNew[^hash::create[]]
    ^foreach[it]{
    	$lNew.[^eval($count - $lNew)][$it]
    }
    $_array[$lNew]
  }
  ^reset[]

#----- Iterator's -----

@GET_currentItem[][lIndexes]
## Возвращает текущий элемент коллекции
  ^pfAssert:isTrue($count > 0)[Коллекция пустая.]
  $lIndexes[$indexes]
  ^lIndexes.offset[set]($_currentIndex)
  $result[^at[$lIndexes.index]]



