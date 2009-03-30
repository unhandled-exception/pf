# PF Library
# Copyright (c) 2006-07 Oleg Volchkov

#@module   URL Transliterator Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

@CLASS
pfURLTranslit

@USE
pf/types/pfClass.p

@BASE
pfClass

#@doc
##  ���� �� Parser php-������ �� ������� http://pixel-apes.com/translit
##
##  �������������� ������ (���������� �� � ������������ � �������� URL).
##  ��������� ����� � ����� ��������, � ������� + ����� ���������� �������������
##  ����� �� �������� (������� ����� ������ ��� ����� ������)
##  ����������� ��. �� http://pixel-apes.com/translit/article 
##
##  ������������ ������:
##  --------------------
##  Translit PHP class.
##  v.1.2 
##  12 November 2005
##
##  (c) WackoWiki team ( http://wackowiki.com/team/ ), 2003-2004
##  (c) Pixel-Apes team ( http://pixel-apes.com/ ), 2004
##  (c) JetStyle ( http://jetstyle.ru/ ), 2004
##  Maintainers -- Roman Ivanov <thingol@mail.ru>,
##                 Kuso Mendokusee <mendokusee@gmail.com>
#/doc

@create[]
  ^BASE:create[]
  ^_init[]
  
@auto[]
  ^_init[]
  
@toURL[aString;aOptions][lSlash]
## ������������� ������ � "�������� �������� URL".
## aOptions.allowSlashes(0) - ������������ �� ������ "/", ��������� ��� ��������������, 
##                            ���� ������� ��� �� ������
  ^cleanMethodArgument[]
  $lSlash[^if(^aOptions.allowSlashes.int(0)){/}]
  
  $result[^aString.trim[both]]
  $result[^result.match[[_\s\.,?!\[\](){}]+][g]{_}]
  $result[^result.match[(?:-{2,}|_-+_)][g]{--}]
  $result[^result.match[[_\-]+^$][g]{}]

  $result[^result.lower[]]

  $result[^result.match[(?:�|�)([$_vowel])][g]{j$match.1}]
  $result[^result.match[(?:�|�)][g]{}]

  $result[^result.replace[$_letters]]

  $result[^result.match[j{2,}][g]{}]
  $result[^result.match[[^^${lSlash}0-9a-z_\-]+][g]{}]

@toSupertag[aString;aOptions][lSlash]
## ������������� ������ � "��������" -- �������� ������� 
## �������������, ��������� �� ��������� ���� � ����.
## aOptions.allowSlashes(0) - ������������ �� ������ "/", ��������� ��� ��������������, 
##                            ���� ������� ��� �� ������
  ^cleanMethodArgument[]
  $lSlash[^if(^aOptions.allowSlashes.int(0)){/}]

  $result[^toURL[$aString;$aOptions]]
  $result[^result.match[[^^${lSlash}0-9a-zA-Z\-]+][g]{}]
  $result[^result.match[[\-_]+][g]{-}]
  $result[^result.match[-+^$][g]{}]

@toWiki[aString;aOptions][lStrings;lSlash]
## ������������� ������������ ������ � ����-�����
## ��������: "������ ���" => "���������"
## aOptions.allowSlashes(0) - ������������ �� ������ "/", ��������� ��� ��������������, 
##                            ���� ������� ��� �� ������
  ^cleanMethodArgument[]
  $lSlash[^if(^aOptions.allowSlashes.int(0)){/}]

  $result[^aString.match[[^^\- 0-9a-zA-Z�-��-߸�${lSlash}]+][g]{ }]

  $lStrings[^result.split[ ]]
  $result[]
  ^lStrings.menu{
    $result[${result}^lStrings.piece.match[^^\s*(.)(.*)][]{^match.1.upper[]^if(def $match.2){^match.2.lower[]}}]
  }

@fromWiki[aString]
## ������� ������������ ��������� ��� �������� ������ �� ����-������
## ��������: "���������" => "������ ���"
  $result[^aString.match[([^^\-\/])([A-Z�-�][a-z�-�0-9])][g]{$match.1 $match.2}]
  $result[^result.match[([^^0-9 \-\/])([0-9])][g]{$match.1 $match.2}]

@encode[aString;aOptions]
## ����������������� �����
## aOptions.allowSlashes(0) - ������������ �� ������ "/", ��������� ��� ��������������, 
##                            ���� ������� ��� �� ������
  $result[^bidi[$aString;encode;$aOptions]]

@decode[aString;aOptions]
## �� ����������������� ����� :)
## aOptions.allowSlashes(0) - ������������ �� ������ "/", ��������� ��� ��������������, 
##                            ���� ������� ��� �� ������
  $result[^bidi[$aString;decode;$aOptions]]


@bidi[aString;aDirection;aOptions][lSlash]
## ������������� ������ � "��������� ���������� URL"
## � ������������ ��������������.
## ������ �������� $aDirection[encode|decode] ��������� ������������
## ������ ������� � ��������������� ��������
## aOptions.allowSlashes(0) - ������������ �� ������ "/", ��������� ��� ��������������, 
##                            ���� ������� ��� �� ������
  ^cleanMethodArgument[]
  $lSlash[^if(^aOptions.allowSlashes.int(0)){/}]

  ^if($aDirection eq "encode"){
    $result[^aString.match[[^^\- \'_0-9a-zA-Z�-��-߸�${lSlash}]][g]{}]
    $result[^result.match[([�-��-߸� ]+)][g]{+^match.1.replace[$_tran]+}]
  }{
     $result[$aString]
     $result[^result.match[\+(.*?)\+][g]{^match.1.replace[$_detran]}]
     ^if(!def $lSlash){^result.replace[^table::create[nameless]{/	}]}
	 }
  
@_init[]
## �������������� ����������� ����������

  $_letters[^table::create{from	to
�	a
�	b
�	v
�	g
�	d
�	e
�	z
�	i
�	k
�	l
�	m
�	n
�	o
�	p
�	r
�	s
�	t
�	u
�	f
�	y
�	e
�	j
�	x
�	e
�	zh
�	ts
�	ch
�	sh
�	sch
�	ju
�	ja}]

  $_vowel[���������]

  $_tran[^table::create{from	to
�	A
�	B
�	V
�	G
�	D
�	E
�	JO
�	ZH
�	Z
�	I
�	JJ
�	K
�	L
�	M
�	N
�	O
�	P
�	R
�	S
�	T
�	U
�	F
�	KH
�	C
�	CH
�	SH
�	SHH
�	_~
�	Y
�	_'
�	EH
�	JU
�	JA
�	a
�	b
�	v
�	g
�	d
�	e
�	jo
�	zh
�	z
�	i
�	jj
�	k
�	l
�	m
�	n
�	o
�	p
�	r
�	s
�	t
�	u
�	f
�	kh
�	c
�	ch
�	sh
�	shh
�	~
�	y
�	'
�	eh
�	ju
�	ja
 	__
_	__}]

  $_detran[^table::create{from	to
SHH	�
JO	�
ZH	�
JJ	�
KH	�
CH	�
SH	�
EH	�
JU	�
JA	�
A	�
B	�
V	�
G	�
D	�
E	�
Z	�
I	�
K	�
L	�
M	�
N	�
O	�
P	�
R	�
S	�
T	�
U	�
F	�
C	�
Y	�
shh	�
_'	�
_~	�
jo	�
zh	�
jj	�
kh	�
ch	�
sh	�
eh	�
ju	�
ja	�
a	�
b	�
v	�
g	�
d	�
e	�
z	�
i	�
k	�
l	�
m	�
n	�
o	�
p	�
r	�
s	�
t	�
u	�
f	�
c	�
~	�
y	�
'	�
__	 }]
