# PF Library

#@module   Highlighters Manager
#@author   Oleg Volchkov <oleg@volchkov.net>                                                                                                          
#@web      http://oleg.volchkov.net

@CLASS
pfHighlightersManager

@USE
pf/modules/pfModule.p

@BASE
pfModule

@create[aOptions]
## Инициализируем базовые хайлайтеры
  ^if(!($aOptions is hash)){$aOptions[^hash::create[]]}
  ^BASE:create[$aOptions]

  $_cssPrefix[$aOptions.cssPrefix]

# Добавляем известные нам хайлайтеры

# Parser Highliter (ну куда же без него :)
  ^assignModule[parser;
      $.class[pfParserHighlighter]
      $.file[pf/highlighters/pfParserHighlighter.p]
      $.args[
        $.cssPrefix[$_cssPrefix]
      ]
  ]
  
@onDEFAULT[aOptions]
## По-умолчанию возвращает текст, заключенный в теги <pre>
  ^if(!($aOptions is hash)){$aOptions[^hash::create[]]}
  $result[<pre>$aOptions.text</pre>]

@process[aHighlighterName;aText;aOptions]
## Запускает процесс обработки хайлайтеров
  ^if(!($aOptions is hash)){$aOptions[^hash::create[]]}

  ^dispatch[$aHighlighterName/highlight][
     $.text[$aText]
     $.params[$aOptions]
  ]



