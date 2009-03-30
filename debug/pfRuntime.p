# PF Library

#@module   Runtime Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

@CLASS
pfRuntime

@USE
pf/tests/pfAssert.p

#@doc
##  Авторы некоторых методов:
##  ----------------------------------------
##    Михаил Петрушин (misha@design.ru).
##    http://misha.design.ru/
#/doc

#----- Constructor -----
@auto[]
  $_parserVersion[^hash::create[]]

  $_memoryLimit(4096)
  $_lastMemorySize($status:memory.used)

@create[]
  ^pfAssert:fail[Класс pfRuntime может быть только статическим.]

#----- Properties -----

@GET_parserVersion[]
	^if(!def $_parserVersion && def $env:PARSER_VERSION){
		^env:PARSER_VERSION.match[^^(\d+)\.((\d+)\.(\d+))(\S*)\s*(.*)][]{
			$result[
				$.name[$match.1]
				$.ver(^match.3.int(0))
				$.subver(^match.4.int(0))
				$.fullver(^match.2.double(0))
				$.sp[$match.5]
				$.comment[$match.6]
			]
		}
	}{
		  $result[$_parserVersion]
	 }

@GET_memoryLimit[]
  $result($_memoryLimit)

@SET_memoryLimit[]
  $_memoryLimit($_memoryLimit)

#----- Methods -----

@compact[aOptions]
## Выполняет сборку мусора, если c момента последней сборки мусора было выделено
## больше $memoryLimit килобайт.
  ^if(!($aOptions is hash)){$aOptions[^hash::create[]]}
  ^if(^aOptions.isForce.int(0) || ($status:memory.used - $_lastMemorySize) > $memoryLimit){
     ^memory:compact[]
     $_lastMemorySize($status:memory.used)
  }
