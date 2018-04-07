# PF Library

#@compat 3.2.3

@CLASS
pfString

##  Класс с различными строковыми функциями.

@auto[]
  $self.__pfString__[
    $.classDefRegex[^regex::create[^^([^^@:]*)(?:@([^^:]+))?(?::+(.+))?^$]]
  ]

@trim[aString;aSide;aSymbols]
## Обертка над стандартным парсеровским trim'ом, которая проверяет существование строку.
  $result[^if(def $aString){^aString.trim[$aSide;$aSymbols]}]

@changeCase[str;type]
## Меняет регистр на СТРОЧНЫЙ/прописной/Первый Символ строчный/Только первый символ строчный
## а заодно отрезает все пробельные символы в начале строки.
## $type[upper/lower/first/first-upper]
## http://www.spearance.ru/parser3/change_case/
  $result[^switch[^type.lower[]]{
    ^case[upper]{^str.upper[]}
    ^case[lower]{^str.lower[]}
    ^case[first]{^str.match[^^\s*(\pL)(.*?)^$][i]{^if(def $match.1){^match.1.upper[]}^if(def $match.2){^match.2.lower[]}}}
    ^case[first-upper]{^str.match[^^\s*(\pL)][]{^match.1.upper[]}}
    ^case[DEFAULT]{$str}
  }]

@rsplit[text;regex;options][table_split]
## Разбивает строку по регулярным выражениям
## $options:   l - разбить слева направо (по-умолчанию);
##             r - разбить справа налево;
##             h - сформировать безымянную таблицу где части исходной строки
##                 помещаются горизонтально;
##             v - сформировать таблицу со столбцом piece, где части исходной строки
##                 помещаются вертикально (по-умолчанию).
## http://www.spearance.ru/parser3/rsplit/
  ^if(def $regex){
    $table_split[^table::create{piece}]
    ^if(def $text){
      $result[^text.match[(.*?)(?:$regex)][g]{^if(def $match.1){^table_split.append{$match.1}}}]
      ^if(def $result){^table_split.append{$result}}
    }
      ^if(!def $options){$options[lv]}
      ^switch[^options.lower[]]{
        ^case[r;rv;vr]{$result[^table::create[$table_split;$.reverse(1)]]}
        ^case[rh;hr]{$result[^table::create[$table_split;$.reverse(1)]]$result[^result.flip[]]}
        ^case[h;lh;hl]{$result[^table_split.flip[]]}
        ^case[DEFAULT]{$result[$table_split]}
      }
  }{
    ^throw[parser.runtime;rsplit;parameters ^$regex must be defined]
  }

@left[str;substr]
## $substr - символ или набор символов до которого нужно отрезать строку слева
## http://www.spearance.ru/parser3/lrstring/
  $substr[^taint[regex][$substr]]
  ^if(def $str && def $substr && ^str.match[$substr]){
    $result[^str.match[^^(.*?)${substr}.*?^$][]{$match.1}]
  }{
    $result[$str]
  }

@right[str;substr]
## $substr - символ или набор символов до которого нужно отрезать строку слева
## http://www.spearance.ru/parser3/lrstring/
  $substr[^taint[regex][$substr]]
  ^if(def $str && def $substr && ^str.match[$substr]){
    $result[^str.match[^^.*?${substr}(.*?)^$][]{$match.1}]
  }{
    $result[$str]
  }

@middle[str;left;right]
## http://www.spearance.ru/parser3/lrstring/
  ^if(def $str && def $left && def $right){
    $result[^left[$str;$left]]
    $result[^right[$str;$right]]
  }{
    $result[$str]
  }

@numberFormat[sNumber;sThousandDivider;sDecimalDivider;iFracLength][iTriadCount;iSign;tPart;sIntegerPart;sMantissa;sNumberOut;iMantLength;tIncomplTriad;iZeroCount;sZero]
## Форматирует число и вставляет правильные десятичные разделители
  $iSign(^math:sign($sNumber))
  $tPart[^sNumber.split[.][lh]]
  $sIntegerPart[^eval(^math:abs($tPart.0))[%.0f]]
  $sMantissa[$tPart.1]
  $iMantLength(^sMantissa.length[])
  $iFracLength(^iFracLength.int($iMantLength))
  ^if(!def $sThousandDivider){
    $sThousandDivider[ ]
  }

  ^if(^sIntegerPart.length[] > 3){
    $iIncomplTriadLength(^sIntegerPart.length[] % 3)
    ^if($iIncomplTriadLength){
      $tIncomplTriad[^sIntegerPart.match[^^(\d{$iIncomplTriadLength})(\d*)]]
      $sNumberOut[$tIncomplTriad.1]
      $sIntegerPart[$tIncomplTriad.2]
      $iTriadCount(1)
    }{
      $sNumberOut[]
      $iTriadCount(0)
    }
    $sNumberOut[$sNumberOut^sIntegerPart.match[(\d{3})][g]{^if($iTriadCount){$sThousandDivider}$match.1^iTriadCount.inc(1)}]
  }{
    $sNumberOut[$sIntegerPart]
  }

  $result[^if($iSign < 0){-}$sNumberOut^if($iFracLength > 0){^if(def $sDecimalDivider){$sDecimalDivider}{,}^sMantissa.left($iFracLength)$iZeroCount($iFracLength-^if(def $sMantissa)($iMantLength)(0))^if($iZeroCount > 0){$sZero[0]^sZero.format[%0${iZeroCount}d]}}]

@numberDecline[num;nominative;genitive_singular;genitive_plural]
## Склоняет существительные, стоящие после числительных, и позволяет избегать
## в результатах работы ваших скриптов сообщений вида: «найдено 2 записей».
## ^num_decline[натуральное число или ноль;именительный падеж;родительный падеж, ед. число;родительный падеж, мн. число]
## http://www.parser.ru/examples/decline/
  ^if($num > 10 && (($num % 100) \ 10) == 1){
          $result[$genitive_plural]
  }{
          ^switch($num % 10){
                  ^case(1){$result[$nominative]}
                  ^case(2;3;4){$result[$genitive_singular]}
                  ^case(5;6;7;8;9;0){$result[$genitive_plural]}
          }
  }

@parseURL[aURL][lMatches;lPos]
## Разбирает url
## $result[$.protocol $.user $.password $.host $.port $.path $.options $.nameless $.url $.hash]
## $result.options - таблица со столбцом piece
  $result[^hash::create[]]
  ^if(def $aURL){
    $lMatches[^aURL.match[
       ^^
       (?:([a-zA-Z\-0-9]+?)\:(?://)?)?   # 1 - protocol
       (?:(\S+?)(?:\:(\S+))?@)?          # 2 - user, 3 - password
       (?:([a-z0-9\-\.]*?[a-z0-9]))      # 4 - host
       (?:\:(\d+))?                      # 5 - port
       (/[^^\s\?]*)?                     # 6 - path
       (?:\?(\S*?))?                     # 7 - options
       (?:\#(\S*))?                      # 8 - hash (#)
       ^$
          ][xi]]
   ^if($lMatches){
      $result.protocol[$lMatches.1]
      $result.user[$lMatches.2]
      $result.password[$lMatches.3]
      $result.host[$lMatches.4]
      $result.port[$lMatches.5]
      $result.path[$lMatches.6]

      $lPos(^lMatches.7.pos[?])
      $result.nameless[^if($lPos >= 0){^lMatches.7.mid($lPos+1)}]
      $result.options[^if($lPos >= 0){^lMatches.7.left($lPos)}{$lMatches.7}]
      $result.options[^if(def $result.options){^result.options.split[&;lv]}{^table::create{piece}}]

      $result.hash[$lMatches.8]
      $result.url[$aURL]
    }
  }

@format[aString;aValues]
## Форматирует строку, заменяя макропоследовательности %(имя)Длина.ТочночтьТип значениями из хеша aValues.
## В дополнение к парсеровским типам форматирования понимает тип "s" - строковое представление значения.
## Если тип не указан, то он соответствует строковому.
   $result[^aString.match[(?<!\\)(%\((\S+?)\)((?:\d+(?:\.\d+)?)?([sudfxXo]{1})?))][g]{^if(^aValues.contains[$match.2]){^if(!def $match.4 || $match.4 eq "s"){$aValues.[$match.2]}{^eval($aValues.[$match.2])[%$match.3]}}{}}]
   $result[^result.match[\\(.)][g]{^_processEscapedSymbol[$match.1]}]

@_processEscapedSymbol[aSymbol]
## Возвращает символ, соответствующий букве в заэскейпленой конструкции.
   ^switch[$aSymbol]{
     ^case[n]{$result[^taint[^#0A]]}
     ^case[t]{$result[^taint[^#09]]}
     ^case[b;r;f]{$result[]}
     ^case[DEFAULT]{$result[$aSymbol]}
   }

@stripHTMLTags[aText]
## Удаляет из текста все HTML-теги.
  $result[^aText.match[<\/?[a-z0-9]+(?:\s+(?:[a-z0-9\_\-]+\s*(?:=(?:(?:\'[^^\']*\')|(?:\"[^^\"]*\")|(?:[0-9@\-_a-z:\/?&=\.]+)))?)?)*\/?>][gi][]]

@dec2bin[iNum;iLength][i]
## Преобразует число в двоичную строку. 5 -> '101'
  $i(1 << (^iLength.int(24)-1))
  $result[^while($i>=1){^if($iNum & $i){1}{0}$i($i >> 1)}]


@unEscape[aText]
  $result[^aText.replace[^table::create{from	to
+	^#20
%20	^#20
%D0	^rem{empty}
%D1	^rem{empty}
%B0	а
%B1	б
%B2	в
%B3	г
%B4	д
%B5	е
%91	ё
%B6	ж
%B7	з
%B8	и
%B9	й
%BA	к
%BB	л
%BC	м
%BD	н
%BE	о
%BF	п
%80	р
%81	с
%82	т
%83	у
%84	ф
%85	х
%86	ц
%87	ч
%88	ш
%89	щ
%8A	ъ
%8B	ы
%8C	ь
%8D	э
%8E	ю
%8F	я}]]

@levenshteinDistance[aStr1;aStr2][locals]
## Вычисляет расстояние Левенштейна между двумя строками.
## Алгоритм потребляет очень много памяти, поэтому его лучше использовать
## на коротких строках (до 15-20 символов).
  $result(0)

  ^if(^aStr1.length[] > ^aStr2.length[]){
#   Make sure n <= m, to use O(min(n,m)) space
    $lStr1[$aStr2]
    $lStr2[$aStr1]
  }{
     $lStr1[$aStr1]
     $lStr2[$aStr2]
   }
  $n(^lStr1.length[])
  $m(^lStr2.length[])

  ^if($n > 0 && $m > 0){
#   Keep current and previous row, not entire matrix
    $current_row[^hash::create[]]
    ^for[i](0;$n){
      $current_row.[$i]($i)
    }
    ^for[i](1;$m){
      $previous_row[$current_row]
      $current_row[^hash::create[]]
      $current_row.0($i)
      ^for[j](1;$n){
        $add($previous_row.[$j] + 1)
        $delete($current_row.[^eval($j - 1)] + 1)
        $change($previous_row.[^eval($j - 1)])
        ^if(^lStr1.mid($j - 1;1) ne ^lStr2.mid($i - 1;1)){
          ^change.inc[]
        }
        $lTemp(^if($add < $delete){$add}{$delete})
        $current_row.[$j](^if($lTemp < $change){$lTemp}{$change})
      }
    }
    $result($current_row.[$n])
  }{
     $result(^math:abs($n - $m))
   }

@parseClassDef[aClassDef] -> [$.className $.constructor $.package $.classDef]
## Метод может быть вызван из других классов для разбора пути к пакетам.
  $aClassDef[^aClassDef.trim[]]
  $result[$.classDef[$aClassDef]]
  ^aClassDef.match[$self.__pfString__.classDefRegex][]{
    $result.constructor[^if(def $match.3){$match.3}{create}]
    ^if(def $match.2){
      $result.className[$match.2]
    }{
       $result.className[^file:justname[$match.1]]
     }
    $result.package[^if($match.1 ne $result.className){$match.1}]
  }
