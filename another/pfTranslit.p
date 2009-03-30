@CLASS
pfTranslit

@toLat[str]
  $result[^str.replace[$rtr]]
  
@toRus[str][temp]
  $temp[^str.replace[$rtl_l2]]
  $temp[^temp.replace[$rtl_l]]
  $result[^temp.replace[$rtl_s]]

@auto[]
  $rtl_s[^table::create[nameless]{а	а	
b	б	
v	в	
g	г	
d	д	
e	е	
z	з	
i	и	
j	й	
k	к	
l	л	
m	м	
n	н	
o	о	
p	п	
r	р	
s	с	
t	т	
u	у	
f	ф	
h	х	
c	ц	
y	ы
x	х
А	А	
B	Б	
V	В	
G	Г	
D	Д	
E	Е	
Z	З	
I	И	
J	Й	
K	К	
L	Л	
M	М	
N	Н	
O	О	
P	П	
R	Р	
S	С	
T	Т	
U	У	
F	Ф	
H	Х
X	Х	
C	Ц	
Y	Ы
'	ь}]

  $rtl_l2[^table::create[nameless]{sch	щ
Sch	Щ
tsja	тся
}]

  $rtl_l[^table::create[nameless]{e'	э
E'	Э
sh	ш	
ch	ч	
yu	ю	
ya	я	
yo	Ё	
ja	я
ju	ю
ts	ц
ei	ей
ej	ей
#je	e
zh	ж
Sh	Ш	
Ch	Ч	
Yu	Ю	
Ya	Я	
Yo	Ё	
Zh	Ж
Ts	ц
#Je	Е
EI	ЕЙ
Ja	Я
Ju	Ю}]
  
  $rtr[^table::create[nameless]{щ	shch	
ш	sh
ч	ch
ю	yu	
я	ya
ё	yo	
ж	zh	
э	e'	
а	а	
б	b	
в	v	
г	g	
д	d	
е	e	
з	z	
и	i	
й	j	
к	k	
л	l	
м	m	
н	n	
о	o	
п	p	
р	r	
с	s	
т	t	
у	u	
ф	f	
х	h	
ц	c	
ъ	'	
ы	y	
ь	'
Щ	Shch	
Ш	Sh
Ч	Ch
Ю	Yu	
Я	Ya
Ё	Yo	
Ж	Zh	
Э	E'	
А	А	
Б	B	
В	V	
Г	G	
Д	D	
Е	E	
З	Z	
И	I	
Й	J	
К	K	
Л	L	
М	M	
Н	N	
О	O	
П	P	
Р	R	
С	S	
Т	T	
У	U	
Ф	F	
Х	H	
Ц	C	
Ъ	'	
Ы	Y	
Ь	'}]
