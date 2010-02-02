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

@create[aValues;aOptions]
## Создает коллекцию. 
## aValues - таблица, хэш или коллекция, содержимое которой копируется в новую коллекцию.
## Если нам передали строку, то можно задать дополнитрельные опции:
## aOptions.separator[,] - символ-разделитель элементов списка 
## aOptions.encloser["] - символ, обрамляющий значение (внутри значения должен удваиваться)
## aOptions.ignoreWhitespaces(true) - удалить ведущие и конечные пробельные символы
## Опции импорта из таблицы:
## aOptions.type[string|hash] - если задан тип string (default), то берем значения из первого столбца таблицы,
##                              если задан тип hash, то в коллекцию попадет хеш строки таблицы.
## aOptions.key[] - имя столбца из которого берется значение, если не задано, то берем самый левый столбец.
  ^BASE:create[]
  ^cleanMethodArgument[]

  ^switch(true){
  	^case($aValues is table){
  		^_importFromTable[$aValues;$aOptions]
  	}
  	^case($aValues is hash){
  		^_importFromHash[$aValues]
  	}
  	^case($aValues is pfCollection){
  		^_importFromCollection[$aValues]
  	}
  	^case($aValues is string){
  		^_importFromString[$aValues;$aOptions]
  	}
  }

@_importFromTable[aTable;aOptions][result;lColumns;lColumnName]
## Добавляет в коллекцию данные из самого левого столбца таблицы.
  ^pfAssert:isTrue($aTable is table)[Параметр должен быть таблицей.]
  $result[]
  ^if($aTable){                   
    ^if(def $aOptions.key){
      $lColumnName[$aOptions.key]
    }{
       $lColumns[^aTable.columns[]]
       $lColumnName[$lColumns.column]
     }
    ^switch[$aOptions.type]{
      ^case[string;DEFAULT]{
        ^aTable.menu{
          ^add[$aTable.[$lColumns.column]]
        }
      }
      ^case[hash]{
        ^aTable.menu{
          ^add[$aTable.fields]
        }
      }
    }
  }

@_importFromHash[aHash][result]
## Добавляет в коллекцию данные из хэша. 
  $result[]
  ^pfAssert:isTrue($aHash is hash)[Параметр должен быть хэшем.]  
  ^if($aHash){
    ^aHash.foreach[k;v]{
   		^add[$v]
    }
  }

@_importFromCollection[aCollection][result;it]
## Добавляет коллекцию aCollection в текущую коллекцию. 
  $result[]
  ^pfAssert:isTrue($aCollection is pfCollection)[Параметр должен быть коллекцией.]
  ^if($aCollection){
    ^aCollection.foreach[it]{
   	  ^add[$it]
    }	
  } 

@_importFromString[aString;aOptions][lEncloser;lSeparator;lItem;lRegex]
## Добавляет в коллекцию данные из строки.
## aOptions.separator[,] - символ-разделитель элементов списка 
## aOptions.encloser["] - символ, обрамляющий значение (внутри значения должен удваиваться)
## aOptions.ignoreWhitespaces(true) - удалить ведущие и конечные пробельные символы  
  ^cleanMethodArgument[]
  $result[]
  ^if(def $aString){
    $lEncloser[^taint[regex][^if(def $aOptions.encloser || ($aOptions is hash && ^aOptions.contains[encloser])){$aOptions.encloser}{"}]]
    $lEncloser[^lEncloser.trim[]]
    $lSeparator[^taint[regex][^if(def $aOptions.separator){$aOptions.separator}{,}]]
    ^if(def $lEncloser){
      $lRegex[((?:\s*${lEncloser}(?:[^^${lEncloser}]*|${lEncloser}{2})*${lEncloser}\s*(?:${lSeparator}|^$))|\s*${lEncloser}[^^${lEncloser}]*${lEncloser}\s*(?:${lSeparator}|^$)|[^^${lSeparator}]+(?:${lSeparator}|^$)|(?:${lSeparator}))]
    }{
       $lRegex[([^^${lSeparator}]+(?:${lSeparator}|^$)|(?:${lSeparator}))]
    }
    ^aString.match[$lRegex][g]{
      $lItem[^match.1.trim[right;$lSeparator]]
      ^if(^aOptions.ignoreWhitespaces.bool(true)){
        $lItem[^lItem.trim[]]
      }
      ^if(def $lEncloser){
        $lItem[^lItem.match[${lEncloser}(.*)${lEncloser}][]{^match.1.match[${lEncloser}${lEncloser}][g]{${lEncloser}}}] 
      }
      ^add[$lItem]
    }
    ^if(^aString.right(1) eq $lSeparator){
#     Хак: добавляем пустой элемент в конец коллекции, если строка заканчивается сепаратором.
      ^add[]
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

@has[aString][lItem]
## Проверяет содержит ли коллекция строку aString.
  $result(false)                   
  ^reset[]
  ^if($count){
    ^while(!$result && ^moveNext[]){
      $result($currentItem is string && $currentItem eq $aString)
    }
  }

@break[]
  ^throw[pfCollection.break]

@continue[]
  ^throw[pfCollection.continue]

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
    $result[^while(^moveNext[]){^try{$caller.[$aVarName][$currentItem]$aCode^if(def $aSeparator && $currentIndex < ($count - 1)){$aSeparator}}{^if($exception.type eq "pfCollection.break"){$exception.handled(true)^break[]}^if($exception.type eq "pfCollection.continue"){$exception.handled(true)^continue[]}}}]
    $caller.[$aVarName][]
  }
  
  