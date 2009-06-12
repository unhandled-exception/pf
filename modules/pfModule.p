# PF Library

@CLASS
pfModule

@USE
pf/types/pfClass.p
pf/collections/pfList.p
pf/types/pfString.p
pf/modules/pfRouter.p

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
  $_name[$aOptions.name]
  
# Модули
  $_MODULES[^hash::create[]]  

# Префикс для uri. 
  $uriPrefix[^if(def $aOptions.uriPrefix){$aOptions.uriPrefix}{/}]

# Текущий экшн
  $_action[]

  $_router[^pfRouter::create[]] 


#----- Properties -----

@GET_uriPrefix[]
  $result[$_uriPrefix]

@SET_uriPrefix[aUriPrefix]  
  $_uriPrefix[$aUriPrefix/]
  $_uriPrefix[^_uriPrefix.match[(/)+][g]{$match.1}]
  
@GET_action[]
  $result[$_action]
  
@GET_MODULES[]
  $result[$_MODULES]

@GET_router[]
  $result[$_router]

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

@GET_DEFAULT[aName][lName]
## Эмулирует свойства modModule
  $result[]
  ^if(^aName.left(3) eq "mod"){
    $lName[^aName.mid(3)]
    $lName[^lName.lower[]]
    ^if(^_MODULES.contains[$lName]){
      ^if(!$_MODULES.[$lName].isCompiled){
        ^compileModule[$lName]
      }
      $result[$_MODULES.[$lName].object]
    }                     
  }

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
  	     ^use[$_MODULES.[$aName].file]
  	  }
  	  ^process{
  	    ^$_MODULES.[$aName].object[^^$_MODULES.[$aName].class::create[^$_MODULES.[$aName].args]]
  	  }
  	  $_MODULES.[$aName].isCompiled(1)  
     }
  }{
  	 ^throw[module.compile;Module "$aName" not found.]
   }
   
@dispatch[aAction;aRequest;aOptions][lModule;lActionHandler;lHandler;lAction;CALLER;lRewrite;CALLER]
## Производим обработку экшна
## aAction    Действие, которое необходимо выполнить
## aRequest   Параметры экшна      
## aOptions.prefix
  ^cleanMethodArgument[]
 
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
    $uriPrefix[^if(def $lRewrite.prefix){$lRewrite.prefix}{^if(def $aOptions.prefix){$aOptions.prefix}{/}$lModule/}] 
#   Если у нас есть экшн, совпадающий с именем модуля, то зовем его. 
#   При этом отсекая имя модуля от экшна перед вызовом (восстанавливаем после экшна).
    ^if(^hasAction[$lModule]){
      $_action[^aAction.match[([^^/\.]+)(.*)][]{$match.2}]
      $result[^self.[^_makeActionName[$lModule]][$aRequest]]
      $_action[$aAction]
    }{                                                                                                   
       $result[^self.[mod^_makeSpecialName[$lModule]].dispatch[^aAction.mid(^lModule.length[]);$aRequest;$.prefix[$_uriPrefix]]]
     }
  }{                                                        
    $uriPrefix[^if(def $lRewrite.prefix){/$lRewrite.prefix/}{^if(def $aOptions.prefix){$aOptions.prefix}{/}}] 
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

@rewriteAction[aAction;aRequest][lRewrite;it]
## Вызывается каждый раз перед диспатчем - внутренний аналог mod_rewrite.
## $result.action - новый экшн.
## $result.args - параметры, которые надо добавить к аргументам и передать обработчику. 
## $result.prefix - префикс, который необходимо передать диспетчеру
## Стандартный обработчик проходит по карте преобразований и ищет пододящий шаблон, 
## иначе возвращает оригинальный экшн. 
  $result[^router.route[$aAction;$.args[$aRequest]]]
  ^if(!$result){
    $result[$.action[$aAction] $.args[] $.prefix[]]
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
   
@_makeLinkURI[aAction;aOptions;aAnchor]
## Формирует url для экшна
## $uriPrefix$aAction?aOptions.foreach[key=value][&]#aAnchor 
  ^if(def $aAction){$aAction[^aAction.trim[both;/.]]} 
  $result[$uriPrefix^if(def $aAction){$aAction/}]
  ^if(def $result && ^result.match[\.[^^/]+?/+^$][n]){$result[^result.trim[end;/]]}
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
