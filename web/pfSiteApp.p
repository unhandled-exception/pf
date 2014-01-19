# PF Library

## Менеджер для отделяемых приложения на базе PF'а.

@CLASS
pfSiteApp

@USE
pf/web/pfSiteModule.p

@BASE
pfSiteModule

#----- Constructor -----

@create[aOptions]
## aOptions.serveStatic(false) — обрабатывать статику на уровне приложения.
## aOptions.appRoot[] — путь к корневой папке приложения.
## aOptions.publicFolder[public]
## aOptions.viewsFolder[views]
  ^cleanMethodArgument[]
  ^BASE:create[$aOptions]

  ^pfAssert:isTrue(def $aOptions.appRoot)[Не задан путь к корневой папке приложения (appRoot).]
  ^pfAssert:isTrue(-d $aOptions.appRoot)[Папка «${aOptions.appRoot}» (appRoot) не найдена.]
  $_appRoot[^aOptions.appRoot.trim[end;/\]]
  ^defReadProperty[appRoot]

  $_publicFolder[^if(def $aOptions.publicFolder){$aOptions.publicFolder}{public}]
  $_viewsFolder[^if(def $aOptions.viewsFolder){$aOptions.viewsFolder}{views}]
  $templatePath[$_appRoot/$_viewsFolder]
  ^TEMPLET.appendPath[/]

  $_serveStatic(^aOptions.serveStatic.bool(false))
  $_publicPath[$_appRoot/$_publicFolder]

  $_now[^date::now[]]
  $_today[^date::today[]]


#----- Events -----

@onNOTFOUND[aRequest][locals]
  $lFileName[$_publicPath/$action]
  ^if($_serveStatic && -f $lFileName){
#   Выдаем статику в браузер, если включен режим serveStatic.
#   Штука очень простая и подходит только для отладки.
#   Для работы лучше сделать симлинк или алиас средствами веб-сервера.
    $result[
      $.type[file]
      $.content-type[^_getMimeByExt[^file:justext[$lFileName]]]
      $.body[
        $.file[$lFileName]
      ]
    ]
  }{
     $result[^on404[$aRequest]]
   }

@on404[aRequest]
  $result[^pfHTTPResponseNotFound::create[]]



