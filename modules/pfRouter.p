# PF Library

@CLASS
pfRouter

@USE
pf/types/pfClass.p

@BASE
pfClass

@create[aOptions]
  ^cleanMethodArgument[]
  ^BASE:create[] 
  
  $_routes[^hash::create[]]
  $_segmentSeparators[\./] 
  $_varRegexp[[^^$_segmentSeparators]+] 
  $_trapRegexp[(.*)]
  
  $_rootRoute[]
  ^root[]

@auto[]
  $_pfRouterPatternVar[([:\*])\{?([\p{L}\p{Nd}_\-]+)\}?]
  $_pfRouterPatternRegex[^regex::create[$_pfRouterPatternVar][g]]
  $_pfRouteRootRegex[^regex::create[^^^$]]

  
@assign[aPattern;aRouteTo;aOptions][lCompiledPattern]
## Добавляет новый шаблон aPattern в список маршрутов 
## aRouteTo - новый маршрут (может содержать переменные)
## aOptions.defaults[] - хеш со значениями переменных шаблона "по-умолчанию" 
## aOptions.requirements[] - хеш с регулярными выражениями для проверки переменных шаблона
## aOptions.prefix[] - дополнительный, вычисляемый префикс для путей (может содержать переменные)
## aOptions.reversePrefix[] - префикс маршрута при бэкрезолве
## aOptions.name[] - имя шаблона (используется в reverse, нечувствительно к регистру)
## aOptions.ignoreCase(true) - игнорироавть регистр букв при обработке шаблона
## aOptions.strict(false) - включает "строгий" режим проверки шаблона.
  ^cleanMethodArgument[]
  $result[]
  
  ^if(!def $aOptions.defaults){$aOptions.defaults[^hash::create[]]}
  ^if(!def $aOptions.requirements){$aOptions.requirements[^hash::create[]]}

  $lCompiledPattern[^_compilePattern[$aPattern;$aOptions]]
  $_routes.[^eval($_routes + 1)][
    $.pattern[$lCompiledPattern.pattern]
    $.regexp[^regex::create[$lCompiledPattern.regexp][^if(^aOptions.ignoreCase.bool(true)){i}]]
    $.ignoreCase(^aOptions.ignoreCase.bool(true))
    $.vars[$lCompiledPattern.vars]
    $.trap[$lCompiledPattern.trap]
    
    $.routeTo[^_trimPath[$aRouteTo]]
    $.prefix[$aOptions.prefix]
    $.reversePrefix[$aOptions.reversePrefix]

    $.defaults[$aOptions.defaults]
    $.requirements[$aOptions.requirements]
    $.name[^if(def $aOptions.name){^aOptions.name.lower[]}]
    $.strict(^aOptions.strict.bool(false))
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
    $.regexp[$_pfRouteRootRegex]
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
    ^_routes.foreach[k;it]{
      $lParsedPath[^_parsePathByRoute[$aPath;$it;$.args[$aOptions.args]]]
      ^if($lParsedPath){     
        $result[$lParsedPath]    
        ^break[]
      }
    }
  }{                  
     $result[^_parsePathByRoute[$aPath;$_rootRoute;$.args[$aOptions.args]]]
   }

@reverse[aAction;aArgs][it;lVar;k;v;lPath]
## aAction - имя экшна или роута
## aArgs - хеш с параметрами для преобразования
## result[$.path[] $.prefix[] $.reversePrefix[] $.args[]] - если ничего не нашли, возвращаем пустой хеш
  ^cleanMethodArgument[aArgs]
  $result[^hash::create[]]
  $aAction[^_trimPath[$aAction]]
  ^_routes.foreach[k;it]{
#   Ищем подходящий маршрут по action (если в routeTo содержатся переменные, то лучше использовать name для маршрута)
    ^if((def $it.name && $aAction eq $it.name) || $aAction eq $it.routeTo){                     
      $lPath[^_applyPath[$it.pattern;$aArgs]]
#     Проверяем соотвтетствует ли полученный путь шаблоу (с ограничениями requirements)
      ^if(^lPath.match[$it.regexp]){
#       Добавляем оставшиеся параметры из aArgs в result.args
        $result.path[$lPath]
        $result.prefix[^_applyPath[$it.prefix;$aArgs]]
        $result.reversePrefix[^_applyPath[$it.reversePrefix;$aArgs]]
        $result.args[^hash::create[$aArgs]]
        ^result.args.sub[$it.vars]
        ^break[]
      }
    }
  }

  ^if(!$result && $aAction eq $_rootRoute.routeTo){
#   Если не нашли реверс, то проверяем рутовый маршрут   
    $result.path[]
    $result.prefix[^_applyPath[$_rootRoute.prefix;$aArgs]]
    $result.args[$aArgs]
  }


#----- Private -----

@_trimPath[aPath]
  $result[^if(def $aPath){^aPath.trim[both;/. ^#0A]}]

@_compilePattern[aRoute;aOptions][lPattern;lSegments;lRegexp;lParts]
## result[$.pattern[] $.regexp[] $.vars[] $.trap[]]
  $result[
    $.vars[^hash::create[]]
    $.pattern[^_trimPath[$aRoute]]
    $.trap[]
  ]       
  $lPattern[^untaint[regex]{/$result.pattern}]

# Разбиваем шаблон на сегменты и компилируем их в регулярные выражения
  $lSegments[^hash::create[]]
  $lParts[^lPattern.match[([$_segmentSeparators])([^^$_segmentSeparators]+)][g]]
  ^lParts.menu{                                                                              
     $lHasVars(false)
     $lRegexp[^lParts.2.match[$_pfRouterPatternRegex][]{^if($match.1 eq ":"){(^if(def $aOptions.requirements.[$match.2]){^aOptions.requirements.[$match.2].match[\((?!\?[=!<>])][g]{(?:}}{$_varRegexp})}{$_trapRegexp}^if($match.1 eq "*"){$result.trap[$match.2]}$result.vars.[$match.2](true)$lHasVars(true)}]  
     $lSegments.[^eval($lSegments + 1)][
       $.prefix[$lParts.1]
       $.regexp[$lRegexp]
       $.hasVars($lHasVars)
     ]
  } 
  
# Собираем регулярное выражение для всего шаблона
  $result.regexp[^^^lSegments.foreach[k;it]{^if($it.hasVars){(?:}^if($k>1){\$it.prefix}$it.regexp}^lSegments.foreach[k;it]{^if($it.hasVars){)^if(!^aOptions.strict.bool(false)){?}}}^$]

@_parsePathByRoute[aPath;aRoute;aOptions][lVars;i;k;v]
## Преобразует aPath по правилу aOptions.
## aOptions.args
## result[$.action $.args $.prefix]
  $result[^hash::create[]]   
  $lVars[^aPath.match[$aRoute.regexp]]
  ^if($lVars){
    $result.args[^hash::create[$aRoute.defaults]]
    ^if($aRoute.vars){    
      $i(1)
      ^aRoute.vars.foreach[k;v]{    
        ^if(def $lVars.$i){
          $result.args.[$k][$lVars.$i]
        }
        ^i.inc[]
      }
    }        
    $result.action[^_applyPath[$aRoute.routeTo;$result.args;$aOptions.args]]
    $result.prefix[^_applyPath[$aRoute.prefix;$result.args;$aOptions.args]]
  }                                                           

@_applyPath[aPath;aVars;aArgs]
## Заменяет переменные в aPath. Значения переменных ищутся в aVars и aArgs.  
  ^cleanMethodArgument[aVars]
  ^cleanMethodArgument[aArgs]
  $result[^if(def $aPath){^aPath.match[$_pfRouterPatternRegex][]{^if(^aVars.contains[$match.2]){$aVars.[$match.2]}{^if(^aArgs.contains[$match.2] || $match.1 eq "*"){$aArgs.[$match.2]}}}}]

