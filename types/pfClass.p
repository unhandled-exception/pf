# PF Library

## Базовый предок большинства классов PF

@CLASS
pfClass

@USE
pf/tests/pfAssert.p

#----- Constructor -----

@create[aOptions]
## Empty constructor
  $result[]

@auto[aFilespec]
  $[__PFROOT__][^aFilespec.match[^^(?:^taint[regex][$request:document-root])(.*?)(/types/pfClass.p)^$][]{$match.1}]
  
#----- Properties -----

@GET_isDynamic[]
## Возвращает true, если класс создан динамически
  $result(^reflection:dynamical[])
  
@GET_isStatic[]  
## Возвращает true, если класс создан статически
  $result(!^reflection:dynamical[])

#----- Public -----

@cleanMethodArgument[aName]
## Метод проверяет пришел ли вызывающему методу
## параметр с именем $aName[aOptions].
## Если пришел пустой параметр или строка, то записываем в него пустой хеш.
  ^if(!def $aName){$aName[aOptions]}
  ^if(!def $caller.[$aName] || ($caller.[$aName] is string && !def ^caller.[$aName].trim[])){$caller.[$aName][^hash::create[]]}
  $result[]
  
@defProperty[aPropertyName;aVarName;aType][lVarName]
## Добавляет в объект свойство с именем aPropertyName
## ссылающееся на переменную $aVarName[_$aPropertyName].
## aType[read] - тип свойства (read|full: только для чтения|чтение/запись)
  ^pfAssert:isTrue(def $aPropertyName)[Не определено имя свойства]
  $lVarName[^if(def $aVarName){$aVarName}{_$aPropertyName}]

  ^process[$self]{@GET_$aPropertyName^[^]
    ^^switch[^$self.[$lVarName].CLASS_NAME]{
      ^^case[bool^;int^;double]{^$result(^$self.[$lVarName])}
      ^^case[DEFAULT]{^$result[^$self.[$lVarName]]}
    }
  }

  ^if($aType eq "full"){
    ^process[$self]{@SET_$aPropertyName^[aValue^]
      ^^switch[^$self.[$lVarName].CLASS_NAME]{
        ^^case[bool^;int^;double]{^$self.[$lVarName](^$aValue)}
        ^^case[DEFAULT]{^$self.[$lVarName][^$aValue]}
      }
    }
  }
  $result[]

@defReadProperty[aPropertyName;aVarName]
# Добавляет свойство только для чтения.
  ^defProperty[$aPropertyName;$aVarName]
  $result[]

@defReadWriteProperty[aPropertyName;aVarName]
# Добавляет свойство для чтения/записи.
  ^defProperty[$aPropertyName;$aVarName;full]
  $result[]

@equals[aObject]
## Возвращает true, если текущий объект равен aObject.
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

@int[aDefault]
## Перобразует объект в int.
  $result(^unsafe{^GET[int]}{^if(def $aDefault){$aDefault}{^throw[$CLASS_NAME;Невозможно преобразовать объект класса $CLASS_NAME в int.]}})

@double[aDefault]
## Перобразует объект в double.
  $result(^unsafe{^GET[double]}{^if(def $aDefault){$aDefault}{^throw[$CLASS_NAME;Невозможно преобразовать объект класса $CLASS_NAME в double.]}})

@bool[aDefault]
## Перобразует объект в bool.
  $result(^unsafe{^GET[bool]}{^if(def $aDefault){$aDefault}{^throw[$CLASS_NAME;Невозможно преобразовать объект класса $CLASS_NAME в bool.]}})

@contains[aName][lFields]
## Проверяет есть ли у объекта поле с именем aName.
  $lFields[^reflection:fields[^if(^reflection:dynamical[]){$self}{$CLASS}]]
  $result(^lFields.contains[$aName])

@foreach[aKeyName;aValueName;aCode;aSeparator][lFields;lKey;lValue]
## Обходит все поля объекта.
  $lFields[^reflection:fields[^if(^reflection:dynamical[]){$self}{$CLASS}]]
  $result[^lFields.foreach[lKey;lValue]{$caller.[$aKeyName][$lKey]$caller.[$aValueName][$lValue]$aCode}[$aSeparator]] 

@alias[aName;aMethod]
## Создает алиас для метода.
  ^pfAssert:isTrue($aMethod is junction)[Переменная aMethod должна содержать ссылку на функцию.]
  $self.[$aName][$aMethod]
  $result[]

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

@unless[aCond;aFalseCode;aTrueCode]
## if наоборот.
  $result[^if(!$aCond){$aFalseCode}{$aTrueCode}]

#----- Private -----

@_abstractMethod[]
  ^pfAssert:fail[Не реализовано. Вызов абстрактного метода.]

#----- Serialize -----

## Подробности в файле pf/TECHNOTES

#@__asString[]
#@__fromString[aString]
#@__asXML[aOptions]
#@__fromXML[aXML;aOptions]
 