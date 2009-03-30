@USE
pf/types/pfClass.p
pf/types/pfString.p
pf/collections/pfDictionary.p
pf/collections/pfArrayList.p

pf/web/forms/pfFormFields.p
pf/web/forms/pfFormBoundField.p

@CLASS
pfForm

@BASE
pfClass

@create[aOptions]
## Конструктор
## aOptions.data[] - хеш с данными для полей формы
## aoptions.initial[] - начальные значения полей формы (используется, если не определен $.data)
## aOptions.prefix[] - префикс для названий полей формы
## aOptions.autoID[id_] - префикс для id полей формы
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(!def $aOptions.data || $aOptions.data is hash)[Параметр data должен быть хешем.]
  ^pfAssert:isTrue(!def $aOptions.initial || $aOptions.initial is hash)[Параметр initial должен быть хешем.]

# Словарь с полями формы
  $_fields[^pfDictionary::create[]]

# Словарь с ошибками формы
  $_errors[^pfDictionary::create[]]

  $_initial[$aOptions.initial]
  $_data[$aOptions.data]
  $_prefix[$aOptions.prefix]
  $_autoID[^if(def $aOptions.autoID){$aOptions.autoID}{id_}]
  
  $_labelSuffix[^if(def $aOptions.labelSuffix){$aOptions.labelSuffix}{:}]
  
  $_isBound(false)
  
#   ^defineFields[$aOptions]
#   
# @defineFields[aOptions]
# ## Перекрывать лучше именно этот метод, а не конструктор.
  
#----- Properties -----

@GET_fields[]
  $result[$_fields]

@GET_errors[]
  $result[$_errors]

@GET_cleanedData[]
  ^pfAssert:fail[Не реализовано.]

@GET_isBound[]
## Заполнена ли форма значениями?
  $result($_isBound)
 
@GET_isValid[]
## Правильная ли форма?
  ^pfAssert:fail[Не реализовано.]

#----- Public -----

@field[aName;aField]
## Добавляем поле в форму и создаем свойство с именем fFieldname.
  ^pfAssert:isTrue($aField is pfFormBaseField)[Новое поле не является потомком класса pfFormBaseField.]
  ^pfAssert:isTrue(def $aName)[Не определено имя поля.]
  ^pfAssert:isFalse(^fields.contains[$aName])[Поле с именем $aName уже существует.]
  ^fields.add[$aName;$aField]

@getField[aFieldName]
  ^pfAssert:isTrue(def $aFieldName && ^fields.contains[$aFieldName])[Поля "$aFieldName" в форме нет.]
  $result[^fields.by[$aFieldName]]  

@hasField[aFieldName]
  $result(^fields.contains[$aFieldName])

@asTable[]
## Возвращает текущую форму в виде HTML-тегов <tr>. Без тегов <table>. 
  ^pfAssert:fail[Не реализовано.]

@asUl[]
## Возвращает текущую форму в виде HTML-тегов <li>. Без тегов <ul>. 
  $result[^_htmlOutput[<li>%(errors)s%(label)s %(field)s%(help_text)s</li>;<li>%s</li>;</li>;' %s';0]]

@asP[]
## Возвращает текущую форму в виде HTML-тегов <p>. 
  ^pfAssert:fail[Не реализовано.]

@addPrefix[aFieldName]
  $result[^if(def $_prefix){${_prefix}-$aFieldName}{$aFieldName}]

    

#----- Private -----

# @_createPropertyForField[aFieldName]
#   ^pfAssert:isTrue(^hasField[$aFieldName])[Поля с именем "$aFieldName" нет в форме.]
#   ^process{^$result[^^getField[$aFieldName]]}[$.main[GET_^_makeFieldPropertyName[$aFieldName]]]

@_makeFieldPropertyName[aFieldName]
  $result[f^aStr.match[(.)(.*)][]{^match.1.upper[]^match.2.lower[]}]

@_htmlOutput[aNormalRow;aErrorRow;aRowEnder;aHelpTextHTML;aErrorsOnSeparateRow][lHiddenFields;lVisibleFields;lBF]
## Выводит форму в виде HTML'я.
  $lHiddenFields[^pfArrayList::create[]]
  $lVisibleFields[^pfArrayList::create[]]
  ^fields.foreach[it]{
    $lBF[^pfFormBoundField::create[$self;$it.value;$it.key]]
    ^if($it.value.isHidden){
    }{ 
#     ^throw[stop;$aNormalRow]
        ^pfString:format[$aNormalRow][
          $.label[^lBF.labelTag[$lBF.label^if(^lBF.label.right(1) ne $_labelSuffix){$_labelSuffix}]]
          $.field[^lBF.asHTML[]]
        ]
     }
  }
  

   

            