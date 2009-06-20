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
  $_firstIndex(-1)
  $_lastIndex(-1)             
  ^BASE:create[$aValues;$aOptions]
                                 

@reset[]
  ^BASE:reset[]  
  $_indexes[]
  
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
  ^if(!def $_indexes){
    ^_generateIndexes[]
  }
  $result[$_indexes]

@GET_firstIndex[]
## Возвращает минимальное значение индекса коллекции.
  $result($_firstIndex)

@GET_lastIndex[]
## Возвращает максимальное значение индекса коллекции.
  $result($_lastIndex)

#----- Public -----

@contains[aIndex][lKeys]
## Проверяет есть ли в коллекци элемент с индексом aIndex
  $result(^_array.contains[$aIndex])

@at[aIndex]
## Возвращает элемент с индексом aIndex
  ^pfAssert:isTrue(^contains[$aIndex])[Элемента с номером $aIndex нет в коллеции.]
  $result[$_array.[$aIndex]]

@add[aItem][result;$lIndex]
## Добавляем элемент в коллекцию
  ^if(!$count){$_firstIndex(0)}
  $_array.[^eval($lastIndex + 1)][$aItem]
  ^_lastIndex.inc[]
  ^reset[]                   
#  ^pfAssert:fail[$_firstIndex - $_lastIndex]

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
    ^_recountFirstLastIndexes[]
  }
  
@optimize[][result;lNew;it]
## Оптимизирует коллекцию, удаляя пробелы в нумерации. [1,4,18] -> [0,1,2]
  ^if($count){
  	$lNew[^hash::create[]]
    ^foreach[it]{
    	$lNew.[^eval($lNew)][$it]
    }
    $_array[$lNew]
    ^_recountFirstLastIndexes[]
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
    ^_recountFirstLastIndexes[]
  }
  ^reset[]

@has[aString][lItem]
## Проверяет содержит ли список строку aString.
  $result(false)                   
  ^reset[]
  ^if($count){
    ^while(!$result && ^moveNext[]){
      $result($currentItem is string && $currentItem eq $aString)
    }
  }


#----- Iterator's -----

@GET_currentItem[][lIndexes]
## Возвращает текущий элемент коллекции
  ^pfAssert:isTrue($count > 0)[Список пустой.]
  ^indexes.offset[set]($_currentIndex)
  $result[^at[$indexes.index]]
  

#----- Private -----

@_generateIndexes[]
  $_indexes[^_array._keys[index]]
  ^_indexes.sort($_indexes.index)[asc] 

@_recountFirstLastIndexes[]
  $result[]
  $_firstIndex(-1)
  $_lastIndex(-1)             
  ^if($count > 0){
    $_firstIndex(0)
    $_lastIndex(0)
    ^_array.foreach[k;v]{
      ^if($k < $_firstIndex){$_firstIndex($k)}
      ^if($k > $_lastIndex){$_lastIndex($k)}
    }
  }

