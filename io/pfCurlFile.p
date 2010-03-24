# PF Library

#@info Класс для загрузки файлов через curl.
#@author Oleg Volchkov <oleg@volchkov.net>                                                                                                          
#@web http://oleg.volchkov.net

#@compat 3.2.2

#@doc 
## Обеспечивает интерфейс, подобный стандартному классу "file",
## но для загрузки используется косольная утилита curl.
## В качестве адреса необходимо указывать строку в формате URL.
## 
#/doc

@CLASS
pfCurlFile

@USE
pf/tests/pfAssert.p
pf/types/pfClass.p
pf/types/pfString.p

@BASE
pfClass

#----- Constructor -----

@auto[]
  ^if(def $MAIN:CURL_PATH && -f $MAIN:CURL_PATH){
    $_CURL_PATH[$MAIN:CURL_PATH]
  }{
     $_CURL_PATH[/../bin/curl]
   }

  $_protocols[
    $._default(false)
    $.http(true)
    $.https(true)
    $.ftp(true)
    $.file(true)
  ]
 
  $_defaultUserAgent[parser3 (pfCurlFile)/$env:PARSER_VERSION]
  $_throwPrefix[$self.CLASS_NAME]

@load[aFormat;aURL;aArgs1;aArgs2][lMatches]
## ^pfCurlFile::load[format;url;options]
## ^pfCurlFile::load[format;url;new_name;options]

## aFormat[text|binary] - формат файла.
## aURL[] - путь к файлу.

## options.charset[$request:charset] - кодировка.
## options.timeout(2) - таймаут в секундах.
## options.user - имя пользователя.
## options.password - пароль.

## options.offset, aOptions.limit - загрузить только определенное количество байт.
##                               Отработает, если эта фича поддерживается сервером.

## HTTP
## options.compressed(false) - использовать компрессию для http-соединений.
## options.headers[ $.HTTP-ЗАГОЛОВОК[значение] ... ] - значение может быть строкой 
##                               или именованной таблицей с одной колонкой.
## options.form[$.name[] ...] - параметры запроса. Значением может выступать 
##                               строка или таблица строк с одним столбцом. 
##                               Не передаются, если метод HEAD.
## options.body[] - заменяет запрос. Если задан body, то form игнорируется.
## options.any-status - игнорировать ошибочные результаты http-ответов.

## SSL

  ^if($aArgs1 is hash){
    $_options[^hash::create[$aArgs1]]
    $_name[]
  }{
     $_name[$aArgs1]
     ^if($aArgs2 is hash){
       $_options[^hash::create[$aArgs2]]
     }{
        $_options[^hash::create[]]
      }
   }

  ^if(!def ${_options.user-agent}){$_options.user-agent[$_defaultUserAgent]}
  $_options.timeout(^_options.timeout.int(2))

  $_URL[^pfString:parseURL[$aURL]]
  ^if(!$_URL){
    ^_throw[3]
  }
  $_format[$aFormat]

  $_isBinary($aFormat eq "binary")
  $_isHTTP($_URL.protocol eq "http" || $_URL.protocol eq "https")
  $_isSSL($_URL.protocol eq "https")
  $_canParseHeaders($_isHTTP && $aFormat eq "text")

  $_headers[^hash::create[]]
  $_tables[^hash::create[]]
  $_content-type[]

  $lENV[^hash::create[]]
  ^if(def $_options.charset){
    $lENV.charset[$_options.charset]
  }
  ^if($_isHTTP && def $_options.body){
    $lENV.stdin[$_options.body]
  }

  $_file[^file::exec[$aFormat;$_CURL_PATH;$lENV;^_makeOptions[]]]
  ^if($_file.status){
    ^_throw[$_file.status;$_file.stderr]
  }

# Разделяем результат на заголовки и тело
  ^if($_isHTTP){
    ^if($_canParseHeaders){
      ^_file.text.match[^^(?:HTTP/1\.1\s100.+?\n\n)*(.+?)\n\n(.*)^$][i]{
        $_file[^file::create[text;$_URL.url;$match.2]]
        ^match.1.match[^^HTTP\S+\s(\d+)(.*?)\n][]{$_status($match.1) $_comment[$match.2]}
        $lMatches[^match.1.match[^^(\S+?):\s+(.*)^$][gm]]
        ^if($lMatches){
          ^lMatches.menu{
            ^if(!def $_headers.[$lMatches.1]){
              $_headers.[^lMatches.1.upper[]][$lMatches.2]
              $_tables.[^lMatches.1.upper[]][^table::create{value^#0A$lMatches.2}]
            }{
               ^_tables.[^lMatches.1.upper[]].append{$lMatches.2}
             }
          }
        }
        ^if(def $_headers.[CONTENT-TYPE]){
          ^_headers.[CONTENT-TYPE].match[^^(\S+?)\^;][]{$_content-type[$match.1]}
        }
      }
    }{
       ^if(!${_options.any-status}){
         $_status(200)
       }
     }
  }  

#----- Properties -----

@GET_status[]
  $result[^_status.int(0)]

@GET_comment[]
  $result[$_comment]

@GET_content-type[]
  $result[^if(def ${_content-type}){$_content-type}{$_file.content-type}]

@GET_text[]
  $result[$_file.text]

@GET_size[]
  $result[$_file.size]

@GET_stderr[]
  $result[$_file.stderr]

@GET_headers[]
  $result[$_headers]

@GET_name[]
  $result[^if(def $_name){$_name}{$_URL.url}]

@GET_tables[]
  $result[$_tables]

@GET_data[]
## Возврашает переменную типа file
  $result[$_file]

#----- Public -----
@save[aFormat;aName]
  ^_file.save[$aFormat;$aName]

@sql-string[]
  $result[^_file.sql-string[]]

@base64[]
  $result[^_file.base64[]]

@md5[]
  $result[^_file.md5[]]

@crc32[]
  $result[^_file.crc32[]]

#----- Private -----

@_throw[aStatus;aStdErr][lType;lSource;lComment]
  ^switch[$aStatus]{
    ^case[3]{
      $lType[url.malformat]
      $lSource[URL malformat]
      $lComment[$aStdErr]
    }
    ^case[6]{
      $lType[http.host]
      $lSource[Host not found]
      $lComment[$aStdErr]
    }
    ^case[7]{
      $lType[http.connect]
      $lSource[Failed to connect to host]
      $lComment[$aStdErr]
    }
    ^case[28]{
      $lType[http.timeout]
      $lSource[Operation timeout]
      $lComment[$aStdErr]
    }
    ^case[22]{
      $lType[http.status]
      $lSource[$aStdErr]
      $lComment[$name]
    }
    ^case[DEFAULT]{
      $lType[${_throwPrefix}.fail]
      $lSource[curl: $aStatus]
      $lComment[$aStdErr]
    }
  }
  ^throw[$lType;$lSource;$lComment]

@_makeOptions[][lColumns;lMethod]
  $result[^table::create{arg}]

  ^result.append{--connect-timeout}
  ^result.append{$_options.timeout}

  ^if($_isHTTP){
    ^if(!$_isBinary){^result.append{--include}}
    ^if(!${_options.any-status}){^result.append{--fail}}

    ^result.append{--user-agent}
    ^result.append{$_options.user-agent}

    ^if(^aOptions.compressed.bool(true)){^result.append{--compressed}}

    $lMethod[^if(def $_options.method){^_options.method.upper[]}]
    ^switch[$lMethod]{
      ^case[GET;DEFAULT]{^result.append{--get}}
      ^case[POST]{}
      ^case[HEAD]{^result.append{--head}}
    }

#   Формируем http-заголовки
    ^if($_options.headers is hash && $_options.headers){
      ^_options.headers.foreach[k;v]{
        ^switch(true){
          ^case($v is table){
            $lColumns[^v.columns[]]
            ^v.menu{
              ^result.append{--header}
              ^result.append{${k}: $v.[$lColumns.column]}
            }
          }
          ^case($v is date){
#           Доделать работу с датами
          }
          ^case[DEFAULT]{
            ^result.append{--header}
            ^result.append{${k}: $v}
          }
        }
      }
    }

#   Добавляем данные из формы
    ^if(!def $_options.body && $_options.form is hash && $_options.form && $lMethod ne "HEAD"){
      ^result.append{--data}
      ^result.append{^_options.form.foreach[k;v]{^if($v is table){$lColumns[^v.columns[]]^v.menu{${k}=^taint[uri][$v.[$lColumns.column]]}[&]}{${k}=^taint[uri][$v]}}[&]}
    }

#   Обрабатываем body
    ^if(def $_options.body && $lMethod ne "HEAD"){
      ^result.append{--data-binary}
      ^result.append{@-}
    }

  }

  ^if($_isSSL){
#   Несекьюрный режим
    ^result.append{--insecure}
  }

# Частичная загрузка контента (только если поддерживает удаленный сервер)
  $lLimit[^_options.limit.int(0)]
  $lOffset[^_options.offset.int(0)]
  ^if($lLimit|| $lOffset){
    ^result.append{--range}
    ^result.append{${lOffset}-^if($lLimit){$lLimit}}
  }

  ^if(def $_options.user){
    ^result.append{--user}
    ^result.append{$_options.user:$_options.password}
  }

  ^result.append{-#}
  ^result.append{$_URL.url}

#   ^pfAssert:fail[^result.menu{$result.arg}[ ]]

