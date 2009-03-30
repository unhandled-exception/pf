# PF Library

#@module   Collection Base Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

## Абстрактная коллекция.

@CLASS
pfCollection

@USE
pf/types/pfClass.p

@BASE
pfClass

#----- Constructor -----

@create[aValues]
## Создает коллекцию. 
## aValues - таблица, хэш или коллекция, содержимое которой копируется в новую коллекцию.
  ^pfAssert:isTrue(!def $aValues 
     || (def $aValues && ($aValues is pfCollection || $aValues is hash || $aValues is table))
  )
  ^BASE:create[]

  ^if(def $aValues){
  	^if($aValues is table){
  		^_importFromTable[$aValues]
  	}
  	^if($aValues is hash){
  		^_importFromHash[$aValues]
  	}
  	^if($aValues is pfCollection){
  		^_importFromCollection[$aValues]
  	}
  }

@_importFromTable[aTable][result;lColumns]
## Добавляет в коллекцию данные из самого левого столбца таблицы.
  ^pfAssert:isTrue($aTable is table)[Параметр должен быть таблицей.]
  ^if($aTable){
  	$lColumns[^aTable.columns[]]
  	^aTable.menu{
  		^add[$aTable.[$lColumns.column]]
  	}
  }

@_importFromHash[aHash][result]
## Добавляет в коллекцию данные из хэша. 
  ^pfAssert:isTrue($aHash is hash)[Параметр должен быть хэшем.]
  ^if($aHash){
    ^aHash.foreach[k;v]{
   		^add[$v]
    }
  }

@_importFromCollection[aCollection][result;it]
## Добавляет коллекцию aCollection в текущую коллекцию.
  ^pfAssert:isTrue($aCollection is pfCollection)[Параметр должен быть коллекцией.]
  ^if($aCollection.count){
    ^aCollection.foreach[it]{
   	  ^add[$it]
    }	
  } 
    
#----- Properties -----

@GET_count[]
## Возвращает количество элементов в коллекции.
  $result(0)

@GET[]
  $result($count)

#----- Public -----

@add[aItem]
## Добавляем элемент в коллекцию
  ^_abstractMethod[]    

@clear[]
## Удаляет все элементы из коллекции
  ^_abstractMethod[]    

@reverse[]
## Меняет порядок элементов на обратный
  ^_abstractMethod[]    

    
#----- Iterator's -----

@GET_currentItem[]
## Текущий элемент коллекции c порядкоовым номером $currentIndex
  ^pfAssert:fail[Обращение к свойству абстрактного класса.]    

@GET_currentIndex[]
## Номер текущей позиции (нумерация от нуля)
  $result($_currentIndex)

@reset[]
## Обнуляет счетчик текущей позиции
  $_currentIndex(-1)  

@moveNext[][lIndexes]
## Переносит текущий указатель на следующий элемент
## result(true|false) - результат смещения указателя 
  $result($count && $_currentIndex < ($count - 1))
  ^if($result){
    ^_currentIndex.inc[]
  }
  
@foreach[aVarName;aCode;aSeparator]
## Перебирает все элементы
  ^pfAssert:isTrue(def $aVarName)[Не определено имя переменной для значения.]
  ^reset[]
  $result[] 
  ^if($count){ 
    ^while(^moveNext[]){
      $caller.$aVarName[$currentItem]
      $result[${result}$aCode^if(def $aSeparator && $currentIndex < ($count - 1)){$aSeparator}]
    }
    $caller.$aVarName[]
  }