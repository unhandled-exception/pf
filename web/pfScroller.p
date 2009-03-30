# PF Library

#@info     Скролер (построение "страничной" навигации)
#@author   Oleg Volchkov <oleg@volchkov.net>                                                                                                          
#@web      http://oleg.volchkov.net

## В текущей реализации - класс-адаптер для класса scroller Михаила Петрушина.
## http://www.parser.ru/examples/mscroller/
## Прямой вызов оригинального скроллера в контексте классов PF запрещен.

## Важные отличия: если не определен номер текущей страницы, то он не берется из
## formName, а считается равным 1. Это нужно, чтобы избежать обращения к классу
## form непосредственно из скроллера. Кроме того в методе _print удалены некоторые
## "лишние" параметры (tag_name, tag_attr).

@CLASS
pfScroller

@USE
pf/deprecated/scroller.p
pf/types/pfClass.p

@BASE
pfClass

#----- Constructor -----

@create[aItemsCount;aItemsPerPage;aCurrentPage;aOptions]
## aOptions.formName[page] - название элемента формы через который передается номер страницы.
## aOptions.direction[forward|backward] - направление нумерации страниц
  ^pfAssert:isTrue(def $aItemsCount)[Не задано количество элементов скролера.]
  ^pfAssert:isTrue($aItemsCount >= 0)[Количество элементов скролера не может быть меньше нуля.]
  ^pfAssert:isTrue(def $aItemsPerPage)[Не задано количество элементов на странице скролера.]
  ^pfAssert:isTrue($aItemsPerPage >= 1)[Количество элементов на странице скролера не может быть меньше 1.]

  ^cleanMethodArgument[]
  $_directions[$.forward(1) $.backward(-1) $._default(1)]
  $_scroller[^scroller::init[$aItemsCount;$aItemsPerPage;$aOptions.formName;$_directions.[$aOptions.direction];$aCurrentPage]]

#----- Properties -----

# $itemsCount 		- количество записей
# $limit		- количество записей на страницу
# $offset 		- смещение для получение первой записи текущей страницы (надодля sql запросов)
# $pagesCount 		- количество страниц
# $currentPage 		- N текущей страницы
# $currentPageNumber	- порядковый номер текущей страницы
# $currentPageName 	- название текущей страницы
# $direction 		- направление нумерации страниц ( < 0 то последняя страница имеет номер 1 )
# $firstPage 		- N первой страницы
# $lastPage 		- N последней страницы
# $formName		- название элемента формы через который передается номер страницы (по умолчанию "page")

@GET_itemsCount[]
  $result[$_scroller.items_count]

@GET_limit[]
  $result[$_scroller.limit]

@GET_offset[]
  $result[$_scroller.offset]

@GET_pagesCount[]
  $result[$_scroller.page_count]

@GET_currentPage[]
  $result[$_scroller.current_page]

@GET_currentPageNumber[]
  $result[$_scroller.current_page_number]

@GET_currentPageName[]
  $result[$_scroller.current_page_name]

@GET_direction[]
  ^if($_scroller.direction >= 0){
    $result[forward]
  }{
     $result[backward]
   }

@GET_firstPage[]
  $result[$_scroller.first_page]

@GET_lastPage[]
  $result[$_scroller.last_page]

@GET_formName[]
  $result[$_scroller.form_name]

#----- Public -----

@asHTML[aOptions]
  ^_print[html;$aOptions]

@asXML[aOptions]
  ^_print[xml;$aOptions]

#----- Private -----

@_print[aMode;aOptions]
## выводит html постраничной навигации
## принимает параметры (хеш)
## $aMode			- тип вывода. сейчас умеет: html|xml
## aOptions.navCount		- количество отображаемых ссылок на страницы (по умолчанию 5)
## aOptions.separator		- разделитель пропусков в страницах (по умолчанию "…")
## aOptions.title		- заголовок постраничной навигации (по умолчанию "Страницы: ")
## aOptions.leftDivider		- разделитель между "Назад" и первой страницей (по умолчанию "")
## aOptions.rightDivider	- разделитель между последней страницей и "Дальше" (по умолчанию: "|")
## aOptions.backName		- "< Назад"
## aOptions.forwardName		- "Дальше >"
## aOptions.targetURL		- URL куда мы будем переходить (по умолчанию "./")

  ^cleanMethodArgument[]

  $result[^_scroller.print[
     $.mode[$aMode]
     $.nav_count[$aOptions.navCount]
     $.separator[$aOptions.separator]
     $.title[$aOptions.title]
     $.left_divider[$aOptions.leftDivider]
     $.right_divider[$aOptions.rightDivider]
     $.back_name[$aOptions.backName]
     $.forward_name[$aOptions.forwardName]
     $.target_url[$aOptions.targetURL]
  ]]
