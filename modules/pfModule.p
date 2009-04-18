# PF Library

#@module   Module Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

@CLASS
pfModule

@USE
pf/types/pfClass.p
pf/collections/pfArrayList.p
pf/types/pfString.p

@BASE
pfClass

#@doc
## Обработчики экшнов именуются по схеме onНазваниеСобытия. 
## В названии первая буква переводится в верхний регистр.
## Экшн может быть поименован по схеме "first/second/third", тогда имя обработчика будет
## onFirstSecondThird (news/add -> onNewsAdd)
## Все обработчики принимают один параметр [aRequest.. имя может быть любым] - 
## хэш с параметрами события. aRequest может быть пустым.
##
##todo: Дописать текст про modModule
#/doc

#----- Constructor -----

@create[aOptions]
## Конструктор класса
## aOptions.uriPrefix[/] - префикс для uri. Нужно передавать только в головной модуль, 
##                         поскольку метод assignModule будт передавать свой собственный
##                         префикс.
  ^BASE:create[]
  ^cleanMethodArgument[]
  $_throwPrefix[pfModule]
  
# Модули
  $_MODULES[^hash::create[]]  

# Префикс для uri. 
  $_uriPrefix[^if(def $aOptions.uriPrefix){$aOptions.uriPrefix}{/}]

# Текущий экшн
  $_action[]

# Коллекция с шаблонами для реврайта 
  $_rewriteMap[^pfArrayList::create[]]

#----- Properties -----

@GET_uriPrefix[]
  $result[$_uriPrefix]

@GET_action[]
  $result[$_action]
  
@GET_MODULES[]
  $result[$_MODULES]

#---- Public -----

@hasModule[aName]
## Проверяет есть ли у нас модуль с имененм aName
##todo: Возможно стоит сделать более серьезную проверку.
  $result($_MODULES.$aName is hash)

@hasAction[aAction][lHandler]
## Проверяем есть ли в модуле обработчик aAction
  $lHandler[^_makeActionName[$aAction]]
  $result($$lHandler is junction)

@assignModule[aName;aOptions]
## Добавляет модуль aName
## aOptions.class - имя класса
## aOptions.file - файл с текстом класса
## aOptions.source - строка с текстом класса (если определена, то плюем на file)
## aOptions.compile(0) - откомпилировать модуль сразу 
## aOptions.args - опции, которые будут переданы конструктору.

## Experimental:
## aOptions.faсtory - метод, который будет вызван для создания модуля
##                    Если определен, то при компиляции модуля вызывается код, 
##                    который задан в этой переменной. Предполагается, что в качестве 
##                    кода выступает метод, который возвращает экземпляр.
##                    Если определена $aOptions.args, то эта переменная будет
##                    передана методу в качестве единственного параметра.
##                    Пример:
##                     ^addModule[test;$.factory[$moduleFactory] $.args[test]]
##                      
##                     @moduleFactory[aArgs]
##                       $result[^pfModule::create[$aArgs]]
##       
  ^cleanMethodArgument[]

#  Добавляем в хэш с модулями данные о модуле
   $_MODULES.[$aName][
       $.class[$aOptions.class]

       ^if($aOptions.factory is junction){
         $.factory[$aOptions.factory]
         $.hasFactory(1)
       }{
       	  $.factory[]
          $.hasFactory(0)
       	}

       $.file[$aOptions.file]
       $.source[$aOptions.source]
       
       $.args[^if(def $aOptions.args){$aOptions.args}{^hash::create[]}]
       $.object[]
       
       $.isCompiled(0)
       $.makeAction(^aOptions.makeAction.int(1))
       $.uriPrefix[${uriPrefix}$aName/]
   ]

#  Перекрываем uriPrefix, который пришел к нам в $aOptions.args.
#  Возможно и не самое удачное решение, но позволяет сохранить цепочку.
   $_MODULES.[$aName].args.uriPrefix[$_MODULES.[$aName].uriPrefix]
        
#  Если необходимо, то компилируем модуль
   ^if(^aOptions.compile.int(0)){
     ^compileModule[$aName]
   }

#  Вкомпилируем в наш объект ссылку на модуль [$self.modName]
#  Первая буква модуля становится большой.
   ^process{
      ^^if(!^$_MODULES.[$aName].isCompiled){
        ^^compileModule[$aName]
      }
      ^$result[^$_MODULES.${aName}.object]   
   }[$.main[GET_mod^_makeSpecialName[$aName]]]

@compileModule[aName][lFactory]
## Компилирует модуль
## Если модуль задан не в виде ссылки на файл, а в виде строки (source),
## то компилируем ее, не обращая при этом, внимания на файл.
## Если для модуля есть фабрика, то зовем именно ее.
  ^if($_MODULES.[$aName]){
    ^if($_MODULES.[$aName].hasFactory){
    	$lFactory[$_MODULES.[$aName].factory]
      ^if(def $_MODULES.[$aName].args){
      	$_MODULES.[$aName].object[^lFactory[$_MODULES.[$aName].args]]
      }{
         $_MODULES.[$aName].object[^lFactory[]]
       }
  	  $_MODULES.[$aName].isCompiled(1)  
    }{
            ^if(def $_MODULES.[$aName].source){
  	    ^process[$MAIN:CLASS]{^taint[as-is][$_MODULES.[$aName].source]}
  	  }{
  	     ^process{^^use[$_MODULES.[$aName].file]}
  	  }
  	  ^process{
  	    ^$_MODULES.[$aName].object[^^$_MODULES.[$aName].class::create[^$_MODULES.[$aName].args]]
  	  }
  	  $_MODULES.[$aName].isCompiled(1)  
     }
  }{
  	 ^throw[module.compile;Module "$aName" not found.]
   }

@dispatch[aAction;aRequest][lModule;lActionHandler;lHandler;lAction;CALLER;lRewrite]
## Производим обработку экшна
#@param aAction    Действие, которое необходимо выполнить
#@param aRequest   Параметры экшна

#@todo: Составить описание составления action'ов
  ^if(def $aAction){
    $aAction[^aAction.trim[both;/.]]
    $aAction[^aAction.lower[]]
  }

  $lRewrite[^rewriteAction[$aAction;$aRequest]]
  $aAction[$lRewrite.action]
  ^if($lRewrite.args){
#   Пытаемся воспользоваться методом рефлексии.
    ^if($aRequest.__add is junction){
  	  ^aRequest.__add[$lRewrite.args]
  	}{
   	   ^aRequest.add[$lRewrite.args]
  	 }
  }

  $_action[$aAction]

# Формируем специальную переменную $CALLER, чтобы передать текущий контекст 
# из которого вызван dispatch. Нужно для того, чтобы можно было из модуля
# получить доступ к контейнеру, не городя передачу оному $self отдельным параметром.
  $CALLER[$self]

# Если у нас в первой части экшна имя модуля, то передаем управление ему
  $lModule[^aAction.match[([^^/\.]+)(.*)][]{$match.1}]
  ^if(def $lModule && ^hasModule[$lModule]){
#   Если у нас есть экшн, совпадающий с именем модуля, то зовем его. 
#   При этом отсекая имя модуля от экшна перед вызовом (восстанавливаем после экшна).
    ^if(^hasAction[$lModule]){
      $_action[^aAction.match[([^^/\.]+)(.*)][]{$match.2}]
      $result[^self.[^_makeActionName[$lModule]][$aRequest]]
      $_action[$aAction]
    }{
       $result[^self.[mod^_makeSpecialName[$lModule]].dispatch[^aAction.mid(^lModule.length[]);$aRequest]]
     }
  }{
#   Если модуля нет, то пытаемся найти и запустить экш из нашего модуля
#   Если не получится, то зовем onDEFAULT, а если и это не получится,
#   то выбрасываем эксепшн.
     ^if(^hasAction[$aAction]){
       $result[^self.[^_makeActionName[$aAction]][$aRequest]]
     }{
        ^if($onDEFAULT is junction){
          $result[^onDEFAULT[$aRequest]]
        }{
           ^throw[module.dispatch.action.not.found;Action "$aAction" not found.]
         }
      }
   }

@addRewritePattern[aPattern;aNewAction;aOptions][lPattern]
## Добавляем шаблон в карту преобразований.
## aOptions.args - хеш с аргументами, которые будут добавлены к полученным из шаблона.
## aOptions.isStatic(0) - статический шаблон (если в шаблоне нет переменных, то считаем такой
##                        шаблон тоже статическим).
## aOptions.defaults[] - хеш со значениями по-умолчанию, который будет добавлен, 
##                       если выполнится преобразование, но в результате будут 
##                       отсутствовать некоторые ключи.
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(def $aPattern)[Не задан шаблон преобразования.]
  
  $lPattern[^_compileRewritePattern[^aPattern.trim[both;/]]]
  ^_rewriteMap.add[
    $.pattern[$lPattern]
    $.action[$aNewAction]
    $.args[^if($aOptions.args is hash){$aOptions.args}{^hash::create[]}]
    $.isStatic[^if(^aOptions.isStatic.int(0) || !$lPattern.keys){1}{0}]
    $.defaults[$aOptions.defaults]
  ]

@rewriteAction[aAction;aRequest][lRewrite;it]
## Вызывается каждый раз перед диспатчем - внутренний аналог mod_rewrite.
## $result.action - новый экшн.
## $result.args - параметры, которые надо добавить к аргументам и передать обработчику. 
## Стандартный обработчик проходит по карте преобразований и ищет пододящий шаблон, 
## иначе возвращает оригинальный экшн. 
  $result(0)
  ^if($_rewriteMap.count){
    ^_rewriteMap.foreach[it]{
      ^if(!$result){
        ^if($it.isStatic){
          ^if(^aAction.match[$it.pattern.pattern][in]){
            $result[$.action[$it.action] $.args[$it.args]]
            ^if(def $it.defaults){
               $result.args[^result.args.union[$it.defaults]]
            }
          }
        }{
           $lRewrite[^_parseActionByPattern[$it.pattern;$aAction]]
           ^if($lRewrite){
             $result[$.action[$it.action] $.args[$lRewrite]]
             ^if($it.args){^result.args.add[$it.args]}
             ^if(def $it.defaults){
               $result.args[^result.args.union[$it.defaults]]
             }
           }
         }
      }
    }
  }
  
  ^if(!$result){
    $result[$.action[$aAction] $.args[]]
  }
   

@linkTo[aAction;aOptions;aAnchor]
  $result[^_makeLinkURI[$aAction;$aOptions;$aAnchor]]
    
@redirectTo[aAction;aOptions;aAnchor]
## Редирект на экшн. Реализация остается за программистом
  $result[]
    

@goTo[aAction;aOptions;aAnchor]
## DEPRECATED!
## Редирект на экшн. Реализация остается за программистом
  $result[^redirectTo[$aAction;$aOptions;$aAnchor]]
  
#----- Private -----

@_compileRewritePattern[aPattern][lPattern;lKeys]
## Компилирует шаблон
## $result.pattern
## $result.keys  
   $lKeys[^table::create{key}]
 
#  Заменяем спецсимволы и группировки
   $lPattern[^taint[regex][$aPattern]]
   $lPattern[^lPattern.match[\(][g]{(?:}]
   $lPattern[^lPattern.match[\)(\?)?][g]{^taint[as-is][)$match.1]}]
#  Заменяем макроподстановки   
   $lPattern[^^^lPattern.match[(?<!\?)\:\{?([\p{L}\p{Nd}_\-]+)\}?(?:<(.+?)>)?][gi]{(^if(def $match.2){^taint[as-is][$match.2]}{.+?})^lKeys.append{$match.1}}^$]  

   $result[$.pattern[$aPattern] $.compiled[$lPattern] $.keys[$lKeys]]

@_parseActionByPattern[aPattern;aAction][lCompiled;lPattern;lKeys;lMatches;i]
## Разбираем экшн на основании шаблона и возвращаем хеш с полученными данными.
## Если распарсить не удалось, то возвращаем пустой хеш.
## aPattern - шаблон "path1/path2/:arg1/(:arg2<regex>(/:{arg3}-arg4)?)?"
##            В угловых скобках может быть указано регулярное выражение 
##            для более точной проверки шаблона.
   $result[^hash::create[]]
   
   $lPattern[$aPattern.compiled]
   $lKeys[$aPattern.keys]
   
   $lMatches[^aAction.match[$lPattern][gi]]
   ^if($lMatches){
     ^for[i](1;$lKeys){
       ^lKeys.offset[set]($i-1)
       ^if(def $lMatches.[$i]){
         $result.[$lKeys.key][$lMatches.[$i]]
       }
     }
   }
   
@_makeLinkURI[aAction;aOptions;aAnchor]
## Формирует url для экшна
## $uriPrefix$aAction?aOptions.foreach[key=value][&]
  ^if(def $aAction){$aAction[^aAction.trim[both;/\.]]}
  $result[$uriPrefix^if(def $aAction){$aAction}]
  ^if($aOptions is hash && $aOptions){
    $result[${result}?^aOptions.foreach[key;value]{$key=^taint[uri][$value]}[^taint[&]]]
  }
  ^if(def $aAnchor){$result[${result}#$aAnchor]}

@_makeActionName[aAction][lSplitted;lFirst]
## Формирует имя метода для экшна.
  $result[]
  $lSplitted[^pfString:rsplit[$aAction;[/\.]]]
  ^if($lSplitted){
  	 $result[on]
     ^lSplitted.menu{
     	  $result[${result}^_makeSpecialName[$lSplitted.piece]]
     	}	
  }
  
@_makeSpecialName[aStr][lFirst]
## Возвращает aStr в которой первая буква прописная
  $result[^aStr.match[(.)(.*)][]{^match.1.upper[]^match.2.lower[]}]
