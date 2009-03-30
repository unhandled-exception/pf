# PF Library
# Copyright (c) 2006-07 Oleg Volchkov

#@module   Paragrafica Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://volchkov.net

@CLASS
pfParagrafica

#@doc
##  ���� �� Parser php-������, ����������� ��������� � ������ � html-���������.
##
##  ������������ ������:
##  --------------------
##   Typografica library: paragrafica class.
##   v.2.6
##   23 February 2005. 
##   ---------
##   http://www.pixel-apes.com/typografica
##   Copyright (c) 2004, Kuso Mendokusee <mailto:mendokusee@yandex.ru>
##   All rights reserved.
#/doc

@USE
pf/types/pfClass.p

@BASE
pfClass

#----- Constructor -----

@create[aOptions]
  ^cleanMethodArgument[]

# �����/�������� ��� ����� �����:   <t->text, text, fcuking text<-t>   

# regex, ������� ������������.
   $_reIgnore[(<!--notypo-->.*?<!--\/notypo-->)]
   $_ignoreMark[|#|ignore|#|]

# ����������� ���� <-t>$1<t->
   $_reT0[
     $.1[(<br[^^>]*>)(\s*<br[^^>]*>)+]
     $.2[(<hr[^^>]*>)]
   ]
   
# ����������� ���� <-t>$1
   $_reT1[
#    rightinators
      $.1[
         $.1[(<table)]
         $.2[((?:<a[^^>]*></a>)?<h[1-9]>)]
         $.3[(<(u|o)l)] 
         $.4[(<div)] 
         $.5[(<p)] 
         $.6[(<form)]
         $.7[(<textarea)]
         $.8[(<blockquote)]
      ]
#    wronginators
      $.2[
         $.1[(</td>)]
      ]
#    wronginators-2
      $.3[
         $.1[(</li>)]
      ]
   ]

# ����������� ���� $1<t->
   $_reT2[
#    rightinators
      $.1[
          $.1[(</table>)]
          $.2[(</h[1-9]>)]
          $.3[(</(u|o)l>)]
          $.4[(</div>)]
          $.5[(</p>)]
          $.6[(</form>)]
          $.7[(</textarea>)]
          $.8[(</blockquote>)]
         ]
#    wronginators
      $.2[
          $.1[(<td[^^>]*>)]
         ]
#    wronginators-2
      $.3[
          $.1[(<li[^^>]*>)]
         ]
   ]

   $_markPrefix[^#C8]
   $_mark1[^#C8<:-t>] 
   $_mark2[^#C8<:t->] 
   $_mark3[^#C8<:::>]
#   (*) wronginator mark: 
#       � ������������ ���� <t->(*).....<-t> 
#       & vice versa -- ��������� ��������
#       � ��� � <t->(*)....(*)<-t> -- �� ��������

   $_mark4[^#C8<:-:>]
# (!) ultimate wronginator mark: 
# ��������� �� �������� ���� ���� <t->(!).....<-t> 

   $_prefix1[<p class="auto" id="p]  
   $_prefix2[">]
   $_postfix[</p>]


#---- Public -----
@process[aText;aOptions][lIgnored;lText;piece;pos;pos2;pos_u;pieces_inside;insert_p;inside]
  ^cleanMethodArgument[]

# ������� �� ������ �������, ������ ����� ������������ � ������ ���������
#  $aText[^aText.replace[^table::create[nameless]{$_ignoreMark	
#$_markPrefix	}]]

# ���������� �� ������ ��� �����. ������� ���� ���������������
  $lIgnored[^aText.match[$_reIgnore][gi]]
  $aText[^aText.match[$_reIgnore][gi]{$_ignoreMark}]

# insert terminators appropriately
  ^_reT0.foreach[k;v]{
    $aText[^aText.match[$v][gi]{${_mark1}${match.1}${_mark2}}]
  }

  ^_reT1.1.foreach[k;v]{
    $aText[^aText.match[$v][gi]{${_mark1}${match.1}}]
  }

  ^_reT2.1.foreach[k;v]{
    $aText[^aText.match[$v][gi]{${match.1}${_mark2}}]
  }

  ^_reT1.2.foreach[k;v]{
    $aText[^aText.match[$v][gi]{${_mark3}${_mark1}${match.1}}]
  }

  ^_reT2.2.foreach[k;v]{
    $aText[^aText.match[$v][gi]{${match.1}${_mark2}${_mark3}}]
  }

  ^_reT1.3.foreach[k;v]{
    $aText[^aText.match[$v][gi]{${_mark4}${_mark1}${match.1}}]
  }

  ^_reT2.3.foreach[k;v]{
    $aText[^aText.match[$v][gi]{${match.1}${_mark2}${_mark4}}]
  }

# wrap whole text in terminator pair
  $aText[${_mark2}${aText}${_mark1}]

# 2bis. swap <t-><br /> -> <br /><t->
  $aText[^aText.match[(${_mark2})((\s*<br[^^>]*>)+)][gi]{${match.2}$match.1}]

# noneedin: > eliminating multiple breaks
  $aText[^aText.match[((<br[^^>]*>\s*)+)(${_mark1})][g]{$match.3}]

# 2. cleanup <t->\s<-t>
  $lText[]
  ^while($lText ne $aText){
    $lText[$aText]
    $aText[^aText.match[(${_mark2})((\s|(<br[^^>]*>|${_mark3}|${_mark4}))*)(${_mark1})][gi]{$match.2}]
  }

# 3. replace each <t->....<-t> to <p class="auto">....</p>
  $lPCount(0)
  $lPieces[^aText.split[$_mark2;lv]]
  $lSizeofMark1[^mark1.length[]]

  $lText[]

  ^lPieces.menu{

    $piece[^lPieces.piece.match[\n][g]{}]
	  $pos[^piece.pos[$_mark1]]
    $pos2[^piece.pos[$_mark3]]
    $pos_u[^piece.pos[$_mark4]]
    
    ^if(($pos >= 0) && ($pos_u < 0)){
      $insert_p(false)
         
      ^if($pos2 < 0){
        $insert_p(true)
      }{
         $pieces_inside[^piece.split[$_mark3;lv]]
         ^if($pieces_inside < 3){
           $insert_p(true) 
         }
       }

      ^if($insert_p){
           $inside[^piece.mid(0;$pos)]
           $inside[^inside.replace[^table::create[nameless]{$_mark3	}}]]

           ^if(^inside.length[]){
             ^lPCount.inc[]
             $piece[<a name="p-${lPCount}"></a>${_prefix1}-${lPCount}${_prefix2}${inside}${_postfix}^piece.mid($pos+$lSizeofMark1)]
           }
      }
    }

    $lText[${lText}$piece]
  }

# 4. remove unused <t-> & <-t>
	$aText[^lText.replace[^table::create[nameless]{$_mark1	
$_mark2	
$_mark3	
$_mark4	}]]
# -. done with P

# ������� ������ <br>-� ����� ��������
  $aText[^aText.match[(</(?:p|h[1-9]|table|(?:u|o)l|div|form|textarea|blockquote)[^^>]*>)\s*(?:<br[^^>]*>\s*)+(<[^^>]+)][gi]{$match.1 $match.2}]]

# ��������� ������� �����, ������� ���� ���� ������������
  $result[^aText.match[$_ignoreMark][g]{${lIgnored.1}^lIgnored.offset(1)}]


