###########################################################################
# $Id: Erusage.p,v 1.1 2007/01/15 16:19:44 misha Exp $
###########################################################################
#
# Usage:
# Firts call: ^Erusage:init[$.iLimit(2048)] (can be omited)
# Other calls: ^Erusage:compact[]
# The ^memory:compact[] will executed only if used more then $iLimit KB since 
#  last call or if $.bForce(1) parameter was specified.
#
# At the end you can analize $hStatistics or call ^Erusage:log[] or ^Erusage:print[].


@CLASS
Erusage



###########################################################################
@auto[]
$hRusageBegin[$status:rusage]
$hStatistics[
	$.iCalls(0)
	$.iCompact(0)
	$.hMemory[
		$.iBegin(0)
		$.iEnd(0)
		$.iCollected(0)
	]
]
$iLimit(2048)
^self._saveMemoryUsage[iBegin]
#end @auto[]



###########################################################################
@init[hParam]
$self.iLimit(^hParam.iLimit.int($self.iLimit))
$result[]
#end @init[]



###########################################################################
@compact[hParam][iPrevUsed]
^hStatistics.iCalls.inc(1)
^if($hParam.bForce || !$hStatistics.hMemory.iEnd || ($self.iLimit && ($status:memory.used - $hStatistics.hMemory.iEnd) > $self.iLimit)){
	^hStatistics.iCompact.inc(1)
	$iPrevUsed($status:memory.used)
	^memory:compact[]
	^hStatistics.hMemory.iCollected.inc($iPrevUsed - $status:memory.used)
	^self._saveMemoryUsage[iEnd]
}
$result[]
#end @compact[]



###########################################################################
# measure time/memory usage while running $jCode code
# .time - 'dirty' execution time (millisecond)
# .utime - 'pure' execution time (second)
# .memory_kb - used memory (KB)
# .memory_block - used memory (blocks)
@measure[jCode;sVarName][hBegin;hEnd]
^if(def $sVarName){
	^try{
		$hBegin[
			$.rusage[$status:rusage]
			$.memory[$status:memory]
		]
	}{
		$exception.handled(1)
	}
	$result[$jCode]
	^try{
		$hEnd[
			$.rusage[$status:rusage]
			$.memory[$status:memory]
		]
	}{
		$exception.handled(1)
	}
	$caller.[$sVarName][
		$.time((^hEnd.rusage.tv_sec.double[] - ^hBegin.rusage.tv_sec.double[])*1000 + (^hEnd.rusage.tv_usec.double[] - ^hBegin.rusage.tv_usec.double[])/1000)
		$.utime($hEnd.rusage.utime - $hBegin.rusage.utime)
		$.memory_block($hEnd.rusage.maxrss - $hBegin.rusage.maxrss)
		^if($hBegin.memory){
			$.memory_kb($hEnd.memory.used - $hBegin.memory.used)
		}
	]
}{
	$result[$jCode]
}
#end @measure[]



###########################################################################
@print[hParam][dtNow;result]
$dtNow[^date::now[]]
$result[^dtNow.sql-string[]	memory begin/end/collected: $hStatistics.hMemory.iBegin/$hStatistics.hMemory.iEnd/$hStatistics.hMemory.iCollected KB	calls/compacts: $hStatistics.iCalls/$hStatistics.iCompact	http://${env:SERVER_NAME}$request:uri^#0A]
^if(def $hParam && def $hParam.sFile){
	^result.save[append;$hParam.sFile]
}
#end @print[]



#################################################################################################
@log[hParam][dNow;sResult]
^if(def $hParam && def $hParam.sFile){
	$dNow[^date::now[]]
	$sResult[[^dNow.sql-string[]]	^status:rusage.utime.format[%0.4f]	^eval(^status:rusage.tv_sec.double[] - ^hRusageBegin.tv_sec.double[] + (^status:rusage.tv_usec.double[] - ^hRusageBegin.tv_usec.double[])/1000000)[%0.4f]	$status:rusage.maxrss	[$status:memory.used/$status:memory.free]	$env:REMOTE_ADDR	$request:uri^if(def $hParam.sMessage){ $hParam.sMessage}^#0A]
	^sResult.save[append;$hParam.sFile]
}
$result[]
#end @log[]



###########################################################################
@_saveMemoryUsage[sType][result]
$hStatistics.hMemory.$sType($status:memory.used)
#end @_saveMemoryUsage[]
