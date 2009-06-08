# PF Library

@CLASS
pfRouter

@USE
pf/types/pfClass.p
pf/collections/pfList.p

@BASE
pfClass

@create[aOptions]
  ^cleanMethodArgument[]
  ^BASE:create[] 
  
  $_routes[^pfList::create[]]
  $_segmentSeparators[\./] 
  $_varRegexp[[^^$_segmentSeparators]+] 
  $_trapRegexp[(.+)]
  $_patternVar[([:\*])\{?([\p{L}\p{Nd}_\-]+)\}?] 
  
  $_rootRoute[]
  ^root[]
  
@assign[aPattern;aRouteTo;aOptions][lCompiledPattern]
## Добавляет новый шаблон aPattern в список маршрутов 
## aRouteTo - новый маршрут (может содержать переменные)
## aOptions.defaults[] - хеш со значениями переменных шаблона "по-умолчанию" 
## aOptions.requirements[] - хеш с регулярными выражениями для проверки переменных шаблона
## aOptions.prefix[] - дополнительный, вычисляемый префикс для путей (может содержать переменные)
  ^cleanMethodArgument[]
  $result[]
  
  ^if(!def $aOptions.defaults){$aOptions.defaults[^hash::create[]]}
  ^if(!def $aOptions.requirements){$aOptions.requirements[^hash::create[]]}

  $lCompiledPattern[^_compilePattern[$aPattern;$aOptions]]
  ^_routes.add[
    $.pattern[$lCompiledPattern.pattern]
    $.regexp[$lCompiledPattern.regexp]
    $.vars[$lCompiledPattern.vars]
    
    $.routeTo[^_trimPath[$aRouteTo]]
    $.prefix[$aOptions.prefix]

    $.defaults[$aOptions.defaults]
    $.requirements[$aOptions.requirements]
  ]

@root[aRouteTo;aOptions]
## Добавляет действие для пустого роута
## aRouteTo - новый маршрут (может содержать переменные)
## aOptions.defaults[] - хеш со значениями переменных шаблона "по-умолчанию" 
## aOptions.prefix[] - дополнительный, вычисляемый префикс для путей (может содержать переменные)
  ^cleanMethodArgument[]
  ^if(!def $aOptions.defaults){$aOptions.defaults[^hash::create[]]}
  ^if(!def $aOptions.requirements){$aOptions.requirements[^hash::create[]]}
  $_rootRoute[
    $.routeTo[^_trimPath[$aRouteTo]]
    $.prefix[^if(def $aOptions.prefix){$aOptions.prefix}{^_trimPath[$aRouteTo]}]
    $.defaults[$aOptions.defaults]        
    $.regexp[^^^$]
    $.vars[^table::create{var}]
  ]                

@route[aPath;aOptions][lParsedPath;it]
## Выполняет поиск и преобразование пути по списку маршрутов 
## aOptions.args
## result[$.action $.args $.prefix]
  ^cleanMethodArgument[]
  $result[^hash::create[]]
  $aPath[^_trimPath[$aPath]]
  ^if(def $aPath){
    ^_routes.foreach[it]{
      ^if(!$result){
        $lParsedPath[^_parsePathByRoute[$aPath;$it;$.args[$aOptions.args]]]
        ^if($lParsedPath){     
          $result[$lParsedPath]  
        }
      }
    }
  }{                  
     $result[^_parsePathByRoute[$aPath;$_rootRoute;$.args[$aOptions.args]]]
   }

#----- Private -----

@_trimPath[aPath]
  $result[^if(def $aPath){^aPath.trim[both;/. ^#0A]}]

@_compilePattern[aRoute;aOptions][lPattern;lSegments;lRegexp]
## result[$.pattern[] $.regexp[] $.vars[]]
  $result[
    $.vars[^table::create{var}]
    $.pattern[^_trimPath[$aRoute]]
  ]       
  $lPattern[^untaint[regex]{/$result.pattern}]

# Разбиваем шаблон на сегменты и компилируем их в регулярные выражения
  $lSegments[^pfList::create[]]
  ^lPattern.match[([$_segmentSeparators])([^^$_segmentSeparators]+)][g]{                                                                              
     $lHasVars(false)
     $lRegexp[^match.2.match[$_patternVar][gi]{^if($match.1 eq ":"){(^if(def $aOptions.requirements.[$match.2]){^aOptions.requirements.[$match.2].match[\(][g]{(?:)}}{$_varRegexp})}{$_trapRegexp}^result.vars.append{$match.2}$lHasVars(true)}]  
     ^lSegments.add[
       $.prefix[$match.1]
       $.regexp[$lRegexp]
       $.hasVars($lHasVars)
     ]
  } 
  
# Собираем регулярное выражение для всего шаблона
  $result.regexp[^^^lSegments.foreach[it]{^if($it.hasVars){(?:}^if($lSegments.currentIndex){\$it.prefix}$it.regexp}^lSegments.foreach[it]{^if($it.hasVars){)?}}^$]


@_parsePathByRoute[aPath;aRoute;aOptions][lVars;i]
## Преобразует aPath по правилу aOptions.
## aOptions.args
## result[$.action $.args $.prefix]
  $result[^hash::create[]]   
  $lVars[^aPath.match[$aRoute.regexp][i]]
  ^if($lVars){
    $result.args[^hash::create[$aRoute.defaults]]
    ^if($aRoute.vars){
      ^for[i](1;$aRoute.vars){
        ^aRoute.vars.offset[set]($i-1)
        ^if(def $lVars.$i){
          $result.args.[$aRoute.vars.var][$lVars.$i]
        }
      }
    }                         
    $result.action[^_applyPath[$aRoute.routeTo;$result.args;$aOptions.args]]
    $result.prefix[^_applyPath[$aRoute.prefix;$result.args;$aOptions.args]]
  }                                                           

@_applyPath[aPath;aVars;aArgs]
## Заменяет переменные в aPath. Значения переменных ищутся в aVars и aArgs.  
  ^cleanMethodArgument[aVars]
  ^cleanMethodArgument[aArgs]
  $result[^aPath.match[$_patternVar][gi]{^if(def $aVars.[$match.2]){$aVars.[$match.2]}{^if(def $aArgs.[$match.2]){$aArgs.[$match.2]}{^throw[$CLASS_NAME;Unknown variable ":$match.2" in "$aRouteTo"]}}}]

