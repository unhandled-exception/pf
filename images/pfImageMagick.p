# PF Library

#@info Класс для работы с консольными скриптами ImageMagick.
#@author Oleg Volchkov <oleg@volchkov.net>
#@web http://oleg.volchkov.net

#@compat 3.2.2

#@doc
#/doc

@CLASS
pfImageMagick

@USE
pf/types/pfClass.p
pf/tests/pfAssert.p

@BASE
pfClass

#----- Constructor -----

@create[aOptions]
## aOptions.scriptPath[/../bin] - путь к скриптам ImageMagick
  ^cleanMethodArgument[]
  ^BASE:create[]

  $_throwPrfeix[$self.CLASS_NAME]
  $_scriptPath[^if(def $aOptions.scriptPath && -d $aOptions.scriptPath){^aOptions.scriptPath.trim[end;/]}{/../bin}]

#----- Public -----

@identify[aImageFileName][lExec]
## Возвращает хеш с информацией об изображении
  ^pfAssert:isTrue(-f $aImageFileName)[Файл "$aImageFileName" не найден на сервере.]

  $lExec[^file::exec[$_scriptPath/identify;;-format;height: %h\nwidth: %w\ntype: %m\nquality: %Q\ndepth: %q\nxResolution: %x\nyResolution: %y\ncompressionType: %C\ndisposeMethod: %D\ncolorSpace: %r\n%[EXIF:*];-quiet;-units;PixelsPerInch;-ping;$request:document-root/$aImageFileName]]
  ^if(!$lExec.status){
    $result[^_parseIdentifyResponse[$lExec.text]]
  }{
     ^throw[${_throwPrfeix}.exec.error;Ошибка при выполнении скрипта;$lExec.stderr]
   }

@normalize[aImageFileName;aOptions][lExec;lArgs]
## Конверирует изображение для оптимального хранения на сервере.
## aOptions.quality(85) - качество компресии
## aOptions.newFileName -  новое имя файла. Если не задано, то переписываем оригинальный файл.
## aOptions.keepProfiles(false) - сохранить цветовые профили
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(-f $aImageFileName)[Файл "$aImageFileName" не найден на сервере.]

  $lArgs[^table::create{arg}]
  ^lArgs.append{-quality}
  ^lArgs.append{^aOptions.quality.int(85)}
  ^lArgs.append{-compress}
  ^lArgs.append{JPEG}

  ^if(!^aOptions.keepProfiles.bool(false)){
    ^lArgs.append{-strip}
  }

  ^lArgs.append{-alpha}
  ^lArgs.append{off}
  ^lArgs.append{$request:document-root/$aImageFileName}

  ^if(def $aOptions.newFileName){
    ^lArgs.append{$request:document-root/$aOptions.newFileName}
  }{
     ^lArgs.append{$request:document-root/$aImageFileName}
   }

  $lExec[^file::exec[$_scriptPath/convert;;$lArgs]]
  ^if(!$lExec.status){
    $result(true)
  }{
     ^throw[${_throwPrfeix}.exec.error;Ошибка при выполнении скрипта;$lExec.stderr]
   }

@makePreview[aImageFileName;aPreviewFileName;aOptions][lExec;lArgs]
## Строит превьюшку для изображения.
## aOptions.width(100) - максимальная ширина.
## aOptions.height(100) - Максимальная высота.
## aOptions.proportional(true) - пропорционально меням размер?
## aOptions.keepProfiles(false) - сохранить цветовые профили
## aOptions.keepColorspace(false) - сохранить цветовое пространство
  ^cleanMethodArgument[]
  ^pfAssert:isTrue(-f $aImageFileName)[Файл "$aImageFileName" не найден на сервере.]
  ^pfAssert:isTrue(def $aPreviewFileName)[Не задано имя для превьюшки.]
  ^pfAssert:isTrue($aImageFileName ne $aPreviewFileName)[Имя файла и превьюшки не могут совпадать.]
  ^pfAssert:isTrue(def $aOptions.width || def $aOptions.height)[Не определены размеры превьюшки]

  $lArgs[^table::create{arg}]

  ^if(!^aOptions.keepProfiles.bool(false)){
    ^lArgs.append{-strip}
  }
  ^if(!^aOptions.keepColorspace.bool(false)){
    ^lArgs.append{-colorspace}
    ^lArgs.append{RGB}
  }
  ^lArgs.append{-format}
  ^lArgs.append{jpeg}
  ^lArgs.append{-resize}
  ^lArgs.append{^aOptions.width.int(100)x^aOptions.height.int(100)^if(!^aOptions.proportional.bool(true)){!}}

  ^lArgs.append{$request:document-root/$aImageFileName}
  ^lArgs.append{$request:document-root/$aPreviewFileName}

  $lExec[^file::exec[$_scriptPath/convert;;$lArgs]]
  ^if(!$lExec.status){
    $result(true)
  }{
     ^throw[${_throwPrfeix}.exec.error;Ошибка при выполнении скрипта;$lExec.stderr]
   }


@applyWatermark[aImageFileName;aWatermarkFileName;aOptions]
## aWatermarkFileName[]
## aOptions.position[center] - позиция watermark'a на картинке.
##                           [top|top-left|top-right;left|right|bottom|bottom-left|bottom-right]
## aOptions.opacity(25)
## aOptions.method[dissolve]

  ^cleanMethodArgument[]
  ^pfAssert:isTrue(-f $aImageFileName)[Файл "$aImageFileName" не найден на сервере.]
  ^pfAssert:isTrue(-f $aWatermarkFileName)[Файл "$aOptions.watermarkFileName" не найден на сервере.]

  $lArgs[^table::create{arg}]
  ^switch[$aOptions.method]{
    ^case[DEFAULT;dissolve]{
      ^lArgs.append{-dissolve}
      ^lArgs.append{^aOptions.opacity.int(25)%}
    }
  }

  ^lArgs.append{-gravity}
  ^switch[$aOptions.position]{
    ^case[DEFAULT;center]{^lArgs.append{Center}}
    ^case[top]{^lArgs.append{North}}
    ^case[top-left]{^lArgs.append{NorthWest}}
    ^case[top-right]{^lArgs.append{NorthEast}}
    ^case[left]{^lArgs.append{West}}
    ^case[right]{^lArgs.append{East}}
    ^case[bottom]{^lArgs.append{South}}
    ^case[bottom-left]{^lArgs.append{SouthWest}}
    ^case[bottom-right]{^lArgs.append{SouthEast}}
  }

  ^lArgs.append{$request:document-root/$aWatermarkFileName}
  ^lArgs.append{$request:document-root/$aImageFileName}
  ^lArgs.append{$request:document-root/$aImageFileName}

  $lExec[^file::exec[$_scriptPath/composite;;$lArgs]]
  ^if(!$lExec.status){
    $result(true)
  }{
     ^throw[${_throwPrfeix}.exec.error;Ошибка при выполнении скрипта;$lExec.stderr]
   }

#----- Private -----

@_parseIdentifyResponse[aResponse]
  $result[^hash::create[]]
  ^if(def $aResponse){
    ^aResponse.match[^^(.+?):\s*(.+?)^$][gm]{
      ^switch[$match.1]{
        ^case[DEFAULT]{
          ^switch[$match.1]{
            ^case[xResolution;yResolution]{$result.[$match.1][^match.2.match[^^\s*(\d+).*^$][]{$match.1}]}
            ^case[colorSpace]{$result.[$match.1][^match.2.match[^^(?:Direct|Pseudo)Class(\S+).*][i]{$match.1}]}
            ^case[DEFAULT]{$result.[$match.1][$match.2]}
          }
        }
        ^case[exif]{
         ^if(!($result.exif is hash)){$result.exif[^hash::create[]]}
         ^match.2.match[^^(.+?)=(.+)^$][]{$result.exif.[$match.1][$match.2]}
       }
     }
    }
    $result.aspectRatio($result.width/$result.height)
    ^if(!$result.quality){$result.quality(100)}
  }

#  ^pfAssert:fail[^result.foreach[k;v]{^if($v is hash){^v.foreach[k1;v1]{${k}: $k1 -> $v1}[^#0a]}{$k -> $v}}[^#0a]]