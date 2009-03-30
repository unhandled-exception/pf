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
##  ����� ��� �������������� ������ �� �������� ������� �����������. 
##
##  ��� ���������� ������������� ��������� ���:
##  --------------------
##  1. Typografica library: typografica class. v.2.6 23 February 2005. 
##     http://www.pixel-apes.com/typografica
##     Kuso Mendokusee <mailto:mendokusee@yandex.ru>
##
##  2. ��������� ����� ������� "��������"
##     http://www.typograf.ru/download/
##     Eugene Spearance (mail@spearance.ru)
##  
##  3. "������� ���������� ���������"
##     http://spearance.ru/parser3/regex/
##     Eugene Spearance (mail@spearance.ru)
## 
#/doc

@create[aOptions]
  ^BASE:create[]
  ^cleanMethodArgument[]
  
# ����������� ������������ �������
  $_processQuotes[^aOptions.processQuotes.int(1)]

# ������������ ����������� ������� [(c), (R), +- � �.�.]
  $_processSpecial[^aOptions.processSpecial.int(1)]

  $_processSpaces[^aOptions.processSpaces.int(1)]

# regex, ������� ������������.
   $_reIgnore[(<!--notypo-->.*?<!--\/notypo-->)]
   $_ignoreMark[^math:uid64[]]  

# regex, ������� ������������.
   $_reTags[(<\/?[a-z0-9]+(?:         # ��� ����
                       \s+(?:        # ����������� �����������: ���� �� ���� ����������� � ������
                         [a-z]+(   # ������� �� ����, �� ������� ����� ������ ���� ��������� � �����
                                 =(?:(?:\'[^^\']*\')|(?:\"[^^\"]*\")|(?:[0-9@\-_a-z:\/?&=\.]+))
                          )?       # '

                          )?
                        )*\/?>|\xA2\xA2[^^\n]*?==)]
   $_tagsMark[^taint[regex][<:t:>]]  

   ^_makeVars[]

@process[aText][lIgnored;lTags]
# ���������� �� ������ ��� �����. ������� ���� ���������������
  $lIgnored[^aText.match[$_reIgnore][gi]]
  $aText[^aText.match[$_reIgnore][gi]{$_ignoreMark}]

# ���������� �� ������ ��� html-����.
  $lTags[^aText.match[$_reTags][gxi]]
  $result[^aText.match[$_reTags][gxi]{$_tagsMark}]

# �������� � ������ "������������" ������� � ������ �� ������� �������.
  $result[^result.replace[$_preRep]]

  ^if($_processSpaces){
#   ����������� � �������� � ������� ���������.
    $result[^result.match[\s{2,}][g]{ }]
    
#   ���������� ������� �� � ����� ������ ����������    
    $result[^result.match[\b(?:\s*)([\.?!:^;]+)\s*([a-z�-�])][gi]{$match.1 $match.2}]
    $result[^result.match[\b(?:\s*)([,])][gi]{$match.1 }]
    $result[^result.match[(\w)\s+([\.:\?!^;])][g]{${match.1}$match.2}]

#   ��������� ������ ����� ������� � ��������� ������
    $result[^result.match[(\b[\d]+)([a-z�-�])][gi]{$match.1 $match.2}]
    $result[^result.match[(\w)([\.?!^;:]+)([A-Z�-�])][g]{${match.1}${match.2} $match.3}]
 
    $result[^result.match[(�|�)\s*(.)][g]{$match.1&nbsp^;$match.2}]
    $result[^result.match[(?:(P\.)\s*)?(P\.)\s*(S\.)][gi]{${match.1}${match.2}${match.3}}]

#   ������� ������ ������� ������ ������ � �������.
    $result[^result.match[(\s|^^)(["']+)\s*([A-Z�-�])][g]{${match.1}${match.2}${match.3}}]
    $result[^result.match[([a-z�-�])\s*(["']+)([\s\.,?!^;:]+)][g]{${match.1}${match.2}${match.3} }]
    
    $result[^result.match[([\(])\s+][g]{$match.1}]
    $result[^result.match[(?:\s+)(\))][g]{$match.1}]
  
    $result[^result.match[(\S)\((\S)][g]{$match.1 ($match.2}]
    $result[^result.match[(\S)\)(\S)][g]{$match.1) $match.2}]
  
  }

# �������
  ^if($_processQuotes){
    $laquo[^#AB]
    $raquo[^#BB]
    $ldquo[^#84]
    $rdquo[^#93]

    $_preQuotePattern[\w^;\.,:\)\^]\}\?!%\^$`/">-]

    $result[^result.match[\s+"(\s+)][g]{"$match.1}]

  	$result[^result.match[^^(\"+)][g]{^for[i](1;^match.1.length[]){$laquo}}]
   	$result[^result.match[((?:\n|^^)\s*)($_tagsMark*)(\"+)][g]{${match.1}${match.2}^for[i](1;^match.3.length[]){$laquo}}]
   	$result[^result.match[(?<=[^^${_preQuotePattern}])(\"+)][g]{^for[i](1;^match.1.length[]){$laquo}}]
   	$result[^result.match[(\"+\b)][g]{^for[i](1;^match.1.length[]){$laquo}}]
   	$result[^result.match[(?<=[${_preQuotePattern}])(\"+)][g]{^for[i](1;^match.1.length[]){$raquo}}]
    $result[^result.match[${laquo}([^^${raquo}]*)((${laquo}[^^${laquo}]+?${raquo}[^^\n]*?)+?)${raquo}][g]{${laquo}${match.1}^match.2.match[${laquo}(.+?)${raquo}][g]{${ldquo}${match.1}${rdquo}}${raquo}}]
        	
#     $result[^result.match[($raquo|$rdquo)(\S|[:\.?^;\!])][g]{$match.1 $match.2}]    
#     $result[^result.match[(\S|[:\.?^;\!])($laquo|$ldquo)][g]{$match.1 $match.2}]    
         
    $result[^result.match[($raquo|$rdquo|\b)(\()][g]{$match.1 $match.2}]    
    $result[^result.match[(\))($laquo|$ldquo|\b)][g]{$match.1 $match.2}]    
        
    $result[^result.replace[^table::create{from	to
$laquo	&laquo^;
$raquo	&raquo^;
$rdquo	&ldquo^;
$ldquo	&bdquo^;}]]
  }

## ������

# �����������  
  ^if($_processSpecial){
  	$result[^result.match[(?:�|�)][g]{&bull^;}]
  	$result[^result.match[\.{3,}][g]{&hellip^;}]
  	$result[^result.match[\((?:c|�)\)][gi]{&copy^;}]
  	$result[^result.match[\(r\)][gi]{<sup><small>&reg^;</small></sup>}]
  	$result[^result.match[\(tm\)][gi]{<sup><small>&trade^;</small></sup>}]
  	$result[^result.match[(\d+)\s*(x|�)\s*(\d+)][gi]{$match.1&times^;$match.3}]
  	$result[^result.match[\b1/2\b][gi]{&frac12^;}]
  	$result[^result.match[\b1/4\b][gi]{&frac14^;}]
  	$result[^result.match[\b3/4\b][gi]{&frac34^;}]
  	$result[^result.match[(\+\-|\-\+|\+/\-)][gi]{&plusmn^;}]
	
#   �������� � � F � ������������ �������� �� ����������� ������, �C � �F ��������������
    $result[^result.match[([-+]?\d+(?:[.,]\d*)?)([C�F])\b][g]{${match.1}&nbsp^;&deg^;$match.2}]
  }
  
# �������� ������� ����� ���������� � ���� �� ���������
  $result[^result.match[([\.,!?-])\1+][g]{$match.1}]

# ����� � ����
  $result[^result.match[(?<!\-)(?=\b)(\w+)\-(\w+)(?<=\b)(?!\-)][g]{<span class="nobr">${match.1}-$match.2</span>}]

# �������� ���� ���� ����� ����� �������� � ��������� ������� �� � (������ �����)
# ��������� ��� ����, ����� ��������� ���������� ������� ��������� (��������, ��������)
  $result[^result.match[(\d+|[IVXL]+)-(\d+|[IVXL]+)][g]{${match.1}&ndash^;$match.2}]
  $result[^result.match[(\d+|[IVXL]+)-(\d+|[IVXL]+)][g]{${match.1}&ndash^;$match.2}]


# ����
  $result[^result.match[(\s|&nbsp^;)\-\s+][g]{&nbsp^;&mdash^; }]


# ��������
  $result[^result.match[([A-Z�-�])\.\s*([A-Z�-�])\.\s*([A-Z�-�][a-z�-�])][g]{${match.1}.${match.2}.&nbsp^;$match.3}]
  $result[^result.match[([a-z�-�]+)\s*([A-Z�-�])\.\s*([A-Z�-�])\.][g]{${match.1}&nbsp^;${match.2}.${match.3}.}]


## ����������
    
# ����������� �����������
  $result[^result.match[(\s+|&nbsp^;)(���|����|��|���|���|���|����|���|��|��|���|��|����|��|�|�)(\.)(?:\s*)][gi]{${match.1}${match.2}${match.3}&nbsp^;}]
  $result[^result.match[(?:\s+)(���\.|���\.|�\.�\.|���\.)(\s+|&nbsp^;)][gi]{&nbsp^;${match.1}${match.2}}]

# �������� ���������� � �.�., � �.�. �� <nobr>� �.�.</nobr> <nobr>� �.�.</nobr>, ������ ��� ���� ������ �������
  $result[^result.match[(�)\s+(�)\.\s*([��])\.][gi]{<span class="nobr">${match.1} ${match.2}.${match.3}.</span>}]

# ��������� ����������� � ��. ����������� ��������
  $result[^result.match[(�)\s+(��.)][gi]{${match.1}&nbsp^;$match.2}]

# �������� ���������� � �.�. �� <nobr>� �.�.</nobr> ������ ��� ���� ������ �������
  $result[^result.match[(�)\s+(�.)\s?(�.)][gi]{<span class="nobr">$match.1 ${match.2}$match.3</span>}]

# ����������� ��� ����-����-����-���������� ����� � ��������� (����������) ������
  $result[^result.match[(?<![-:])\b([a-z�-��]{1,3}\b(?:[,:^;\.]?))(?!\n)\s][gi]{${match.1}&nbsp^;}]
  $result[^result.match[(\s|&nbsp^;)(��|��|��|��|�|�|��)([\.,!\?:^;])?&nbsp^;][gi]{&nbsp^;${match.2}$match.3 }]

# ����������� ����� ������ �� ������.
  $result[^result.match[(\d)\s+([\w%^$])][gi]{$match.1&nbsp^;$match.2}]
  
# ����������� � ����������� � ����������� �������/������������.
  $result[^result.match[(?<!(?:\s|\d))(��|�)(2|3)([^^\d\w])][gi]{$match.1<sup><small>$match.2</small></sup>$match.3}]

# ������� ������ ����
  $result[^result.match[(>|\A|\n)\-\s][g]{^taint[^#0A^#0A]${match.1}&mdash^;&nbsp^;}]

# �������� <nobr></nobr> �� <span class="nobr></span> ��� ���� ������ �� ����� ������ &nbsp^;
## TODO



# ��������� ������� ����
  $result[^result.match[$_tagsMark][g]{${lTags.1}^lTags.offset(1)}]
  
# ��������� ������� �����, ������� ���� ���� ������������
  $result[^result.match[$_ignoreMark][g]{${lIgnored.1}^lIgnored.offset(1)}]
 
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
�	(c)
�	(r)
�	(tm)
�	
�	+-
--	-
�	-
-	-
�	-
�	"
�	"
�	...
�	"
�	"
�	"
<nobr>	
</nobr>
<NOBR>	
</NOBR>	
&#8470^;	�
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
&#1105^;	�
&#1025^;	�
&#167^;	�}]  
