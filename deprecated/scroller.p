#################################################################################################################
# $Id: scroller.p,v 1.14 2005/08/16 07:54:59 misha Exp $
#################################################################################################################

@CLASS
scroller


###########################################################################
# РєРѕРЅСЃС‚СЂСѓРєС‚РѕСЂ. РїРµСЂРІС‹Рµ 2 РїР°СЂР°РјРµС‚СЂР° РѕР±СЏР·Р°С‚РµР»СЊРЅС‹. 
# РїСЂРё РёРЅРёС†РёР°Р»РёР·Р°С†РёРё СЂР°СЃС‡РёС‚С‹РІР°СЋС‚СЃСЏ РІСЃРµ РїР°СЂР°РјРµС‚СЂС‹ РїРѕСЃС‚СЂР°РЅРёС‡РЅРѕР№ РЅР°РІРёРіР°С†РёРё

# РґРѕСЃС‚СѓРїРЅС‹Рµ РїРѕР»СЏ:
# $items_count 			- РєРѕР»РёС‡РµСЃС‚РІРѕ Р·Р°РїРёСЃРµР№
# $limit		 		- РєРѕР»РёС‡РµСЃС‚РІРѕ Р·Р°РїРёСЃРµР№ РЅР° СЃС‚СЂР°РЅРёС†Сѓ
# $page_count 			- РєРѕР»РёС‡РµСЃС‚РІРѕ СЃС‚СЂР°РЅРёС†
# $current_page 		- N С‚РµРєСѓС‰РµР№ СЃС‚СЂР°РЅРёС†С‹
# $current_page_number	- РїРѕСЂСЏРґРєРѕРІС‹Р№ РЅРѕРјРµСЂ С‚РµРєСѓС‰РµР№ СЃС‚СЂР°РЅРёС†С‹
# $current_page_name 	- РЅР°Р·РІР°РЅРёРµ С‚РµРєСѓС‰РµР№ СЃС‚СЂР°РЅРёС†С‹
# $offset 				- СЃРјРµС‰РµРЅРёРµ РґР»СЏ РїРѕР»СѓС‡РµРЅРёРµ РїРµСЂРІРѕР№ Р·Р°РїРёСЃРё С‚РµРєСѓС‰РµР№ СЃС‚СЂР°РЅРёС†С‹ (РЅР°РґРѕРґР»СЏ sql Р·Р°РїСЂРѕСЃРѕРІ)
# $direction 			- РЅР°РїСЂР°РІР»РµРЅРёРµ РЅСѓРјРµСЂР°С†РёРё СЃС‚СЂР°РЅРёС† ( < 0 С‚Рѕ РїРѕСЃР»РµРґРЅСЏСЏ СЃС‚СЂР°РЅРёС†Р° РёРјРµРµС‚ РЅРѕРјРµСЂ 1 )
# $first_page 			- N РїРµСЂРІРѕР№ СЃС‚СЂР°РЅРёС†С‹
# $last_page 			- N РїРѕСЃР»РµРґРЅРµР№ СЃС‚СЂР°РЅРёС†С‹
# $form_name			- РЅР°Р·РІР°РЅРёРµ СЌР»РµРјРµРЅС‚Р° С„РѕСЂРјС‹ С‡РµСЂРµР· РєРѕС‚РѕСЂС‹Р№ РїРµСЂРµРґР°РµС‚СЃСЏ РЅРѕРјРµСЂ СЃС‚СЂР°РЅРёС†С‹ (РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ "page")

# РїСЂРёРјРµСЂ СЃРѕР·РґР°РЅРёСЏ РѕР±СЉРµРєС‚Р°: $my_scroller[^scroller::init[$total_items_count;50;page]]

@init[items_count;items_per_page;form_name;direction;page][is_full_page]
^if(!def $items_count){
	^throw[scroller;Items count must be defined.]
}
^if(!^items_per_page.int(0)){
	^throw[scroller;Items per page must be defined and not equal 0.]
}
$self.mode[xml]
$self.form_name[^if(def $form_name){$form_name}{page}]
^if(!def $page){
	$page[$form:[$self.form_name]]
}
$self.items_count(^items_count.int(0))
$limit(^items_per_page.int(0))
$page_count(^math:ceiling($self.items_count / $limit))
^if(^direction.int(0) < 0){
	$current_page(^page.int($page_count))
	^if($current_page > $page_count){
		$current_page($page_count)
	}{
		^if($current_page < 1){$current_page(1)}
	}
	$current_page_number($page_count - $current_page + 1)
	$current_page_name($current_page_number)
	^if($page_count && $current_page < $page_count){
		$is_full_page(^if($self.items_count % $limit){1}{0})
		$offset($self.items_count % $limit + ($page_count - $current_page - $is_full_page) * $limit)
	}{
		$offset(0)
	}
	$self.direction(-1)
	$first_page($page_count)
	$last_page(1)
}{
	$current_page(^page.int(1))
	^if($current_page > $page_count){
		$current_page($page_count)
	}{
		^if($current_page < 1){$current_page(1)}
	}
	$current_page_number($current_page)
	$current_page_name($current_page)
	$self.direction(+1)
	$first_page(1)
	$last_page($page_count)
	^if($page_count){
		$offset(($current_page - 1) * $limit)
	}{
		$offset(0)
	}
}
#end @init[]




###########################################################################
# РІС‹РІРѕРґРёС‚ html РїРѕСЃС‚СЂР°РЅРёС‡РЅРѕР№ РЅР°РІРёРіР°С†РёРё
# РїСЂРёРЅРёРјР°РµС‚ РїР°СЂР°РјРµС‚СЂС‹ (С…РµС€)
# $mode				- С‚РёРї РІС‹РІРѕРґР°. СЃРµР№С‡Р°СЃ СѓРјРµРµС‚: html|xml
# $nav_count		- РєРѕР»РёС‡РµСЃС‚РІРѕ РѕС‚РѕР±СЂР°Р¶Р°РµРјС‹С… СЃСЃС‹Р»РѕРє РЅР° СЃС‚СЂР°РЅРёС†С‹ (РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ 5)
# $separator		- СЂР°Р·РґРµР»РёС‚РµР»СЊ РїСЂРѕРїСѓСЃРєРѕРІ РІ СЃС‚СЂР°РЅРёС†Р°С… (РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ "вЂ¦")
# $tag_name			- С‚РµРі РІ РєРѕС‚РѕСЂРѕРј РІСЃРµ РІС‹РІРѕРґРёРј
# $tag_attr			- Р°С‚С‚СЂРёР±СѓС‚С‹ С‚РµРіР°
# $title			- Р·Р°РіРѕР»РѕРІРѕРє РїРѕСЃС‚СЂР°РЅРёС‡РЅРѕР№ РЅР°РІРёРіР°С†РёРё (РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ "РЎС‚СЂР°РЅРёС†С‹: ")
# $left_divider		- СЂР°Р·РґРµР»РёС‚РµР»СЊ РјРµР¶РґСѓ "РќР°Р·Р°Рґ" Рё РїРµСЂРІРѕР№ СЃС‚СЂР°РЅРёС†РµР№ (РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ "")
# $right_divider	- СЂР°Р·РґРµР»РёС‚РµР»СЊ РјРµР¶РґСѓ РїРѕСЃР»РµРґРЅРµР№ СЃС‚СЂР°РЅРёС†РµР№ Рё "Р”Р°Р»СЊС€Рµ" (РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ: "|")
# $back_name		- "< РќР°Р·Р°Рґ"
# $forward_name		- "Р”Р°Р»СЊС€Рµ >"
# $target_url		- URL РєСѓРґР° РјС‹ Р±СѓРґРµРј РїРµСЂРµС…РѕРґРёС‚СЊ (РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ "./")

# РїСЂРёРјРµСЂ РІС‹Р·РѕРІР° (РїРѕСЃР»Рµ СЃРѕР·РґР°РЅРёСЏ РѕР±СЉРµРєС‚Р° $scroller):
# ^my_scroller.print[
#		$.mode[html]
#		$.target_url[./]
#		$.nav_count(9)
#		$.left_divider[|]
# ]

@print[in_params][lparams;nav_count;page_number;first_nav;last_nav;separator;url_separator;ipage;i;title]
^if($page_count > 1){
	$lparams[^hash::create[$in_params]]
	^if(def $lparams.mode){
		$mode[$lparams.mode]
	}
	$nav_count(^lparams.nav_count.int(5))
	$first_nav($current_page_number - $nav_count \ 2)
	^if($first_nav < 1){
		$first_nav(1)
	}
	$last_nav($first_nav + $nav_count - 1)
	^if($last_nav > $page_count){
		$last_nav($page_count)
		$first_nav($last_nav - $nav_count)
		^if($first_nav < 1){$first_nav(1)}
	}
	$separator[^if(def $lparams.separator){$lparams.separator}{вЂ¦}]
	$url_separator[^if(^lparams.target_url.pos[?]>=0){^taint[&]}{?}]
	^if(def $lparams.tag_name){
		<$lparams.tag_name $lparams.tag_attr>
	}
	$title[^if(def $lparams.title){$lparams.title}{РЎС‚СЂР°РЅРёС†С‹: }]
	^if($mode eq "html"){
		$title
	}{
		<title>$title</title>
		^if(def $lparams.left_divider){<left-divider>$lparams.left_divider</left-divider>}
		^if(def $lparams.right_divider){<right-divider>$lparams.right_divider</right-divider>}
	}
	^if($current_page != $first_page){
		^print_nav_item[back;^if(def $lparams.back_name){$lparams.back_name}{&larr^; РќР°Р·Р°Рґ};$lparams.target_url;$url_separator;^eval($current_page - $direction)]
		^if($mode eq "html"){
			^if(def $lparams.left_divider){$lparams.left_divider}
		}
	}
	^if($first_nav > 1){
		^print_nav_item[first;1;$lparams.target_url;$url_separator;$first_page]
		^if($first_nav > 2){
			^print_nav_item[separator;$separator]
		}
	}
	^for[i]($first_nav;$last_nav){
		^if($direction < 0){
			$ipage($page_count - $i + 1)
		}{
			$ipage($i)
		}
		^print_nav_item[^if($ipage == $current_page){current};$i;$lparams.target_url;$url_separator;$ipage]
	}
	^if($last_nav < $page_count){
		^if($last_nav < $page_count - 1){
			^print_nav_item[separator;$separator]
		}
		^print_nav_item[last;$page_count;$lparams.target_url;$url_separator;$last_page]
	}
	^if($current_page != $last_page){
		^if($mode eq "html"){
			^if(def $lparams.right_divider){$lparams.right_divider}{|}
		}
		^print_nav_item[forward;^if(def $lparams.forward_name){$lparams.forward_name}{Р”Р°Р»СЊС€Рµ&nbsp^;&rarr^;};$lparams.target_url;$url_separator;^eval($current_page + $direction)]
	}
	^if(def $lparams.tag_name){</$lparams.tag_name>}
}
#end @print[]



###########################################################################
# РІС‹РІРѕРґРёС‚ СЌР»РµРјРµРЅС‚ РїРѕСЃС‚СЂР°РЅРёС‡РЅРѕР№ РЅР°РІРёРіР°С†РёРё
@print_nav_item[type;name;url;url_separator;page_num]
^if($mode eq "html"){
	^if($type eq "separator"){
		$result[$name]
	}{
		^if($type ne "current" && def $page_num){
			$result[<a href="^untaint[html]{^if(def $url){$url}{./}^if($page_num != $first_page){${url_separator}$form_name=$page_num}}">$name</a>]]
		}{
			$result[$name]
		}
	}
}{
	$result[<page
		^if(def $type){ type="$type"}
		^if($type ne "current" && def $page_num){
			href="^untaint[xml]{^if(def $url){$url}{./}^if($page_num != $first_page){${url_separator}$form_name=$page_num}}"
		}
		num="$name"
	/>]
}
#end @print_nav_item[]
