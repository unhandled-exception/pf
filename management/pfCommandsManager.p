# PF Library

#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

@CLASS
pfCommandsManager

@USE
pf/modules/pfModule.p
pf/tests/pfAssert.p
pf/collections/pfList.p
pf/debug/pfRuntime.p

@BASE
pfModule

@create[aOptions]
## aOptions.path[/commands] - путь поиск команд
## aOptions.args - хеш с данными, которые передаются конструктору команд
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]

  $_commandsPath[^if(def $aOptions.path){$aOptions.path}{/commands}]
  ^pfAssert:isTrue(def $_commandsPath && -d $_commandsPath)[Путь "$_commandsPath" не существует.]

  $_commandsArgs[$aOptions.args]
  $_commandsNames[^pfList::create[]]

  ^defReadProperty[commandsArgs]
  ^defReadProperty[commandsPath]
  ^defReadProperty[commandsNames]

  ^_findCommands[$commandsPath]

@availableCommands[]
## Выводит информацию обо всех доступных модулях
  ^if($commandsNames){
    ^writeln[Available commands:]
    ^commandsNames.foreach[it]{
      ^writeln[$it]
    }
  }

@process[aArgs]
  ^cleanMethodArgument[aArgs]
  ^dispatch[$aArgs.1;$aArgs]


@writeln[aLine]
## Выводит строку на терминал.
  ^pfConsole:writeln[$aLine]

@writeTimeLine[aLine][lNow]
## Выводит строку с отметокой времени
  $lNow[^date::now[]]
  ^writeln[[^lNow.sql-string[]] $aLine]

@onDEFAULT[aArgs]
  ^writeln[The command "$action" not found.]


@onHelp[aArgs][locals]
  $lCommand[$aArgs.2]
  ^if(def $lCommand){
    ^if(^_containsCommand[$lCommand]){
      ^writeln[$self.[mod$lCommand]._usage]
    }{
       ^_helpUsage[$aArgs]
     }
  }{
    ^_helpUsage[$aArgs]
  }

@_helpUsage[aArgs]
  ^writeln[Usage: ^file:justname[$aArgs.0] help command]
  ^writeln[]
  ^availableCommands[]

#----- Private -----

@_findCommands[aPath][lFiles;lCommandName]
## Ищем команды в папке $aPath.

  $lFiles[^file:list[$aPath;\.p^$]]
  $lFiles[^lFiles.select(-f "$aPath/$lFiles.name")]
  ^lFiles.sort{$lFiles.name}

  ^lFiles.menu{
     $lCommandName[^file:justname[$lFiles.name]]
     ^commandsNames.add[$lCommandName]
     ^assignModule[$lCommandName;
       $.class[^_makeSpecialName[$lCommandName]Command]
       $.file[$aPath/$lFiles.name]
       $.args[$_commandsArgs]
       $.compile(true)
     ]
  }

@_containsCommand[aCommand][locals]
  $result(false)
  ^commandsNames.foreach[it]{
    ^if($it eq $aCommand){
      $result(true)
      ^break[]
    }
  }
