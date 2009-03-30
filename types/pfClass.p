# PF Library
# Copyright (c) 2006-07 Oleg Volchkov

#@module   Super Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

## Базовый предок большинства классов Parser Framework

@CLASS
pfClass

@USE
pf/tests/pfAssert.p

#----- Constructor -----

@create[]
  $_isSerializable(false)
  ^defReadProperty[isSerializable]

#----- Public -----

@cleanMethodArgument[aName]
## Метод проверяет пришел ли вызывающему методу
## параметр с именем $aName[aOptions].
## Если пришел пустой параметр, то записываем в него пустой хеш. 
  ^if(!def $aName){$aName[aOptions]}
  ^if(!def $caller.[$aName]){$caller.[$aName][^hash::create[]]}

@defProperty[aPropertyName;aVarName;aType]
## Добавляет в класс свойство с именем aPropertyName
## ссылающееся на переменную $aVarName[_$aPropertyName].
## aType[read] - тип свойства (read|full: только для чтения|чтение/запись)
  ^pfAssert:isTrue(def $aPropertyName)[Не определено имя свойства]

  ^process{^$result[^$^if(def $aVarName){$aVarName}{_$aPropertyName}]}[$.main[GET_$aPropertyName]]
  ^if($aType eq "full"){
    ^process[$CLASS]{@SET_$aPropertyName^[aValue^]
                       ^$^if(def $aVarName){$aVarName}{_$aPropertyName}^[^$aValue^]
    }
  }

@defReadProperty[aPropertyName;aVarName]
# Добавляет свойтво только для чтения.
  ^defProperty[$aPropertyName;$aVarName]

@defReadWriteProperty[aPropertyName;aVarName]
# Добавляет свойтво для чтения/записи.
  ^defProperty[$aPropertyName;$aVarName;full]

@equals[aObject]
## Возвращает true, если текущий объект равен aObject.
  $result(false)
  
@serialize[]
## Преобразует состояние объекта (переменные) в строку
  $result[]

@deserialize[aString]
## Восстанавливает состояние объекта (переменные) из строки
## Возвращает true, если удалось преобразовать.
  $result(false)
  
@typeOf[aValue][lDone]
## Возвращает строку с типом переменной aValue
  ^unsafe{
    ^if(def $aValue.CLASS_NAME){
      $result[$aValue.CLASS_NAME]
    }
  }
  
  ^if(!def $result){
	  $result[^switch(true){
      ^case($aValue is "string"){string}
      ^case($aValue is "int"){int}
      ^case($aValue is "double"){double}
      ^case($aValue is "date"){date}
      ^case($aValue is "hash"){hash}
      ^case($aValue is "table"){table}
      ^case($aValue is "bool"){bool}
      ^case($aValue is "image"){image}
      ^case($aValue is "file"){file}
      ^case($aValue is "xnode"){xnode}
      ^case($aValue is "xdoc"){xdoc}
      ^case($aValue is "pfClass"){pfClass}
      ^case[DEFAULT]{}
    }]
  }

@try-finally[aCode;aCatchCode;aFinallyCode][lFinallyProcessed]
## Оператор try-catch-finally. Гарантированно выполняет блок 
## finally даже если в коде или обработчике ошибок произошло исключение.
## Блок finally можно опустить.
  $lFinallyProcessed(false)
  $result[^try{^try{$aCode}{$aCatchCode}}{$lFinallyProcessed(true)$aFinallyCode}^if(!$lFinallyProcessed){$aFinallyCode}]  

@unsafe[aCode;aCatchCode]
## Выполняет код и принудительно обрабатывает все exceptions.
## В случае ошибки может дополнительно выполнить aCatchCode.
  $result[^try{$aCode}{$exception.handled(true)$aCatchCode}]

#----- Private -----

@_abstractMethod[]
  ^pfAssert:fail[Не реализовано. Вызов абстрактного метода.]


