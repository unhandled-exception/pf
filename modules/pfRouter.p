# PF Library

@CLASS
pfRouter

@USE
pf/types/pfClass.p
pf/collections/pfList.p
pf/types/pfString.p

@BASE
pfClass

@create[aOptions]
  ^cleanMethodArgument[]
  ^BASE:create[] 
  
  $_routes[^pfList::create[]]
  $_segmentSeparators[\./] 
  $_varRegexp[[^^$_segmentSeparators]+] 
  $_trapRegexp[(.+)]
  $_patternVar[(?<!\?)([:\*])\{?([\p{L}\p{Nd}_\-]+)\}?] 
  
  
@assign[aPattern;aRouteTo;aOptions][lCompiledPattern]
## Добавляет новый шаблон в список маршрутов
## aOptions.args - хеш с аргументами, которые будут добавлены к полученным из шаблона.
## aOptions.defaults[] - хеш со значениями по-умолчанию, который будет добавлен, 
##                       если выполнится преобразование, но в результате будут 
##                       отсутствовать некоторые ключи. 
## aOptions.requirements[] - хеш с регулярными выражениями для проверки переменных шаблона
  ^cleanMethodArgument[]
  $result[]
  
  ^if(!($aOptions.args is hash)){$aOptions.args[^hash::create[]]}
  ^if(!($aOptions.defaults is hash)){$aOptions.defaults[^hash::create[]]}
  ^if(!($aOptions.requirements is hash)){$aOptions.requirements[^hash::create[]]}

  $lCompiledPattern[^_compilePattern[$aPattern;$aOptions]]
  ^_routes.add[
    $.pattern[$lCompiledPattern.pattern]
    $.regexp[$lCompiledPattern.regexp]
    $.vars[$lCompiledPattern.vars]
    
    $.routeTo[$aRouteTo]
    $.args[$aOptions.args]
    $.defaults[$aOptions.defaults]
    $.requirements[$aOptions.requirements]
  ]

#  $result[
#  $lCompiledPattern.pattern<br />
#  $lCompiledPattern.regexp
#  ]

@route[aPath;aOptions][lParsedPath;it]
## Выполняет поиск и преобразование пути по списку маршрутов
  $result[^hash::create[]]
  $aPath[^aPath.trim[both;/. ^#0A]]
  ^_routes.foreach[it]{
    ^if(!$result){
      $lParsedPath[^_parsePathByRoute[$aPath;$it]]
      ^if($lParsedPath){     
        $result[$lParsedPath]  
      }
    }
  }

@_parsePathByRoute[aPath;aRoute][lVars;i]
  $result[^hash::create[]]   
  ^pfAssert:isTrue($aRoute.defaults is hash)[stop]
  ^if(^aPath.match[$aRoute.regexp][in]){
    $result.args[$aRoute.defaults]
    ^if($aRoute.vars){
      $lVars[^aPath.match[$aRoute.regexp][i]]
      ^for[i](1;$aRoute.vars){
        ^aRoute.vars.offset[set]($i-1)
        ^if(def $lVars.$i){
          $result.args.[$aRoute.vars.var][$lVars.$i]
        }
      }
    }                         
    $result.path[^_parseRouteTo[$aRoute.routeTo;$result.args]]
  }
  
@_parseRouteTo[aRouteTo;aArgs]
  $result[^aRouteTo.match[$_patternVar][gi]{^if(^aArgs.contains[$match.2]){$aArgs.[$match.2]}{^throw[$CLASS_NAME;Unknown variable ":$match.2" in "$aRouteTo"]}}]
  

#----- Private -----

@_compilePattern[aRoute;aOptions][lPattern;lSegments;lRegexp;i]
## result[$.pattern[] $.regexp[] $.vars[]]
  $result[
    $.vars[^table::create{var}]
    $.pattern[^aRoute.trim[both;/. ^#0A]]
  ]       
  $lPattern[^untaint[regex]{/$result.pattern}]

# Разбиваем шаблон на сегменты и компилируем их в регулярные выражения
  $lSegments[^pfList::create[]]
  ^lPattern.match[([$_segmentSeparators])([^^$_segmentSeparators]+)][g]{                                                                              
     $lHasVars(false)
     $lRegexp[^match.2.match[$_patternVar][gi]{^if($match.1 eq ":"){(^if(def $aOptions.requirements.[$match.2]){$aOptions.requirements.[$match.2]}{$_varRegexp})}{$_trapRegexp}^result.vars.append{$match.2}$lHasVars(true)}]  
     ^lSegments.add[
       $.prefix[$match.1]
       $.regexp[$lRegexp]
       $.hasVars($lHasVars)
     ]
  } 
  $result.segments[$lSegments]
  
# И собираем регулярное выражение для всего шаблона
  $i(0)
  $result.regexp[^^^lSegments.foreach[it]{^if($it.hasVars){(?:}^if($i){\$it.prefix}$it.regexp^i.inc[]}^lSegments.foreach[it]{^if($it.hasVars){)?}}^$]

#  ^pfAssert:fail[  
#    $result.regexp                                             
#    ^result.vars.menu{$result.vars.var}[
#    ]
#  ]             






