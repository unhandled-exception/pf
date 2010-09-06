# PF Library

@CLASS
pfModule

@USE
pf/types/pfClass.p
pf/types/pfString.p
pf/modules/pfRouter.p

@BASE
pfClass

#----- Constructor -----

@create[aOptions]
## Конструктор класса
## aOptions.uriPrefix[/] - префикс для uri. Нужно передавать только в головной модуль, 
##                         поскольку метод assignModule будт передавать свой собственный
##                         префикс.
## aOptions.parentModule - ссфлка на объект-контейнер.
## aOptions.appendSlash(false) - нужно ли добавлять к урлам слеш.
  ^BASE:create[]
  ^cleanMethodArgument[]
  $_throwPrefix[pfModule]
  $_name[$aOptions.name]

  $_parentModule[$aOptions.parentModule]
  
  $_MODULES[^hash::create[]]  
  $uriPrefix[^if(def $aOptions.uriPrefix){$aOptions.uriPrefix}{/}]

  $_appendSlash(^aOptions.appendSlash.bool(true))

  $_action[]      
  $_request[]
  $_router[^pfRouter::create[]]   

@auto[]
  $_pfModuleActionPartRegex[^regex::create[([^^/\.]+)(.*)]] 
  $_pfModuleCheckDotRegex[^regex::create[\.[^^/]+?/+^$][n]]
  $_pfModuleRepeatableSlashRegex[^regex::create[/+][g]]
  
#----- Properties -----

@GET_uriPrefix[]
  $result[$_uriPrefix]

@SET_uriPrefix[aUriPrefix]  
  $_uriPrefix[$aUriPrefix/]
  $_uriPrefix[^_uriPrefix.match[$_pfModuleRepeatableSlashRegex][][/]]
  
@GET_action[]
  $result[$_action]

@GET_request[]
  $result[$_request]
  
@GET_MODULES[]
  $result[$_MODULES]

@GET_router[]
  $result[$_router]

@GET_appendSlash[]
  $result($_appendSlash)

@SET_appendSlash[aValue]
  $_appendSlash(^aValue.bool(true))

@GET_PARENT[]
  $result[$_parentModule]

#---- Public -----

@hasModule[aName]
## Проверяет есть ли у нас модуль с имененм aName
  $result(^_MODULES.contains[^aName.lower[]])

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
  ^pfAssert:isTrue(def $aName)[Не задано имя для модуля.]
  $aName[^aName.lower[]]

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
       
       $.args[^if(def $aOptions.args){$aOptions.args}{^hash::create[]} $.parentModule[$self]]
       $.object[]
       
       $.isCompiled(0)
       $.makeAction(^aOptions.makeAction.int(1))   
       $.uriPrefix[${uriPrefix}$aName/]
   ]

#  Перекрываем uriPrefix, который пришел к нам в $aOptions.args.
#  Возможно и не самое удачное решение, но позволяет сохранить цепочку.
   $_MODULES.[$aName].args.uriPrefix[$_MODULES.[$aName].uriPrefix]
        
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
  $result[]
  $aName[^aName.lower[]]
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
        ^if(def $_MODULES.[$aName].file){
          ^use[$_MODULES.[$aName].file]
        }
       }
      $_MODULES.[$aName].object[^reflection:create[$_MODULES.[$aName].class;create;$_MODULES.[$aName].args $.appendSlash[$appendSlash]]]
      $_MODULES.[$aName].isCompiled(1)  
     }
  }{
     ^throw[pfModule.compile;Module "$aName" not found.]
   }

@dispatch[aAction;aRequest;aOptions][lProcessed]
## Производим обработку экшна
## aAction    Действие, которое необходимо выполнить
## aRequest   Параметры экшна      
## aOptions.prefix
  ^cleanMethodArgument[]
  $result[]
 
  $lAction[^if(def $aAction){^aAction.trim[both;/.]}]

  $lProcessed[^processRequest[$lAction;$aRequest;$aOptions]]
  $lProcessed.action[^lProcessed.action.lower[]]
  
  $_action[$lProcessed.action]
  $_request[$lProcessed.request]

  $result[^processAction[$lProcessed.action;$lProcessed.request;$lProcessed.prefix;$aOptions]]
  $result[^processResponse[$result;$lProcessed.action;$lProcessed.request;$aOptions]]

@processRequest[aAction;aRequest;aOptions][lRewrite]
## Производит предобработку запроса
## $result[$.action[] $.request[] $.prefix[]] - экшн, запрос и префикс, которые будут переданы обработчикам
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
  $result[$.action[$aAction] $.request[$aRequest] $.prefix[$lRewrite.prefix]]

@rewriteAction[aAction;aRequest;aOtions][lRewrite;it]
## Вызывается каждый раз перед диспатчем - внутренний аналог mod_rewrite.
## $result.action - новый экшн.
## $result.args - параметры, которые надо добавить к аргументам и передать обработчику. 
## $result.prefix - префикс, который необходимо передать диспетчеру
## Стандартный обработчик проходит по карте преобразований и ищет подходящий шаблон, 
## иначе возвращает оригинальный экшн. 
  $result[^router.route[$aAction;$.args[$aRequest]]]
  ^if(!$result){
    $result[$.action[$aAction] $.args[] $.prefix[]]
  }
    
@processAction[aAction;aRequest;aPrefix;aOptions][lModule;lActionHandler;lHandler;lAction;CALLER;lRequest;lPrefix]
## Производит вызов экшна.
## aOptions.aPrefix - префикс, сформированный в processRequest.                                    
  $lAction[$aAction]
  $lRequest[$aRequest]
  $lPrefix[^if(def $aPrefix){$aPrefix}{$aOptions.prefix}]
  $uriPrefix[^if(def $lPrefix){/$lPrefix}/] 

# Формируем специальную переменную $CALLER, чтобы передать текущий контекст 
# из которого вызван dispatch. Нужно для того, чтобы можно было из модуля
# получить доступ к контейнеру, не городя передачу оному $self отдельным параметром.
  $CALLER[$self]

# Если у нас в первой части экшна имя модуля, то передаем управление ему
  $lModule[^lAction.match[$_pfModuleActionPartRegex][]{$match.1}]
  ^if(def $lModule && ^hasModule[$lModule]){  
#   Если у нас есть экшн, совпадающий с именем модуля, то зовем его. 
#   При этом отсекая имя модуля от экшна перед вызовом (восстанавливаем после экшна).
    ^if(^hasAction[$lModule]){
      $_action[^lAction.match[$_pfModuleActionPartRegex][]{^match.2.lower[]}]
      $result[^self.[^_makeActionName[$lModule]][$lRequest]]
      $_action[$lAction]
    }{                                         
       $result[^self.[mod^_makeSpecialName[^lModule.lower[]]].dispatch[^lAction.mid(^lModule.length[]);$lRequest;
         $.prefix[/^if(def $aPrefix){$aPrefix/}{/^if(def $lPrefix){$lPrefix/}$lModule/}]
       ]]                                                  
     }
  }{                          
#   Если модуля нет, то пытаемся найти и запустить экш из нашего модуля
#   Если не получится, то зовем onDEFAULT, а если и это не получится,
#   то выбрасываем эксепшн.
     $lHandler[^_findHandler[$lAction;$lRequest]]
     ^if(def $lHandler){
       $result[^self.[$lHandler][$lRequest]]
     }{
        ^throw[module.dispatch.action.not.found;Action "$lAction" not found.]
      }
   }

@processResponse[aResponse;aAction;aRequest;aOptions]
## Производит постобработку результата выполнения экшна.
  $result[$aResponse]
     
@linkTo[aAction;aOptions;aAnchor][lReverse]
## Формирует ссылку на экшн, выполняя бэкрезолв путей.
## aOptions - объект, который поддерживает свойство $aOptions.fields (хеш, таблица и пр.)
  ^cleanMethodArgument[]
  $lReverse[^router.reverse[$aAction;$aOptions.fields]]
  ^if($lReverse){
    $result[^_makeLinkURI[$lReverse.path;$lReverse.args;$aAnchor]]
  }{
     $result[^_makeLinkURI[$aAction;$aOptions.fields;$aAnchor]]
   }

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
  ^cleanMethodArgument[]
  ^if(def $aAction){$aAction[^aAction.trim[both;/.]]} 

  $result[$uriPrefix^if(def $aAction){^taint[uri][$aAction]^if($_appendSlash){/}}]
  ^if($_appendSlash && def $result && ^result.match[$_pfModuleCheckDotRegex]){$result[^result.trim[end;/]]}

  ^if($aOptions is hash && $aOptions){
    $result[${result}?^aOptions.foreach[key;value]{$key=^taint[uri][$value]}[^taint[&]]]
  }
  ^if(def $aAnchor){$result[${result}#$aAnchor]}

@_makeActionName[aAction][lSplitted;lFirst]
## Формирует имя метода для экшна.
  ^if(def $aAction){
    $aAction[^aAction.lower[]]
    $lSplitted[^pfString:rsplit[$aAction;[/\.]]]
    ^if($lSplitted){
     $result[on^lSplitted.menu{^_makeSpecialName[$lSplitted.piece]}]
   }
  }{
     $result[onINDEX]
   }
  
@_makeSpecialName[aStr][lFirst]
## Возвращает aStr в которой первая буква прописная    
  $lFirst[^aStr.left(1)]
  $result[^lFirst.upper[]^aStr.mid(1)] 

@_findHandler[aAction;aRequest]
## Ищет и возвращает имя функции-обработчика для экшна.
  $result[^_makeActionName[$aAction]]
  ^if(!def $result || !($self.[$result] is junction)){
    $result[^if($onDEFAULT is junction){onDEFAULT}]
  }
