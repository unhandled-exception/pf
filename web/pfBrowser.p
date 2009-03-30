# PF Library

#@module   Browser Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

@CLASS
pfBrowser

#@doc
##  Класс с функциями для работы с браузером 
##  (на самом деле с http-запросом, но это не принципиально).
##
##  Цель: сделать небольшую прокладку между кодом контроллером и функциями браузера,
##        дабы появилась возможность прозрачно "подменить" данные при работе вне браузера,
##        например, для организации юнит-тестов.
#/doc

#---- Constructor's -----

@create[aOptions]
  ^_initialize[]
    
@auto[]
  ^_initialize[]
  
@_initialize[]
  $_browser_types[^table::create{name
opera
msie
mozilla
safari
netscape
}]

  $_platform_types[^table::create{name
win
mac
linux
freebsd
}]

#----- Properties -----
@GET_OS[]
  $result[^getOS[$env:HTTP_USER_AGENT]]

@GET_form[]
  $_result[$form:fieds]

#----- Public -----

@getAgent[user_agent]
	^if(def $user_agent){
		^_browser_types.menu{
			^if(!def $result){
				$result[^_get_agent[$user_agent;$_browser_types.name]]
			}
		}
	}
	^if(!def $result){
		$result[
			$.name[other]
			$.ver(0)
			$.subver(0)
			$.fullver(0)
		]
	}

@getOS[user_agent]
	^if(def $user_agent){
		^_platform_types.menu{
			^if(!def $result){
				$result[^_get_os[$user_agent;$_platform_types.name]]
			}
		}
	}
	^if(!def $result){
		$result[
			$.name[other]
		]
	}


#----- Private -----

@_get_agent[user_agent;name]
	$result[^hash::create[]]
	^user_agent.match[(?:$name).((\d+)(?:\.(\d+)))?][i]{
		$result[
			$.name[$name]
			$.ver(^match.2.int(0))
			$.subver(^match.4.int(0))
			$.fullver(^match.1.double(0))
		]
	}

@_get_os[user_agent;name]
	$result[^hash::create[]]
	^user_agent.match[$name][i]{
		$result[
			$.name[$name]
		]
	}
  