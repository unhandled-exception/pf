# PF Library
# Copyright (c) 2005-07 Oleg Volchkov

#@module   Wiki Formatter
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

@CLASS
pfWikiFormatter

#@doc
##  Основан на:
##  --------------------
##  WackoFormatter.
##  v2.1.1.
##  26 October 2004.
##  ---------
##  http://wackowiki.com/projects/wackoformatter
##  Copyright (c) WackoWiki team ( http://wackowiki.com/team/ ), 2003-2004
##  All rights reserved.
##  Maintainer -- Roman Ivanov <thingol@mail.ru>
#/doc

@USE
pf/types/pfClass.p
pf/collections/pfStack.p

@BASE
pfClass

@create[aOptions]
## Создаем класс и инициализируем переменные
## aOptions.highlighters - менеджер хайлайтеров (если не задан, то используем базовый)
## aOptions.rawhtml

  ^BASE:create[]
  ^cleanMethodArgument[]

  ^if(def $aOptions.highlighters && $aOptions.highlighters is pfHighlightersManager){
    $_highlighters[$aOptions.highlighters]
  }{
     ^use[pf/highlighters/pfHighlightersManager.p]
  	 $_highlighters[^pfHighlightersManager::create[]]
   }

  $_options[
    $.allow_rawhtml(^aOptions.allow_rawhtml.int(0))
    $.disable_formatters(^aOptions.disableFormatters.int(0))
    $.disable_bracketslinks(^aOptions.disableBracketslinks.int(0))
    $.disable_tikilinks(^aOptions.disableTikilinks.int(1))
    $.disable_wikilinks(^aOptions.disableWikilinks.int(1))
    $.disable_npjlinks(^aOptions.disableNpjlinks.int(1))
  ]

  $_headerCount(0)
  $_z_gif[&nbsp^;]
  $_intable(0)
  $_intablebr(0)
  $_cols(0)
  $_tableScope(0)
  
  $_oldIndentLevel(0)
  $_oldIndentType[]
  $_indentClosers[^pfStack::create[]]
  
  $_tdOldIndentLevel(0)
  $_tdOldIndentType[]
  $_tdIndentClosers[^pfStack::create[]]
  
  ^_initializeConst[]

@_initializeConst[]
# Символьные кдассы для регулярных выражений
  $UPPER[[A-Z\xc0-\xdf\xa8]]
  $UPPERNUM[[0-9A-Z\xc0-\xdf\xa8]]
  $LOWER[[a-z\xe0-\xff\xb8\/\-]]
  $ALPHA[[A-Za-z\xc0-\xff\xa8\xb8\_\-\/]]
  $ALPHA_L[[A-Za-z\xc0-\xff\xa8\xb8]]
  $ALPHANUM[[0-9A-Za-z\xc0-\xff\xa8\xb8\_\-\/]]
  $ALPHANUM_L[[0-9A-Za-z\xc0-\xff\xa8\xb8\-]]
  $ALPHANUM_P[0-9A-Za-z\xc0-\xff\xa8\xb8\_\-\/]
  
# Регулярные выражения
  $NOTLONGREGEXP[
    (
      ^if(!$_options.disable_formatters){\%\%.*?\%\%|}
      ~([^^ \t\n]+)|
      \"\".*?\"\"|
      \{\{[^^\n]*?\}\}|
      \xa5\xa5.*?\xa5\xa5
    )
  ]
  $MOREREGEXP[
    (
      >>.*?<<|
      ~([^^ \t\n]+)|
      \xa5\xa5.*?\xa5\xa5
    )
  ]

  $LONGREGEXP[
    (
      \xa5\xa5.*?\xa5\xa5|
     
      ^if($_options.allow_rawhtml){
        \<\#.*?\#\>|
      }
     
      \(\?(\S+?)([ \t]+([^^\n]+?))?\?\)|
     
      ^if(!$_options.disable_bracketslinks){
        \[\[(\S+?)([ \t]+([^^\n]+?))?\]\]|
        \(\((\S+?)([ \t]+([^^\n]+?))?\)\)|
      }
     
      \^^\^^\S*?\^^\^^|vv\S*?vv|
      \n[ \t]*>+[^^\n]*|
      <\[.*?\]>|
      \+\+[^^\n]*?\+\+|
      \b[a-zA-Z]+:\/\/\S+|
      mailto\:[a-zA-Z0-9\-\_\.]+\@[a-zA-Z0-9\-\_\.]+|
      \?\?\S\?\?|\?\?(\S.*?\S)\?\?|
      \\\\\\\\[$ALPHANUM_P\-\_\\\!\.]+|
      \*\*[^^\n]*?\*\*|\#\#[^^\n]*?\#\#|\'\'.*?\'\'|
      \!\!\S\!\!|\!\!(\S.*?\S)\!\!|__[^^\n]*?__|
      \xA4\xA4\S\xA4\xA4|\xA3\xA3\S\xA3\xA3|\xA4\xA4(\S.*?\S)\xA4\xA4|\xA3\xA3(\S.*?\S)\xA3\xA3|
      \#\|\||\#\||\|\|\#|\|\#|\|\|.*?\|\||
      <|>|
      \/\/[^^\n]*?(?<!http:|https:|ftp:|ftps:|file:|nntp:)\/\/|
      (?:^^|\n)\s*={2,7}.*?={2,7}|
      [-]{4,}|---\n?\s*|--\S--|--(\S.*?[^^- \t\n\r])--|
      (?:^^|\n)(\t+|([ ]{2})+)(-|\*|[0-9,a-z,A-Z]{1,2}[\.\)](\#[0-9]{1,3})?)?|
      \b[a-zA-Z0-9]+[:][$ALPHANUM_P\!\.][$ALPHANUM_P\-\_\.\+\&\=]+|
      ~([^^ \t\n]+)|

      ^if(!$_optionsdisable_tikilinks){
         \b(${UPPER}${LOWER}${ALPHANUM}*\.${ALPHA}${ALPHANUM}+)\b|
      }
      
      ^if(!$_options.disable_wikilinks){
        (~?)(?<=[^^\.$ALPHANUM_P]|^^)(((\.\.|!)?\/)?${UPPER}${LOWER}+${UPPER}${ALPHANUM}*)\b|
      }

      ^if(!$_options.disable_npjlinks){
        (~?)$ALPHANUM_L+\@$ALPHA_L*(?!$ALPHANUM*\.$ALPHANUM+)(\:$ALPHANUM*)?|$ALPHANUM_L+\:\:$ALPHANUM+|
      }
      \n
   )
  ]

#---- Properties ----

@GET_highlighters[]
  $result[$_highlighters]

#---- Public ----

@process[aStr;aOptions][text;wtext;texts;wtexts;i;opens;closes]
  ^cleanMethodArgument[]

# Запрещаем теги для всего текста (может быть отменено с использованием rawhtml)
  $text[^taint[xml][$aStr]]

# Удаляем перевод строки (\r)
  $text[^text.replace[^table::create[nameless]{^taint[^#0D]	}]]

# Первый проход. Короткое выражение
  $text[^text.match[$NOTLONGREGEXP][gxs]{^_preProcess[$match]}]

# Выкусываем все, что обработано _preProcess'ом
  $texts[^text.split[^#a5^#a5]]
  $wtext[$texts.piece]
  $i(2)
  ^while($i < $texts){
  	^texts.offset[set]($i)
    $wtext[${wtext}^#a6$texts.piece]
    ^i.inc(2)
  }
  
## Второй проход.
  $wtext[^wtext.match[$MOREREGEXP][gxs]{^_middleProcess[$match]}]

## Третий проход
  $wtext[^wtext.match[$LONGREGEXP][gxs]{^_callback[$match]}]

## Завершающий проход
  $text[^postFormat[$text]]

# Вставляем все, что выкушено _preProcess'ом 
  $wtexts[^wtext.split[^#a6]]
  $text[ ]
  ^wtexts.menu{
  		 ^texts.offset[set](^wtexts.offset[]*2+1)
       $text[${text}${wtexts.piece}^if(^texts.offset[] > 0){$texts.piece}]
  }
    
   $text[^text.replace[^table::create[nameless]{^#b1<br />^taint[^#0A]	
^#b1	}]]
  
#  we're cutting the last <br />
   $text[^text.match[<br \/>^$][]{}]

   $text[${text}^_indentClose[]]

#  close all open tables
   $opens[^text.match[<table][g]]
   $closes[^text.match[</table][g]]
   ^if($opens > $closes){
     ^for[i](0;$opens-$closes){
      	$text[$text</table>]
     }	
   }
 
  $result[$text]

@postFormat[aStr]
  $result[^aStr.match[(\xa2\xa2(\S+?)([^^\n]*?)==([^^\n]*?)\xaf\xaf|\xa1\xa1[^^\n]+?\xa1\xa1)][gm]{^_postCallback[$match]}]

#-------- Процессоры ----------

@_preProcess[aThings][isReturn;thing]
  $isReturn(0)
  $thing[$aThings.1]
  ^if(^thing.mid(0;1) eq "~"){
  	^if(^thing.mid(1;1) eq "~"){
  		$result[~~^_preProcess[$.1[0] $.2[^thing.mid(2)]]]
  		$isReturn(1)
  	}
  }

# escaped text
  ^if(!$isReturn){
    ^thing.match[^^\xa5\xa5(.*)\xa5\xa5^$][]{
    	$result[$match.1]
      $isReturn(1)	
    }	
  } 

# escaped text
  ^if(!$isReturn){
    ^thing.match[^^\"\"(.*)\"\"^$][]{
    	$result[^#a5^#a5<!--notypo-->^match.1.replace[^table::create[nameless]{^taint[^#0A]	<br />}]<!--/notypo-->^#a5^#a5]
      $isReturn(1)	
    }	
  } 
  
# code text
  ^if(!$isReturn){
    ^thing.match[^^\%\%(?:\(([^^\n\s]+?)\))?(.*)\%\%^$][]{
    	$result[^#a5^#a5^highlighters.process[$match.1;^taint[html][$match.2]]^#a5^#a5]
      $isReturn(1)	
    }	
  } 

# actions
  ^if(!$isReturn){
    ^thing.match[^^\{\{(.*?)\}\}^$][]{
    	$result[^#a5^#a5^wrapAction[$match.1]^#a5^#a5]
      $isReturn(1)	
    }	
  } 

  ^if(!$isReturn){
  	$result[$thing]
  }  
 

@_middleProcess[aThings][isReturn;thing]
  $isReturn(0)
  $thing[$aThings.1]
  ^if(^thing.mid(0;1) eq "~"){
  	^if(^thing.mid(1;1) eq "~"){
  		$result[~~^_middleProcess[$.1[0] $.2[^thing.mid(2)]]]
  		$isReturn(1)
  	}
  }

# escaped text
  ^if(!$isReturn){
    ^thing.match[^^\xa5\xa5(.*)\xa5\xa5^$][]{
    	$result[$match.1]
      $isReturn(1)	
    }	
  } 

# centered text
  ^if(!$isReturn){
    ^thing.match[^^>>(.*)<<^$][]{
    	$result[^#a5^#a5<div class="center">^match.1.match[$LONGREGEXP][gxs]{^_callback[$match]}</div>^#a5^#a5]
      $isReturn(1)	
    }	
  } 

  ^if(!$isReturn){
  	$result[$thing]
  }  
  
@_callback[aThings][isReturn;thing;url;ext;matches;sup;url;anchor;ahref;oldLevel;oldType;s]
  $isReturn(0)
  $thing[$aThings.1]

# escaped text
  ^if(!$isReturn){
    ^thing.match[^^\xa5\xa5(.*)\xa5\xa5^$][]{
    	$result[$match.1]
      $isReturn(1)	
    }	
  } 

# escaped html
  ^if(!$isReturn){
    ^thing.match[^^\<\#(.*)\#\>^$][]{
#     А здесь нам ничего дополнительно форматить не надо, поскольку Парсер 
#     и так разберется, что у нас грязное, а что нет
    	$result[<!--notypo-->^taint[as-is][$match.1]<!--/notypo-->]
      $isReturn(1)	
    }	
  } 

# Table begin
  ^if(!$isReturn && $thing eq "#||"){
    $_br(0)
    $_cols(0)
    $_intablebr(1)
    $_tableScope(1)
    $result[<table class="dtable" border="0">]
    $isReturn(1)
  }

  ^if(!$isReturn && $thing eq "#|"){
    $_br(0)
    $_cols(0)
    $_intablebr(1)
    $_tableScope(1)
    $result[<table class="usertable" border="0">]
    $isReturn(1)
  }

# Table end
  ^if(!$isReturn && ($thing eq "|#" || $thing eq "||#") && $_tableScope){
    $_br(0)
    $_intablebr(0)
    $_tableScope(0)
    $result[</table>]
    $isReturn(1)
  }

  ^if(!$isReturn){
    ^thing.match[^^\|\|(.*?)\|\|^$][]{
    	$_br(1)
    	$_intable(1)
    	$_intablebr(0)

    	$result[<tr class="userrow">]
    	$cells[^match.1.split[|;lv]]
    	
    	^if($cells){
      	^cells.menu{
    	  	$_tdOldIndentLevel(0)
    		  $_tdIndentClosers[^pfStack::create[]]
    		  ^if(^cells.piece.mid(0;1) eq "^#0A"){
    			  $scells[^cells.piece.mid(1)]
    		  }{
    		  	 $scells[$cells.piece]
    		   }
    		  $s[^#B1^#0A$scells]
    		  $s[<td class="usercell" ^if(^cells.line[] == ^cells.count[] && $_cols != 0 && $cells < $_cols){colspan="^eval($_cols-$cells+1)"}>^s.match[$LONGREGEXP][gxs]{^_callback[$match]}]
    		  $s[^s.replace[^table::create[nameless]{^#B1<br />^taint[^#0A]	
^#B1	}]]
    		  
    	    $result[${result}$s]
    	    $result[${result}^_indentClose[]]
    	    $result[${result}</td>]
    	  }
    	}
      
    	$result[$result</tr>]
    	
    	^if($_cols == 0){$_cols($cells)}
    	
    	$_intablebr(1)
    	$_intable(0)
    	
    	$isReturn(1)
    }
  }  
  
# Deleted
  ^if(!$isReturn){
    ^thing.match[^^\xA4\xA4((\S.*?\S)|(\S))\xA4\xA4^$][]{
    	$result[<span class="del">^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</span>]
      $isReturn(1)	
    }	
  } 
  
# Inserted
  ^if(!$isReturn){
    ^thing.match[^^\xA3\xA3((\S.*?\S)|(\S))\xA3\xA3^$][]{
    	$result[<span class="add">^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</span>]
      $isReturn(1)	
    }	
  } 

# Bold
  ^if(!$isReturn){
    ^thing.match[^^\*\*(.*?)\*\*^$][]{
    	$result[<strong>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</strong>]
      $isReturn(1)	
    }	
  } 

# Italic
  ^if(!$isReturn){
    ^thing.match[^^\/\/(.*?)\/\/^$][]{
    	$result[<em>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</em>]
      $isReturn(1)	
    }	
  } 

# Underline
  ^if(!$isReturn){
    ^thing.match[^^__(.*?)__^$][]{
    	$result[<u>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</u>]
      $isReturn(1)	
    }	
  } 

# Monospace
  ^if(!$isReturn){
    ^thing.match[^^\#\#(.*?)\#\#^$][]{
    	$result[<tt>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</tt>]
      $isReturn(1)	
    }	
  } 

# Small
  ^if(!$isReturn){
    ^thing.match[^^\+\+(.*?)\+\+^$][]{
    	$result[<small>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</small>]
      $isReturn(1)	
    }	
  } 

# Cite
  ^if(!$isReturn){
    ^thing.match[^^\'\'(.*?)\'\'^$][]{
    	$_br(1)
    	$result[<span class="cite">^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</span>]
      $isReturn(1)	
    }	
    ^if(!$isReturn){
    	^thing.match[^^\!\!((\S.*?\S)|(\S))\!\!^$][]{
    		$_br(1)
    	  $result[<span class="cite">^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</span>]
        $isReturn(1)	
      }
    }	
  } 

  ^if(!$isReturn){
    ^thing.match[^^\?\?((\S.*?\S)|(\S))\?\?^$][]{
    	$_br(1)
    	$result[<span class="mark">^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</span>]
      $isReturn(1)	
    }	
  } 

# Urls
  ^if(!$isReturn){
    ^thing.match[^^([a-zA-Z]+:\/\/\S+?|mailto\:[a-zA-Z0-9\-\_\.]+\@[a-zA-Z0-9\-\.\_]+?)([^^a-zA-Z0-9^^\/\-\_\=]?)^$][]{
    	$url[^match.1.lower[]]
    	^if(^url.right(4)eq ".jpg"
    	    || ^url.right(4) eq ".gif"
    	    || ^url.right(4) eq ".png"
    	    || ^url.right(4) eq ".jpe"
    	    || ^url.right(5) eq ".jpeg"
    	   ){
    		    $result[<img src="$match.1" />]
          }{
    	       $result[^_preLink[$match.1;^match.1.match[^^mailto:(.+)][i]{$match.1}]$match.2]]
    	     }
      $isReturn(1)	
    }	
  } 

# Lan path
  ^if(!$isReturn){
    ^thing.match[^^\\\\\\\\([${ALPHANUM_P}\\\!\.\-\_]+)^$][]{
    	$result[<a href="file://^match.1.replace[^table::create[nameless]{\	/}]">\\$match.1</a>]
      $isReturn(1)	
    }	
  } 

# Citated
  ^if(!$isReturn){
    ^thing.match[^^\n[ \t]*(>+)(.*)^$][]{
    	$result[<div class="email email-^if(^match.1.length[]%2){odd}{even}">${match.1}^match.2.match[$LONGREGEXP][gxs]{^_callback[$match]}</div>]
      $isReturn(1)	
    }	
  } 

# Blockquote
  ^if(!$isReturn){
    ^thing.match[^^<\[(.*)\]>^$][]{
    	$result[^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}]
    	$result[^result.match[^^(<br \/>)+][i]{}]
    	$result[^result.match[(<br \/>)+^$][i]{}]
#     These regexp needed for workaround MSIE bug (</ul></blockquote>)
    	^if(^result.match[<\/ul>[\s\r\t\n]*^$][i]){
    		  $result[${result}$_z_gif]
      }
    	$result[<blockquote>$result</blockquote>]
      $isReturn(1)	
    }	
  } 

# Super
  ^if(!$isReturn){
    ^thing.match[^^\^^\^^(.*)\^^\^^^$][]{
    	$result[<sup>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</sup>]
      $isReturn(1)	
    }	
  } 

# Sub
  ^if(!$isReturn){
    ^thing.match[^^vv(.*)vv^$][]{
    	$result[<sub>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</sub>]
      $isReturn(1)	
    }	
  } 

# Headers
  ^if(!$isReturn){
    ^thing.match[(?:^^|\n)\s*={7}(.*?)={2,7}^$][]{
  	  $result[^_indentClose[]]
    	^_headerCount.inc[]
    	$_br(0)
    	$result[${result}<a name="h${_pageId}-$_headerCount"></a><h6>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</h6>]
      $isReturn(1)	
    }	 
  } 

  ^if(!$isReturn){
    ^thing.match[(?:^^|\n)\s*={6}(.*?)={2,7}^$][]{
  	  $result[^_indentClose[]]
    	^_headerCount.inc[]
    	$_br(0)
    	$result[${result}<a name="h${_pageId}-$_headerCount"></a><h5>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</h5>]
      $isReturn(1)	
    }	
  } 

  ^if(!$isReturn){
    ^thing.match[(?:^^|\n)\s*={5}(.*?)={2,7}^$][]{
  	  $result[^_indentClose[]]
  	  ^_headerCount.inc[]
  	  $_br(0)
    	$result[${result}<a name="h${_pageId}-$_headerCount"></a><h4>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</h4>]
      $isReturn(1)	
    }	
  } 

  ^if(!$isReturn){
    ^thing.match[(?:^^|\n)\s*={4}(.*?)={2,7}^$][]{
  	  $result[^_indentClose[]]
    	^_headerCount.inc[]
    	$_br(0)
    	$result[${result}<a name="h${_pageId}-$_headerCount"></a><h3>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</h3>]
      $isReturn(1)	
    }	
  } 

  ^if(!$isReturn){
    ^thing.match[(?:^^|\n)\s*={3}(.*?)={2,7}^$][]{
  	  $result[^_indentClose[]]
    	^_headerCount.inc[]
    	$_br(0)
    	$result[${result}<a name="h${_pageId}-$_headerCount"></a><h2>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</h2>]
      $isReturn(1)	
    }	
  } 

  ^if(!$isReturn){
    ^thing.match[(?:^^|\n)\s*={2}(.*?)={2,7}^$][]{
  	  $result[^_indentClose[]]
    	^_headerCount.inc[]
    	$_br(0)
    	$result[${result}<a name="h${_pageId}-$_headerCount"></a><h1>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</h1>]
      $isReturn(1)	
    }	
  } 

# Separators
  ^if(!$isReturn){
    ^thing.match[^^[-]{4,}^$][]{
    	$_br(0)
    	$result[<hr noshade="noshade" size="1" />]
      $isReturn(1)	
    }	
  } 

# Forced line breaks
  ^if(!$isReturn){
    ^thing.match[^^---\n?\s*^$][]{
    	$result[<br />^#0A]
      $isReturn(1)	
    }	
  } 

# Strike
  ^if(!$isReturn){
    ^thing.match[^^--((\S.*?\S)|(\S))--^$][]{
    	$result[<s>^match.1.match[$LONGREGEXP][gx]{^_callback[$match]}</s>]
      $isReturn(1)	
    }	
  } 

# Definitions
  ^if(!$isReturn){
  	$matches(0)
    ^thing.match[^^\(\?(.+)(?:==|\|)(.*)\?\)^$][]{$matches[$match]}	
    ^if(!$matches){
    	  ^thing.match[^^\(\?(\S+)(?:\s+(.+))?\?\)^$][]{$matches[$match]}	
    }
    ^if($matches){
    	^matches.2.match[\xA4\xA4|__|\^[\^[|\(\(][]{}
    	$result[<dfn title="^if(def $matches.2){$matches.2}{$matches.1}">$matches.1</dfn>]
      $isReturn(1)	
    }
  } 

# forced links & footnotes
  ^if(!$isReturn){
    ^thing.match[^^\[\[(.+)(==|\|)(.*)\]\]^$][]{$matches[$match]}
    ^if(!$matches){^thing.match[^^\(\((.+)(==|\|)(.*)\)\)^$][]{$matches[$match]}}
    ^if(!$matches){^thing.match[^^\[\[(\S+)(\s+(.+))?\]\]^$][]{$matches[$match]}}
    ^if(!$matches){^thing.match[^^\(\((\S+)(\s+(.+))?\)\)^$][]{$matches[$match]}}
    
    $url[$matches.1]
    $text[$matches.3]
    
    ^if(def $url){

#    	Сноска
    	^if(^url.mid(0;1) eq "*"){
        $sup(1)
        $aname[]
        ^if(^url.match[^^\*+^$]){
        	$aname[ftn^url.length[]]
        	^if(!def $text){$text[$url]}
        }
        ^if(^url.match[^^\*\d+^$]){
        	$aname[ftnd^url.mid(1)]
        }
        ^if(!def $aname){
        	$aname[^url.mid(1)]
        	$sup(0)
        }
        ^if(!def $text){
        	$text[^url.mid(1)]
        }
        $result[^if($sup){<sup>}<a href="#o$aname" name="$aname">$text</a>^if($sup){</sup>}]
    	  $isReturn(1)
    	}
    	
    	^if(!$isReturn 
    	    && ^url.mid(0;1) eq "#"){
        $anchor[^url.mid(1)]
        $sup(1)
        ^if(^anchor.match[^^\*+^$]){
        	$ahref[ftn^anchor.length[]]
        }
        ^if(^anchor.match[^^\d+^$]){
        	$ahref[ftnd$anchor]
        }
        ^if(!def $ahref){
        	$ahref[$anchor]
        	$sup(0)
        }
#        ^if(!def $text){
#        	$text[^url.mid(1)]
#        }
        $result[^if($sup){<sup>}<a href="#$ahref" name="o$ahref">$anchor</a>^if($sup){</sup>} $text]
    	  $isReturn(1)
    	}
    	
    	^if(!$isReturn){
    		$ourl[$url]
    		$url[^url.match[\xA4\xA4|\xA3\xA3|\^[\^[|\(\(][]{}]
    		^if($ourl ne $url){
    			$result[</span>]
    		}
    		^if(^url.mid(0;1) eq "("){$url[^url.mid(1) $result[(]]}
    		^if(^url.mid(0;1) eq "^["){$url[^url.mid(1) $result[^[]]}
    		^if(!def $text){$text[$url]}
    		$url[^url.replace[^table::create[nameless]{ 	}]]
    		$text[^text.match[\xA4\xA4|\xA3\xA3|\^[\^[|\(\(][]{}]
    	  $result[${result}^_preLink[$url;$text]]
      }    	
    	$isReturn(1)
    }    
  }

# Indented text
  ^if(!$isReturn){
    ^thing.match[(^^|\n)(\t+|(?:[ ]{2})+)(-|\*|([0-9,a-z,A-Z]{1,2})[\.\)](\#[0-9]{1,3})?)?(\n|^$)][]{$matches[$match]}	
 	
    ^if($matches is table && $matches){
    	
    $result[^if($_br){<br />^#0A}{^#0A}]

#   Intable or not?
	  ^if($_intable){
		  $Closers[$_tdIndentClosers]
		  $oldLevel[$_tdOldIndentLevel]
		  $oldType[$_tdOldIndentType]
		}{
			 $Closers[$_indentClosers]
			 $oldLevel($_oldIndentLevel)
			 $oldType[$_oldIndentType]
		}

#   we definitely want no line break in this one.
		$_br(0)

#   #18 syntax support
		^if(def $matches.5){
			$start[^matches.5.mid(1)]
		}{
			 $start[]
		 }

#   find out which indent type we want
			$newIndentType[^matches.3.mid(0;1)]
			^if(!def $newIndentType){
				$opener[<div class="indent">]
				$closer[</div>]
				$_br(1)
				$li(0)
				$newType[i]
				}{
					^if($newIndentType eq "-" || $newIndentType eq "*"){
						$opener[<ul><li>]
						$closer[</li></ul>]
						$li(1)
						$newType[*]
						}{
							$opener[<ol type="$newIndentType" ><li ^if(def $start){value="$start"}>]
							$closer[</li></ol>]
							$li(1)
							$newType[1]
						}
					}
#         get new indent level
					^if(^matches.2.mid(0;1) eq " "){
						$newIndentLevel(^matches.2.length[]\2)
					}{
						 $newIndentLevel(^matches.2.length[])
				   }

						^if($newIndentLevel > $oldLevel){
							^for[i](0;$newIndentLevel - $oldLevel - 1){
								$result[${result}$opener]
								^Closers.push[$closer]
							}
						}

						^if($newIndentLevel < $oldLevel){
							^for[i](0;$oldLevel - $newIndentLevel - 1){
								$result[${result}^Closers.pop[]]
							}
						}

						^if($newIndentLevel == $oldLevel && $oldType ne $newType){
							$result[${result}^Closers.pop[]]
							$result[${result}$opener]
							^Closers.push[$closer]
						}
							
						^if($li && !^result.match[^taint[regex][$opener]^$]){
							$result[$result</li><li ^if(def $start){value="$start"}>]
						}
							
						^if($_intable){
							$_tdOldIndentLevel($newIndentLevel)
							$_tdOldIndentType[$newType]
						}{
							 $_oldIndentLevel($newIndentLevel)
							 $_oldIndentType[$newType]
							 $_indentClosers[$Closers]
						 }
			$isReturn(1)
		}
  }

# new lines  
  ^if(!$isReturn && $thing eq "^#0A" && !$_intablebr){
  	$result[^_indentClose[]]
  	^if(def $result){$_br(0)}{$_br(1)}
  	$result[$result^if($_br){<br />^#0A}{^#0A}]
  	$_br(1)
  	$isReturn(1)
  }

# interwiki links  
  ^if(!$isReturn){
    ^thing.match[^^([a-zA-Z0-9]+[:][$ALPHANUM_P\!\.][$ALPHANUM_P\-\_\.\+\&\=]+?)([^^a-zA-Z0-9^^\/\-\_\=]?)^$][]{
       $result[^_preLink[$match.1;$match.2]]
       $isReturn(1)
    }
  }  

# tikiwiki links  
  ^if(!$isReturn && !$_options.disable_tikilinks){
    ^thing.match[^^(${UPPER}${LOWER}${ALPHANUM}*\.${ALPHA}${ALPHANUM}+)^$][]{
       $result[^_preLink[$thing]]
       $isReturn(1)
    }
  }  
  
# npj links  
  ^if(!$isReturn){
    ^thing.match[^^(~?)($ALPHANUM_L+\@$ALPHA_L*(\:$ALPHANUM*)?|$ALPHANUM_L+\:\:$ALPHANUM+)^$][]{
       ^if($match.1 eq "~"){
       	 $result[$match.2]
       }{
          $result[^_preLink[$thing]]
       	}
       $isReturn(1)
    }
  }  

# wacko links  
  ^if(!$isReturn){
    ^thing.match[^^(((\.\.)|!)?\/?|~)?(${UPPER}${LOWER}+${UPPERNUM}${ALPHANUM}*)^$][]{
       ^if($match.1 eq "~"){
       	 $result[$match.4]
       }{
          $result[^_preLink[$thing]]
       	}
       $isReturn(1)
    }
  }  

  ^if(!$isReturn){
    ^if(^thing.mid(0;1) eq "~" && ^thing.mid(1;1) eq "~"){
    	^thing.trim[start;~]
    }	
    ^if(^thing.mid(0;2) eq "~~"){
    	$thing[^thing.mid(2)]
    	$result[~^thing.match[$LONGREGEXP][gx]{^_callback[$match]}]
    	$isReturn(1)
    }
  }
  
# Else?
  ^if(!$isReturn){
  	$result[$thing]
  }  

@_postCallback[aThings][isReturn;thing;url;text]
  $isReturn(0)
  $thing[$aThings.1]

# forced links ((link link == desc desc))
  ^if(!$isReturn){
    ^thing.match[^^\xA2\xA2([^^\n]+)==([^^\n]*)\xAF\xAF^$][]{
    	$url[$match.1]
    	$text[$match.2]
    	^if(def $url){
    		$url[^url.replace[^table::create[nameless]{ 	}]]
    		$text[^text.match[\xA4\xA4|__|\^[\^[|\(\(][]{}]
    		$text[^text.trim[]]
    		$result[^_preLink[$url;$text]]
      }{
      	 $result[]
       }
      ^isReturn(1) 
    }
  }
      
# Actions
  ^if(!$isReturn){
    ^thing.match[^^\xA1\xA1\s*([^^\n]+?)\xA1\xA1^$][]{
      ^if(def $match.1){
##@TODO: 
      	$result[]
      }{
      	 $result[{{}}]
       }
      $isReturn(1)
    }
  }

  ^if(!$isReturn){
  	$result[$thing]
  }  
  
#-------- Обрабтчики тэгов ----------
  
@_preLink[aURL;aText]
  $result[<a href="$aURL">^if(def $aText){$aText}{$aURL}</a>]
  
  
#-------- Заглушки для экшнов и пр. ----------
@wrapAction[aStr]
  $result[{{$aStr}}]
  
@_indentClose[][Closers]
  ^if($_intable){
  	$Closers[$_tdIndentClosers]
  }{
  	 $Closers[$_indentClosers]
   }
  ^if($Closers.count > 0){
    ^for[i](0;$Closers.count - 1){
    	$result[${result}^Closers.pop[]]
    }
    ^if($_intable){
     	$_tdOldIndentLevel(0)
    }{
  	   $_oldIndentLevel(0)
     }
  }{
  	  $result[]
   }
    