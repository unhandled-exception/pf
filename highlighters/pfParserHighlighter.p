# PF Library

#@module   Parser Highlighter
#@author   Oleg Volchkov <oleg@volchkov.net>                                                                                                          
#@web      http://oleg.volchkov.net

# Основан на моем старом классе ParserColorer

#@doc
## Хайлайтер понимает один параметр skipSQL(0) - не обрабатывать sql-команды
#/doc

@CLASS
pfParserHighlighter

@USE
pf/highlighters/pfHighlighterBase.p

@BASE
pfHighlighterBase

#----- Constructor -----

@create[aOptions]
## aOptions.cssPrefix - префикс, который надо проставлять css-классам
  ^if(!($aOptions is hash)){$aOptions[^hash::create[]]}
  ^BASE:create[$aOptions]

  $_skipSQL(^aOptions.skipSQL.int(0))  

  ^_makeLocal[]

#----- Events -----

@onHighlight[aOptions][lNum;lComB;lComL]
## Событие, которое надо перекрывать в наследниках.
## aOptions.text - текст, который надо обработать
## aOptions.params - параметры хайлафтера
  ^if(!($aOptions is hash)){$aOptions[^hash::create[]]}
  $lUID[^math:uid64[]]
  
  $result[$aOptions.text]
# Помечаем и "выкусываем" коментарии 
  $lComB[^result.match[(\^^rem{ .*? })][gx]]
  ^if($lComB){
    $result[^result.match[\^^rem{ .*? }][gx]{/%b$lUID%/}]
  }

  $lComL[^result.match[^^(\# .* )^$][gmx]]
  ^if($lComL){
    $result[^result.match[^^\# .* ^$][gmx]{/%l$lUID%/}]
  }

# HTML-теги
  $result[^result.match[(</? \w+\s? .*? /? >)][gx]{^_makeHTML[$match.1]}]

# Служебные конструкции
  $result[^result.match[^^(@ (?:BASE|USE|CLASS) )^$][gmx]{^_makeService[$match.1]}]
# Описание методов
  $result[^result.match[^^(@ [\w\-]+ \[ [\w^;\-]* \] (?:\[ [\w^;\-]* \])? ) (.*)^$][gmx]{^_makeMethodDefine[$match.1;$match.2]}]
# Вызов методов
  $result[^result.match[(\^^ [\w\-\.\:]+)][gx]{^_makeMethodCall[$match.1]}]

# Переменные
  $result[^result.match[(\^$ \{? [\w\-\.\:]+ \}?)][gx]{^_makeVar[$match.1]}]

# Конструкции SQL                                                                                                                                                                                                                                    
# По умолчанию не красим.
  ^if(!^aOptions.skipSQL.int($_skipSQL)){
    $result[^result.match[(^^|\s|\^[|\{){1,1}(^_SQLWords.menu{$_SQLWords.word}[|])(?=(?:\(|,|\}|\s))][gmix]{$match.1^_makeSQL[$match.2]}]
  }

# Скобки
  $result[^result.match[([\[\]\{\}\(\)]+)][g]{^_makeBrackets[$match.1]}]

# Доделываем коментарии
  ^if($lComB){
     $result[^result.match[/%b$lUID%/][g]{^_makeComment[$lComB.1]^lComB.offset(1)}]
  }

  ^if($lComL){
     $result[^result.match[/%l$lUID%/][g]{^_makeComment[$lComL.1]^lComL.offset(1)}]
  }
  
  $result[<div class="code"><pre>$result</pre></div>]
  
##############################################################
# Обрабатываем конструкции языка...

@_makeSQL[aStr]
  $result[<span class="${cssPrefix}sql">$aStr</span>]

@_makeComment[aStr]
  ^if(^aStr.left(2) eq "##"){
    $result[<span class="${cssPrefix}comment ${cssPrefix}inparser">$aStr</span>]
  }{
     $result[<span class="${cssPrefix}comment">$aStr</span>]
   }

@_makeHTML[aStr]
  $result[<span class="${cssPrefix}html">$aStr</span>]

@_makeService[aStr]
  $result[<span class="${cssPrefix}service">$aStr</span>]

@_makeBrackets[aStr]
  $result[<span class="${cssPrefix}brackets">$aStr</span>]

@_makeVar[aStr]
  ^if($aStr eq "^$result"){
    $result[<span class="${cssPrefix}result">$aStr</span>]
  }{
    $result[<span class="${cssPrefix}var">$aStr</span>]
   }

@_makeMethodDefine[aStr;aAdd]
  $result[<span class="${cssPrefix}method">$aStr</span>^if(def $aAdd){^_makeComment[$aAdd]}]

@_makeMethodCall[aStr]
## Разделяем вызовы стандартных методов и вызовы пользовательских методов
  ^if($_reservedWords.[^aStr.mid(1)] || ^aStr.left(6) eq "^^MAIN:" || ^aStr.left(6) eq "^^BASE:"){
    $result[<span class="${cssPrefix}reserved">$aStr</span>]
  }{
     $result[<span class="${cssPrefix}call">$aStr</span>]
   }


@_makeLocal[]
## Определяем вспомогательные переменные класса

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
