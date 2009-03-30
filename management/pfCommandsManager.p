@CLASS
pfCommandsManager

@USE
pf/modules/pfModule.p
pf/tests/pfAssert.p
pf/collections/pfArrayList.p

@BASE
pfModule

@create[aOptions]
## aOptions.path - путь поиск команд
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]

#  ^pfAssert:isTrue(def $aOptions.path && -d $aOptons.path)[Путь "$aOptions.path" не существует.]
#  $_commandsPath[$aOptions.path]

  $_commandsPath[/commands]
  ^defReadProperty[commandsPath]

  $_commandsArgs[$aOptions.args]
  ^defReadProperty[commandsArgs]

  $_commandsNames[^pfArrayList::create[]]
  ^defReadProperty[commandsNames]

  ^_findCommands[$commandsPath]

#  ^commandsNames.foreach[it]{
#    ^pfConsole:writeln[$it - $MODULES.[$it].object.help]
#  }

@process[aArgs]
  ^cleanMethodArgument[aArgs]
  ^if($aArgs){
    ^aArgs.foreach[k;v]{
      ^pfConsole:writeln[$k -> $v]
      
    }
  }

#----- Private -----

@_findCommands[aPath][lFiles;lCommandName]
## Ищем команды в папке $aPath. 

  $lFiles[^file:list[$aPath;\.p^$]]
  $lFiles[^lFiles.select(-f "$aPath/$lFiles.name")]
  ^lFiles.sort{$lFiles.name}
  
  ^lFiles.menu{
     $lCommandName[^file:justname[$lFiles.name]]
     ^assignModule[$lCommandName;
       $.class[^_makeSpecialName[$lCommandName]Command]
       $.file[$aPath/$lFiles.name]
       $.args[$commandsArgs]
       $.compile(true)
     ]
     ^commandsNames.add[$lCommandName]
  }
  
