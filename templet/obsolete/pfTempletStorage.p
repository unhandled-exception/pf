# PF Library
# Templet Engine 1.0

@CLASS
pfTempletStorage

@USE
pf/types/pfClass.p

@BASE
pfClass

## Базовая облочка для получения шаблонов - работает с файловой системой.

#----- Constructor -----

@create[aOptions]
## aOptions.path - путь к каталогу с файлами шаблонов
  ^BASE:create[]
  ^cleanMethodArgument[]

# Если путь не указан или не существует/доступен, то используем каталог 
# по-умолчанию - /../views
  $_path[^if(def $aOptions.path && -d $aOptions.path){^aOptions.path.trim[end;/]}{/../views}]

#----- Properties -----

@GET_path[]
  $result[$_path]

#----- Public -----

@getTemplate[aName;aOptions][lFile]
## Возвращает текст шаблона.
## Шаблон берем из файла и считаем его безопасным
  ^pfAssert:isTrue(^isTemplateExists[$aName])[Файл "$path/$aName" не найден.]
  $lFile[^file::load[text;$path/$aName]]
  $result[^taint[as-is][$lFile.text]]

@isTemplateExists[aName]
## Проверяет есть ли шаблон 
  $result(-f "$path/$aName")
