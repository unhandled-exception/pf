########################################################
##
## @project inParser v. 1.0
## 
## @module  ipColorer
## @version 0.9.4
## @status  pre-release
## @title   Цветовая раскраска Парсерного синтаксиса.
##
## @author  Copyright (c) 2003-2006 by Oleg Volchkov
## @e-mail  sumo@proc.ru
## @web     http://oleg.proc.ru
##
########################################################
@CLASS
pfParserColorer

## @description
##   Класс предназначен для цветовой раскраски синтаксиса Parser.
## @/end

## @todo
##   Нефиг тут делать... :)
## @/todo

## @use
##   $pColor[^ipColorer::load[test.p]]
##   <pre>
##     ^pColor.getString[]
##   </pre>
## @/use

## @history
##   0.9.4 Добавлена подсветка команд SQL.
##   0.9.3 Проведена серьезная оптимизация кода. Скорость обработки увеличилась в два раза.
##         Спасибо Михаилу Петрушину за ценные идеи.
##   0.9.2 Добавлено отдельная обработка зарезервированных слов и коментариев inParser.
##   0.9.1 Отработана достаточно простая, но эффективная система раскраски.
## @/history

@create[aStr;aParam][lTmp]
## Конструктор класса
## @param   aStr      Строка с парсерным кодом.
## @param   aParam    Хэш с параметрами $.is_sql - раскрашиваем SQL.
  $lTmp[$aStr]
  $_str[^lTmp.normalize[]]
  ^_makeLocal[$aParam]
  ^_tokenize[]

@load[aFileName;aParam]
## Конструктор класса. 
## Производит загрузку файла и обработку полученной строки.
## @param   aFileName      Имя файла с парсерным кодом.
## @param   aParam    Хэш с параметрами $.is_sql - раскрашиваем SQL.
  $_file[^file::load[text;$aFileName]]
  $_str[^taint[html][$_file.text]]
  ^_makeLocal[$aParam]
  ^_tokenize[]


@getString[]
##@result   Возвращает преобразованную строку.
  $result[$_str]


@getTable[]
##@result   Возвращает преобразованную строку в виде таблицы [построчно].
  $result[^_str.split[^#0A][v]]


@_tokenize[][lNum;lComB;lComL]
## Собственно метод, который и раскрашивает код.
## Вызывает локальные методы для разных типов .

  $lUID[^math:uid64[]]
  
# Помечаем и "выкусываем" коментарии 
  $lComB[^_str.match[(\^^rem{ .*? })][gx]]
  ^if($lComB){
    $_str[^_str.match[\^^rem{ .*? }][gx]{/%b$lUID%/}]
  }

  $lComL[^_str.match[^^(\# .* )^$][gmx]]
  ^if($lComL){
    $_str[^_str.match[^^\# .* ^$][gmx]{/%l$lUID%/}]
  }

# HTML-теги
  $_str[^_str.match[(</? \w+\s? .*? /? >)][gx]{^_makeHTML[$match.1]}]

# Служебные конструкции
  $_str[^_str.match[^^(@ (?:BASE|USE|CLASS) )^$][gmx]{^_makeService[$match.1]}]
# Описание методов
  $_str[^_str.match[^^(@ [\w\-]+ \[ [\w^;\-]* \] (?:\[ [\w^;\-]* \])? ) (.*)^$][gmx]{^_makeMethodDefine[$match.1;$match.2]}]
# Вызов методов
  $_str[^_str.match[(\^^ [\w\-\.\:]+)][gx]{^_makeMethodCall[$match.1]}]

# Переменные
  $_str[^_str.match[(\^$ \{? [\w\-\.\:]+ \}?)][gx]{^_makeVar[$match.1]}]

# Конструкции SQL                                                                                                                                                                                                                                    
# По умолчанию не красим.
  ^if($_is_sql){
    $_str[^_str.match[(^^|\s|\^[|\{){1,1}(^_SQLWords.menu{$_SQLWords.word}[|])(?=(?:\(|,|\}|\s))][gmix]{$match.1^_makeSQL[$match.2]}]
  }

# Скобки
  $_str[^_str.match[([\[\]\{\}\(\)]+)][g]{^_makeBrackets[$match.1]}]

# Доделываем коментарии
  ^if($lComB){
     $_str[^_str.match[/%b$lUID%/][g]{^_makeComment[$lComB.1]^lComB.offset(1)}]
  }

  ^if($lComL){
     $_str[^_str.match[/%l$lUID%/][g]{^_makeComment[$lComL.1]^lComL.offset(1)}]
  }
  
##############################################################
# Обрабатываем конструкции языка...

@_makeSQL[aStr]
  $result[<font color="$_colors.SQL"><b>$aStr</b></font>]

@_makeComment[aStr]
  ^if(^aStr.left(2) eq "##"){
    $result[<font color="$_colors.inParser"><i>$aStr</i></font>]
  }{
     $result[<font color="$_colors.comment"><i>$aStr</i></font>]
   }

@_makeHTML[aStr]
  $result[<font color="$_colors.html">$aStr</font>]

@_makeService[aStr]
  $result[<font color="$_colors.service">$aStr</font>]

@_makeBrackets[aStr]
  $result[<font color="$_colors.brackets">$aStr</font>]

@_makeVar[aStr]
  ^if($aStr eq "^$result"){
    $result[<font color="$_colors.result">$aStr</font>]
  }{
    $result[<font color="$_colors.var">$aStr</font>]
   }

@_makeMethodDefine[aStr;aAdd]
  $result[<font color="$_colors.methodDefine"><b>$aStr</b></font>^_makeComment[$aAdd]]

@_makeMethodCall[aStr]
## Разделяем вызовы стандартных методов и вызовы пользовательских методов
  ^if($_reservedWords.[^aStr.mid(1)] || ^aStr.left(6) eq "^^MAIN:" || ^aStr.left(6) eq "^^BASE:"){
    $result[<font color="$_colors.reservedWord">$aStr</font>]
  }{
     $result[<font color="$_colors.methodCall">$aStr</font>]
   }


@_makeLocal[aParam]
## Определяем вспомогательные переменные класса

# Раскрашиваем ли SQL?
  ^if($aParam is hash){
    $_is_sql(^aParam.is_sql.int(0))
  }{
     $_is_sql(0)
   }

# Цвета
  $_colors[
     $.brackets[#0000AA]
     $.reservedWord[#0000AA]
     $.methodDefine[#990000]
     $.methodCall[#AA0000]
     $.html[#0077DD]
     $.service[#990000]
     $.var[#CC0000]
     $.result[#D27C00]
     $.comment[#888888]
     $.inParser[#555555]
     $.SQL[#0000CC]
  ]

# Зарезервированные слова
  $_reservedWords[
     $.if(1)
     $.switch(1)
     $.case(1)
     $.for(1)
     $.while(1)
     $.taint(1)
     $.untaint(1)
     $.try(1)
     $.throw(1)
     $.eval(1)
     $.process(1)
     $.cache(1)
     $.use(1)
     $.connect(1)
  ]

  $_SQLWords[^table::create{word
    as
    on
    in
    or
    and
    set
    select
    order\s+by
    asc
    desc
    default
    not\s+null
    from
    where
    insert\s+into
    delete
    update
    values
    drop
    create
    table
    index
    unique
    primary\s+key
    if\s+(?:not\s+)?exists
    auto_increment
    not\s+in
    order\s+by
    (?:right|left)\s+join
    distinct
    temporary
    union
    limit
    flush
    reset
    kill
    show
    explain}]
