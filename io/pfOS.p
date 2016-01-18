# PF Library

@CLASS
pfOS

#@doc
##  Класс с функциями для работы с ОС (файловые системы и т.п.).
#/doc

@USE
pf/tests/pfAssert.p

@create[]
## Конструктор. Если кому-то понадобится использовать класс динамически.

@copy[aFrom;aTo;aOptions]
## Копирует файл или папку
## with $.is_recursive(1) all subdirectories will be copyed as well
  ^if(def $aFrom && def $aTo){
    ^if(-f $aFrom){
      ^fileCopy[$aFrom;$aTo]
    }
    ^if(-d $aFrom){
      ^dirCopy[$aFrom;$aTo;$aOptions]
    }
  }
  $result[]

@rm[path;mask;recurse][list]
## Удаление всех файлов и папок в текущем каталоге
## $path - путь
## $mask - маска для file:list
## $recurse(0) - удялять только то, что указано
## $result:
## 0 - удаление завершено успешно
## 1 - каталог не найден по указанному пути
## 2 - файл не найден по указанному пути
## 3 - каталог не содержит файлов или папок

  ^rem{ *** Проверяем существует ли папка *** }
  ^if(-d $path){
    ^rem{ *** Получаем список файлов и папок *** }
    $list[^file:list[$path;$mask]]
    ^if($list){
      ^list.menu{
        ^if(-f "${path}$list.name"){
          ^rem{ *** Удаляем все файлы из папки, папки не удаляются *** }
          ^file:delete[${path}$list.name]
        }{
          $result(2)
        }
      }
    }{
      $result(3)
    }
  
    ^rem{ *** Если папка не пустая и нет признака recurse проверяем вложенные папки *** }
    ^if(^recurse.int(0) && $result != 3){
      ^rem{ *** Проверяем что осталось в папке *** }
      $list[^file:list[$path]]
      ^if($list){
        ^rem{ *** Рекурсивно вызываем оператор удаления *** }
        ^list.menu{^rm[${path}${list.name}/;$mask;1]}
      }
    }
    $result(0)
  }{
    $result(1)
  }

###########################################################################
@fileSize[sFileName;hName;sDivider][fFile]
# print string with file size. bytes/KB/MB texts and delimiter can be overrided
  ^if(def $sFileName && -f $sFileName){
    ^if(!$hName){$hName[$.b[байт]$.kb[КБ]$.mb[МБ]]}
    $fFile[^file::stat[$sFileName]]
    ^if($fFile.size < 1000){
      $result[$fFile.size $hName.b]
    }{
      ^if($fFile.size < 1000000){
        $result[^eval($fFile.size/1024)[%.1f] $hName.kb]
      }{
        $result[^eval($fFile.size/1048576)[%.1f] $hName.mb]
      }
    }
    $result[^result.match[\.0(\s)][]{$match.1}]
    ^if(def $sDivider){
      $result[^result.match[\.][]{$sDivider}]
    }
  }{
    $result[]
  }

@fileCopy[sFileFrom;sFileTo][fFile]
## coping file $sFileFrom to $sFileTo
  ^if(def $sFileFrom && def $sFileTo && $sFileFrom ne $sFileTo && -f $sFileFrom){
    ^try{
      ^file:copy[$sFileFrom;$sFileTo]
    }{
        ^rem{ *** for parser without ^file:copy[] *** }
        $exception.handled(1)
        $fFile[^file::load[binary;$sFileFrom]]
        ^fFile.save[binary;$sFileTo]
    }
  }
  $result[]

@dirCopy[sDirFrom;sDirTo;hParam][tFileList]
## copy directory $sDirFrom to $sDirTo
## with $.is_recursive(1) all subdirectories will be copyed as well
  ^if(def $sDirFrom && -d $sDirFrom && def $sDirTo && $sDirFrom ne $sDirTo){
    $tFileList[^file:list[$sDirFrom]]
    ^tFileList.menu{
      ^if($hParam.is_recursive && -d "$sDirFrom/$tFileList.name"){
        ^dirCopy[$sDirFrom/$tFileList.name;$sDirTo/$tFileList.name;$hParam]
      }
      ^if(-f "$sDirFrom/$tFileList.name"){
        ^fileCopy[$sDirFrom/$tFileList.name;$sDirTo/$tFileList.name]
      }
    }
  }
  $result[]

@getMimeType[aFileName]
## Возвращает mime-тип для файла
  ^if(^MAIN:MIME-TYPES.locate[ext;^file:justext[^aFileName.lower[]]]){
    $result[$MAIN:MIME-TYPES.mime-type]
  }{
     $result[text/plain]
   }

@tempFile[aPath;aVarName;aCode;aFinallyCode][lTempFileName]
## Формирует на время выполнения кода aCode уникальное имя для временного
## файла в папке aPath. После работы кода удаляет временный файл, если он создан.
## Если задан параметр aFinallyCode, то он запускается, даже если произошла ошибка.
  ^pfAssert:isTrue(def $aVarName)[Не задано имя переменной для названия временного файла.]
  ^try{
    $lTempFileName[^aPath.trim[end;/\]/${status:pid}_^math:uid64[].tmp]
    $caller.[$aVarName][$lTempFileName]
    $result[$aCode]
  }{}{
     $aFinallyCode
     ^if(-f $lTempFileName){
       ^file:delete[$lTempFileName]
     }
  }

@hashFile[aFileName;aVarName;aCode][lHashfile]
## Открывает хешфайл с имененм aFileName и выполняет код для работы с этим файлом.
## Файл доступен коду в переменной с именем aVarName.
## После работы выполняет release хешфайла.
  ^pfAssert:isTrue(def $aVarName)[Не задано имя переменной для хешфайла.]
  $lHashfile[^hashfile::open[$aFileName]]
  ^try{
    $caller.[$aVarName][$lHashfile]
    $result[$aCode]
  }{}{
    ^lHashfile.release[]
  }

@absolutePath[aPath;aBasePath][lBaseParts;lParts;lStep;i]
## Возвращает полный путь к файлу относительно aBasePath[$request:document-root].
  $aPath[^file:fullpath[$aPath]]
  $aPath[^aPath.trim[both;/\]]
  $aBasePath[^if(def $aBasePath){^aBasePath.trim[both;/\]}{^request:document-root.trim[both;/\]}]
  $lParts[^aPath.split[/]]
  
# Вычисляем число уровней на которые нам надо подняться
  $lStep(0)
  ^for[i](1;$lParts){
    ^lParts.offset[set]($i - 1)
    ^if($lParts.piece eq ".."){^lStep.inc[]}{^break[]}
  }

  ^if($lStep){
    $lBaseParts[^aBasePath.split[/]]
    $result[/^for[i](1;$lBaseParts-$lStep){^lBaseParts.offset[set]($i - 1)$lBaseParts.piece}[/]/^for[i]($lStep+1;$lParts){^lParts.offset[set]($i - 1)$lParts.piece}[/]]
  }{
     $result[/$aBasePath/$aPath]
   }

@walk[aPath;aVarName;aCode;aSeparator][lFiles]
## Обходит дерево файлов начиная с aPath и выполняет для каждого найденного файла aCode.
## Имя файла c путем попадает в переменную с именем из aVarName.
## Файлы сортируются по именам.
## Между вызовами aCode вставляется aSeparator.
  ^pfAssert:isTrue(def $aVarName)[Не задано имя переменной для имени файлов.]
  $aPath[^aPath.trim[right;/\]]
  $lFiles[^file:list[$aPath]]
  ^lFiles.sort{$lFiles.name}[asc]
  $result[^if($lFiles && ^aVarName.left(7) eq "caller."){$aSeparator}^lFiles.menu{^process{^$caller.caller.$aVarName^[$aPath/$lFiles.name^]}$aCode^if(-d "$aPath/$lFiles.name"){^walk[$aPath/$lFiles.name;caller.$aVarName]{$aCode}[$aSeparator]}}[$aSeparator]]
  ^if(^aVarName.left(7) ne "caller."){$caller.$aVarName[]}
  