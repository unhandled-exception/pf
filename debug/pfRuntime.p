# PF Library

@CLASS
pfRuntime

@USE
pf/tests/pfAssert.p

#----- Static constructor -----
@auto[]
  $_parserVersion[^hash::create[]]

  $_memoryLimit(4096)
  $_lastMemorySize($status:memory.used)   
  $_compactsCount(0)  
  
  $_profiled[$.last[] $.all[^hash::create[]]]
# Нужно ли накапливать статистику профилировщика
  $_enableProfilerLog(true)

@create[]
  ^pfAssert:fail[Класс pfRuntime может быть только статическим.]

#----- Properties -----

@GET_parserVersion[]
  ^if(!$_parserVersion && def $env:PARSER_VERSION){
    ^env:PARSER_VERSION.match[^^(\d+)\.((\d+)\.(\d+))(\S*)\s*(.*)][]{
      $_parserVersion[
        $.name[$match.1]
        $.ver(^match.3.int(0))
        $.subver(^match.4.int(0))
        $.fullver(^match.2.double(0))
        $.sp[$match.5]
        $.comment[$match.6]
      ]
    }
  }
	$result[$_parserVersion]

@GET_memoryLimit[]
  $result($_memoryLimit)

@SET_memoryLimit[aMemoryLimit]
  $_memoryLimit($aMemoryLimit)

@GET_compactsCount[]
  $result($_compactsCount)

@GET_profiled[]
  $result[$_profiled]

@GET_enableProfilerLog[]
  $result($_enableProfilerLog)

@SET_enableProfilerLog[aCond]
  $_enableProfilerLog($aCond)

#----- Methods -----

@compact[aOptions]
## Выполняет сборку мусора, если c момента последней сборки мусора было выделено
## больше $memoryLimit килобайт.
  $result[]
  ^if(!($aOptions is hash)){$aOptions[^hash::create[]]}
  ^if(^aOptions.isForce.int(0) || ($status:memory.used - $_lastMemorySize) > $memoryLimit){
     ^memory:compact[]
     $_lastMemorySize($status:memory.used)  
     ^_compactsCount.inc[]
  }     

@resources[]
## Возвращает хеш с информацией о времени и памяти, затраченных на данный момент
  $result[
    $.time($status:rusage.tv_sec + $status:rusage.tv_usec/1000000.0)
    $.utime($status:rusage.utime)
    $.stime($status:rusage.stime)

    $.allocated($status:memory.ever_allocated_since_start)
    $.compacts($compactsCount)
    $.used($status:memory.used)
    $.free($status:memory.free)
  ]

@profile[aCode;aComment][lResult]   
## Выполняет код и сохраняет ресурсы, затраченные на его исполнение.
  $lResult[$.before[^resources[]] $.comment[$aComment]]
  ^try{
    $result[$aCode]
  }{
#   pass exceptions 
  }{
     $lResult.after[^resources[]]
     $lResult.time($lResult.after.time - $lResult.before.time)
     $lResult.utime($lResult.after.utime - $lResult.before.utime)
     $lResult.stime($lResult.after.stime - $lResult.before.stime)

     $lResult.allocated($lResult.after.allocated - $lResult.before.allocated)
     $lResult.compacts($lResult.after.compacts - $lResult.before.compacts)
     $lResult.used($lResult.after.used - $lResult.before.used)
     $lResult.free($lResult.after.free - $lResult.before.free)

     $_profiled.last[$lResult]
     ^if($enableProfilerLog){
       $_profiled.all.[^_profiled.all._count[]][$lResult]
     }
   }
