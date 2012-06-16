# PF Library

## Класс оставлен исключительно для совместимости со старфм кодом.
## Сейчас можно создать любой модуль как менеджер: ^pfSiteModule::create[... $.asManager(true)]

@CLASS
pfSiteManager

@USE
pf/web/pfSiteModule.p

@BASE
pfSiteModule

#----- Constructor -----

@create[aOptions]
## aOptions.request
  ^cleanMethodArgument[]
  ^BASE:create[^hash::create[$aOptions] $.asManager(true)]
