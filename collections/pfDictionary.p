# PF Library

#@module   Dictionary Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

## Коллекция-словарь. (Упорядоченный хэш.)
## По сути обычный хэш, но с возможностью перебора значений "в порядке добавления".

@CLASS
pfDictionary

@USE
pf/collections/pfCollection.p

@BASE
pfCollection

#----- Constructor -----

@create[aValues;aOptions]
## Создает коллекцию. 
## aValues - хэш (и только!), содержимое которго копируется в новую коллекцию.
##           Значения ключей копируются в лексикографическом порядке.
  ^pfAssert:isTrue(!def $aValues || ($aValues is hash))[В словарь может быть преобразован только хэш.]
  ^clear[]
  ^reset[]
  ^BASE:create[$aValues;$aOptions]

@clear[]
## Удаляет все элементы из коллекции
  $_dict[^hash::create[]]
  $_keys[^table::create{key}]
  ^reset[]

#----- Properties -----

@GET_DEFAULT[aKey]
  $result[^by[$aKey]]
  
@GET_count[]
## Возвращает количество элементов в коллекции.
  $result($_keys)

@GET_keys[]
## Возарщает таблицу (столбец key) со всеми ключами словаря.
  $result[$_keys]

#----- Public -----

@contains[aKey]
## Проверяет есть ли ключ aKey в словаре
  $result(^_dict.contains[$aKey])

@by[aKey]
## Возвращает значение для aKey.
  ^pfAssert:isTrue(^contains[$aKey])[Элемент с ключем "$aKey" в коллекции не найден.]
  $result[$_dict.[$aKey]]

@add[aKey;aValue]
## Добавляет элемент в словарь. 
## Если элемент с ключем aKey есть в словаре, то заменяем его значение.
  ^pfAssert:isTrue(def $aKey)[Не задан ключ.]
  ^pfAssert:isTrue($aKey is string || $aKey is int || $aKey is double)[Ключ может быть только строкой или числом.]
  ^if(!^contains[$aKey]){
     ^_keys.append{$aKey}
  }
  $_dict.[$aKey][$aValue]
  $result[]
  ^reset[]

@delete[aKey]
## Удаляет из коллекции ключ
  ^pfAssert:isTrue(^contains[$aKey])[Элемент с ключем "$aKey" в коллекции не найден.]
   ^if(^contains[$aKey]){
     ^_dict.delete[$aKey]
     $_keys[^_keys.select($_keys.key ne $aKey)]
   }
  $result[]
  ^reset[]

@reverse[]
## Меняет порядок элементов коллекции на обратный
  $_keys[^table::create[$_keys;$.reverse(1)]]
  ^reset[]

@has[aString][lItem]
## Проверяет содержит ли значения словаря строку aString.
  $result(false)                   
  ^reset[]
  ^if($count){
    ^while(!$result && ^moveNext[]){
      $result($currentItem.value is string && $currentItem.value eq $aString)
    }
  }

@asHash[]
## Возвращает коллекцию в виде хеша.
  $result[^hash::create[$_dict]]

#----- Iterator's -----

@GET_currentItem[][lKeys]
## Текущий элемент коллекции c порядкоовым номером $currentIndex
  ^pfAssert:isTrue($count > 0)[Коллекция пустая.]
   $lKeys[$keys]
   ^lKeys.offset[set]($_currentIndex)
   $result[$.key[$lKeys.key] $.value[^by[$lKeys.key]]]

#----- Private -----

@_importFromHash[aHash][lKeys]
## Добавляет в коллекцию данные из хэша. 
  ^pfAssert:isTrue($aHash is hash)[Параметр должен быть хэшем.]
  ^if($aHash){
    $lKeys[^aHash._keys[]]
    ^lKeys.sort{$lKeys.key}[asc]
    ^lKeys.menu{
      ^add[$lKeys.key;$aHash.[$lKeys.key]]
    }
  }  
