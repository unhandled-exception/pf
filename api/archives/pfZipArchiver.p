# PF Library

## Класс для работы с zip-архивом.
## [Пока только распаковка файлов.]

@CLASS
pfZipArchiver

@USE
pf/types/pfClass.p
pf/io/pfOS.p

@BASE
pfClass

@auto[aFilespec]
  $[__^CLASS_NAME.upper[]_FILESPEC__][^aFilespec.match[^^(^taint[regex][$request:document-root])][][]]

@create[aOptions]
## aOptions.unzipPath[] - путь к unzip-скрипту
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]   

  $_unzipPath[^if(def $aOptions.unzipPath){$aOptions.unzipPath}{^file:dirname[$__PFZIPARCHIVER_FILESPEC__]/bin/unzip}]
  ^_cleanLastError[]

@list[aZipFile;aOptions][lExec]
## aOptions.charset[$request:charset]
  ^cleanMethodArgument[]
  ^_cleanLastError[]
  $lExec[^file::exec[$_unzipPath;^if(def $aOptions.charset){$aOptions.charset}{$request:charset};-Z1;^pfOS:absolutePath[$aZipFile]]]
  ^if($lExec.status){
    ^_error(true)[$lExec.status;$lExec.text;$lExec.stderr]
  }
  $result[^table::create[nameless]{$lExec.text}]
  
@load[aZipFile;aFileName;aOptions]
## aOptions.mode[text]
## aOptions.convertLF(false) 
## aOptions.charset[$request:charset]
## aOptions.ignoreCase(false)
  ^cleanMethodArgument[]
  ^_cleanLastError[]
  $lExec[^file::exec[^if($aOptions.mode eq "binary"){binary}{text};$_unzipPath;$.charset[^if(def $aOptions.charset){$aOptions.charset}{$request:charset}];-p;^if(^aOptions.convertLF.bool(false)){-a};^if(^aOptions.ignoreCase.bool(false)){-C};^pfOS:absolutePath[$aZipFile];$aFileName]]
  ^if($lExec.status){
    ^_error(true)[$lExec.status;$lExec.text;$lExec.stderr]
  }
  $result[$lExec]

@test[aZipFile;aOptions]
  ^_cleanLastError[]
  $lExec[^file::exec[$_unzipPath;;-t;^pfOS:absolutePath[$aZipFile]]]
  $result(!$lExec.status)
  ^if(!$result){
    ^_error(false)[$lExec.status;$lExec.text;$lExec.stderr]
  }

@extractFile[aZipFile;aOptions]
  ^_cleanLastError[]
  $result[]
  ^throw[mega.fail;Не реализовано!]


#----- Private -----

@_cleanLastError[]
  $lastErrorCode[]
  $lastErrorMessage[]
  
@_error[aThrowException;aCode;aScriptResult;aStdErr]
  $lastErrorCode[$aCode]
  $lastErrorMessage[^if(def $aStdErr){$aStdErr}{$aScriptResult}]
  ^if($aThrowException){
    ^throw[pfZipArchiver.fail;Ошибка при выполнении скрипта ($lastErrorCode);$lastErrorMessage]
  }

