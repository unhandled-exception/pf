# PF Library
# Copyright (c) 2006-07 Oleg Volchkov

#@module   Typografica Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

@CLASS
pfTypografica

@USE
pf/types/pfClass.p

@BASE
pfClass


#@doc
##  Класс для преобразования текста по правилом русской типографики. 
##
##  При разработке использовался следующий код:
##  --------------------
##  1. Typografica library: typografica class. v.2.6 23 February 2005. 
##     http://www.pixel-apes.com/typografica
##     Kuso Mendokusee <mailto:mendokusee@yandex.ru>
##
##  2. Исходники части проекта "Типограф"
##     http://www.typograf.ru/download/
##     Eugene Spearance (mail@spearance.ru)
##  
##  3. "Копилка регулярных выражений"
##     http://spearance.ru/parser3/regex/
##     Eugene Spearance (mail@spearance.ru)
## 
#/doc

@create[aOptions]
  ^BASE:create[]
  ^cleanMethodArgument[]
  
# Расставлять типографские кавычки
  $_processQuotes[^aOptions.processQuotes.int(1)]

# Обрабатывать специальные символы [(c), (R), +- и т.п.]
  $_processSpecial[^aOptions.processSpecial.int(1)]

  $_processSpaces[^aOptions.processSpaces.int(1)]

# regex, который игнорируется.
   $_reIgnore[(<!--notypo-->.*?<!--\/notypo-->)]
   $_ignoreMark[^math:uid64[]]  

# regex, который игнорируется.
   $_reTags[(<\/?[a-z0-9]+(?:         # имя тага
                       \s+(?:        # повторяющая конструкция: хотя бы один разделитель и тельце
                         [a-z]+(   # атрибут из букв, за которым может стоять знак равенства и потом
                                 =(?:(?:\'[^^\']*\')|(?:\"[^^\"]*\")|(?:[0-9@\-_a-z:\/?&=\.]+))
                          )?       # '

                          )?
                        )*\/?>|\xA2\xA2[^^\n]*?==)]
   $_tagsMark[^taint[regex][<:t:>]]  

   ^_makeVars[]

@process[aText;aOptions][lIgnored;lTags;lUseMarkup]
## aOptions.disableMarkup(false)
## aOptions.disableTags(false)
  ^cleanMethodArgument[]
  $lUseMarkup(!^aOptions.disableMarkup.bool(false))                                                

  ^if(^aOptions.disableTags.bool(false)){
    $result[^aText.match[$_reIgnore][gi][]]
    $result[^result.match[$_reTags][gxi][]]
  }{
#    Выкусываем из текста все куски. которые надо проигнорировать
     $lIgnored[^aText.match[$_reIgnore][gi]]
     $aText[^aText.match[$_reIgnore][gi]{$_ignoreMark}]

#    Выкусываем из текста все html-тэги.
     $lTags[^aText.match[$_reTags][gxi]]
     $result[^aText.match[$_reTags][gxi]{$_tagsMark}]
   }

# Заменяем в тексте "типографские" символы и ентити на обычные символы.
  $result[^result.replace[$_preRep]]

  ^if($_processSpaces){
#   Разбираемся с запятыми и лишними пробелами.
    $result[^result.match[[\s ]{2,}][g]{ }]
    
#   Поправляем пробелы до и после знаков препинания    
    $result[^result.match[\b(?:[\s ]*)([\.?!:^;]+)[\s ]*([a-zа-я])][gi]{$match.1 $match.2}]
    $result[^result.match[\b(?:[\s ]*)([,])][gi]{$match.1}]
    $result[^result.match[([\w\)\^]\}])[\s ]+([\.:\?!^;,])][g]{${match.1}$match.2}]

#   Вставляем пробел между числами и следующим словом
    $result[^result.match[(\b[\d]+)([a-zа-я])][gi]{$match.1 $match.2}]
    $result[^result.match[(\w)([\.?!^;:]+)([A-ZА-Я])][g]{${match.1}${match.2} $match.3}]
 
    $result[^result.match[(§|№)[\s ]*(.)][g]{${match.1} $match.2}]
    $result[^result.match[(?:(P\.)[\s ]*)?(P\.)[\s ]*(S\.)][gi]{${match.1}${match.2}${match.3}}]

#   Убираем лишние пробелы внутри скобок и кавычек.
    $result[^result.match[([\s ]|^^)(["']+)[\s ]*([A-ZА-Я])][g]{${match.1}${match.2}${match.3}}]
    $result[^result.match[([a-zа-я])[\s ]*(["']+)([\s \.,?!^;:]+)][g]{${match.1}${match.2}${match.3} }]
    
    $result[^result.match[([\(])[\s ]+][g]{$match.1}]
    $result[^result.match[(?:[\s ]+)(\))][g]{$match.1}]
  
    $result[^result.match[(\S)\((\S)][g]{$match.1 ($match.2}]
    $result[^result.match[(\S)\)([\w])][g]{$match.1) $match.2}]
  }

# Кавычки
  ^if($_processQuotes){
    $laquo[«]
    $raquo[»]
    $ldquo[„]
    $rdquo[“]

    $_preQuotePattern[\w^;\.,:\)\^]\}\?!%\^$`/">-]

    $result[^result.match[[\s ]+"([\s ]+)][g]{"$match.1}]

  	$result[^result.match[^^(\"+)][g]{^for[i](1;^match.1.length[]){$laquo}}]
   	$result[^result.match[((?:\n|^^)[\s ]*)($_tagsMark*)(\"+)][g]{${match.1}${match.2}^for[i](1;^match.3.length[]){$laquo}}]
   	$result[^result.match[(?<=[^^${_preQuotePattern}])(\"+)][g]{^for[i](1;^match.1.length[]){$laquo}}]
   	$result[^result.match[(\"+\b)][g]{^for[i](1;^match.1.length[]){$laquo}}]
   	$result[^result.match[(?<=[${_preQuotePattern}])(\"+)][g]{^for[i](1;^match.1.length[]){$raquo}}]
    $result[^result.match[${laquo}([^^${raquo}]*)((${laquo}[^^${laquo}]+?${raquo}[^^\n]*?)+?)${raquo}][g]{${laquo}${match.1}^match.2.match[${laquo}(.+?)${raquo}][g]{${ldquo}${match.1}${rdquo}}${raquo}}]
        	
    $result[^result.match[($raquo|$rdquo|\b)(\()][g]{$match.1 $match.2}]    
    $result[^result.match[(\))($laquo|$ldquo|\b)][g]{$match.1 $match.2}]    

  }
  
## СИМВОЛЫ

# Спецсимволы  
  ^if($_processSpecial){
    $result[^result.match[\.{3,}][g]{…}]
    $result[^result.match[\((?:c|с)\)][gi]{©}]
    $result[^result.match[\(r\)][gi]{®}]
    $result[^result.match[\(tm\)][gi]{™}]
    $result[^result.match[(\d+)[\s ]*(x|х)[\s ]*(\d+)][gi]{${match.1}×$match.3}]
    $result[^result.match[\b1/2\b][gi]{¹⁄₂}]
    $result[^result.match[\b1/4\b][gi]{¹⁄₄}]
    $result[^result.match[\b1/3\b][gi]{¹⁄₃}]
    $result[^result.match[(\+\-|\-\+|\+/\-)][gi]{±}]

#   Заменяем С и F в конструкциях градусов на неразрывной пробел, °C и °F соответственно
    $result[^result.match[([-+]?\d+(?:[.,]\d*)?)([CСF])\b][g]{${match.1} ˚$match.2}]
  }
  
# Заменяет двойные знаки препинания и тире на одинарные
  $result[^result.match[([\.,!?-—–])\1+][g]{$match.1}]

# Слова с дефисом                                     
  ^if($lUseMarkup){
    $result[^result.match[(?<!\-)(?=\b)(\w+)\-(\w+)(?<=\b)(?!\-)][g]{<span class="nobr">${match.1}-$match.2</span>}]
  }

# Заменяем знак тире между двумя римскими и арабскими числами на – (символ минус)
# Прогоняем два раза, чтобы правильно отработать тройные сочетания (например, телефоны)
  $result[^result.match[(\d+|[IVXL]+)-(\d+|[IVXL]+)][g]{${match.1}–$match.2}]
  $result[^result.match[(\d+|[IVXL]+)-(\d+|[IVXL]+)][g]{${match.1}–$match.2}]

# Тире
  $result[^result.match[(\s|&nbsp^;| )+\-[\s ]+][g]{ — }]

# Инициалы
  $result[^result.match[([A-ZА-Я])\.[\s ]*([A-ZА-Я])\.[\s ]*([A-ZА-Я][a-zа-я])][g]{${match.1}.${match.2}. $match.3}]
  $result[^result.match[([a-zа-я]+)[\s ]*([A-ZА-Я])\.[\s ]*([A-ZА-Я])\.][g]{${match.1} ${match.2}.${match.3}.}]


## СОКРАЩЕНИЯ
    
# Прикрепляем сокращаения
  $result[^result.match[(\s+|&nbsp^;| )(рис|табл|см|стр|илл|млн|млрд|тыс|им|ул|пер|кв|офис|оф|г|д)(\.)(?:[\s ]*)][gi]{${match.1}${match.2}${match.3} }]
  $result[^result.match[(?:[\s ]+)(руб\.|коп\.|у\.е\.|мин\.)([\s ]+|&nbsp^;| )][gi]{ ${match.1}${match.2}}]

# Заменяем сокращение и т.д., и т.п. на <nobr>и т.д.</nobr> <nobr>и т.п.</nobr>, убирая при этом лишние пробелы
  $result[^result.match[(и)[\s ]+(т)\.[\s ]*([дп])\.][gi]{<span class="nobr">${match.1} ${match.2}.${match.3}.</span>}]

# Связываем конструкцию и др. неразрывным пробелом
  $result[^result.match[(и)[\s ]+(др.)][gi]{${match.1} $match.2}]

# Заменяем сокращение в т.ч. на <nobr>в т.ч.</nobr> убирая при этом лишние пробелы
  $result[^result.match[(в)[\s ]+(т.)[\s ]?(ч.)][gi]{${match.1} ${match.2}$match.3}]

# Прикрепляем все одно-двух-трех-символьные слова к следующим (предыдущим) словам
  $result[^result.match[(?<![-:])\b([a-zа-яё]{1,3}\b(?:[,:^;\.]?))(?!\n)[\s ]][gi]{${match.1} }]
  $result[^result.match[(\s|&nbsp^;| )(же|ли|ль|бы|б|ж|ка)([\.,!\?:^;])? ][gi]{ ${match.2}$match.3 }]

# Прикрепляем слово идущее за цифрой.
  $result[^result.match[(\d)[\s ]+([\w%^$])][gi]{${match.1} $match.2}]
  
# Разбираемся с кубическими и квадратными метрами/сантиметрами.
  $result[^result.match[(?<!(?:[\s ]|\d))(см|м)(2|3)([^^\d\w])][gi]{$match.1^switch[$match.2]{^case[2]{²}^case[3]{³}}$match.3}]

# Выделяю прямую речь
  $result[^result.match[(>|\A|\n)\-\s ][g]{^taint[^#0A^#0A]${match.1}— }]

  ^if(!^aOptions.disableTags.bool(false)){
#   Вставляем обратно теги
    $result[^result.match[$_tagsMark][g]{${lTags.1}^lTags.offset(1)}]
#   Вставляем обратно куски, которые надо было игнорировать
    $result[^result.match[$_ignoreMark][g]{${lIgnored.1}^lIgnored.offset(1)}]
  }

@_makeVars[]
  $_preRep[^table::create{from	to
&thinsp^;	 
&nbsp^;	 
&ensp^;	 
&emsp^;
&#8197^;	 
&hellip^;	...
&mdash^;	-
&ndash^;	-
&laquo^;	"
&ldquo^;	"
&rdquo^;	"
&raquo^;	"
&bdquo^;	"
&quot^;	"
&lsquo^;	'
&rsquo^;	'
&sbquo^;	'
&apos^;	'
&amp^;	&
&lt^;	<
&gt^;	>
&deg^;	
&trade^;	(tm)
&reg^;	(r)
&copy^;	(c)
©	(c)
®	(r)
™	(tm)
°	
±	+-
--	-
—	-
-	-
–	-
«	"
»	"
…	...
„	"
”	"
“	"
<nobr>	
</nobr>
<NOBR>	
</NOBR>	
&#8470^;	№
&#34^;	"
&#39^;	'
&#38^;	&
&#60^;	<
&#62^;	>
&#8201^;	 
&#160^;	 
&#8194^;	 
&#8195^;	 
&#147^;	"
&#8220^;	"
&#148^;	"
&#8221^;	"
&#132^;	'
&#8222^;	'
&#145^;	'
&#8216^;	'
&#146^;	'
&#8217^;	'
&#130^;	'
&#8218^;	'
&#171^;	"
&#187^;	"
&#150^;	-
&#8211^;	-
&#151^;	-
&#8212^;	-
&#133^;	...
&#8230^;	...
&#174^;	(r)
&#169^;	(c)
&#153^;	(tm)
&#8482^;	(tm)
&#1105^;	е
&#1025^;	Е
&#167^;	§}]  
