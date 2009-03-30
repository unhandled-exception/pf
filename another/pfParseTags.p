@CLASS
pfParseTags

@all[aStr]
  $result[^url[$aStr]]
#  $result[^makeBR[$result]]

#------- Тэги --------

@stripTags[aStr]
## Удаляет htm-теги из строки
# Фридл. Изд 2. Стр. 225.
  $result[^aStr.match[<(?:"[^^"]*"|'[^^']*'|[^^'">])*>][g]{}]

#------- Псевдотеги --------

@url[aStr]
## [url(=адрес)]Имя[/url]
  $result[^aStr.match[\[url(?:=(.+))?\](.+?)\[/url\]][gi]{<a href="^if(def $match.1){$match.1}{$match.2}">$match.2</a>}]

#------- Переносы строк --------
@makeP[aStr]
## Заключаем абзацы в тег <p>
  $result[^undoEnter[$aStr]]
  $result[^result.match[^^(.+)^$][gm]{<p>$match.1</p>}]

@makeBR[aStr]
## Ставим в конце строк тег <br />
  $result[^aStr.match[^^(.+)^$][gm]{$match.1<br />}]

@makeEnter[aStr][repl]
## Заменяем переносы строк на псевдотег <enter>
  $repl[^table::create[nameless]{^taint[^#0A]	<enter>}]
  $result[^aStr.replace[$repl]]

@undoEnter[aStr][repl]
## Заменяем псевдотег <enter> на переносы строк и убираем тег <nobr> и делаем его "as-is"
## Метод используется перед передачей текста в <textarea>
  $repl[^table::create[nameless]{<enter>	^taint[^#0A]}]
  $result[^aStr.replace[$repl]]
  $result[^result.match[</?nobr>][gi]{}]
