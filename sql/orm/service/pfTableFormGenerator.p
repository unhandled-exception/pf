@CLASS
pfTableFormGenerator

## Генерирует «заготовку» формы по модели
## Этот класс — пример написания генераторов кода и заточен под библиотеку Бутстрап 2
## и мой подход к работе с шаблонами, поэтому не надо ждать от него универсальности.

## Виджеты:
##   none — без виджета (пропускаем поле)
##   [input] — стандартный виджет, если не указано иное
##   password
##   hidden
##   textarea
## Виджеты-заготовки (для них  форме выводится шаблончик, который надо дописать программисту :)
##   checkbox
##   radio
##   select

@USE
pf/types/pfClass.p

@BASE
pfClass

@create[aOptions]
## aOptions.widgets[object]
  ^cleanMethodArgument[]
  ^BASE:create[]
  $_defaultArgName[aFormData]

  $_widgets[^if(def $aOptions.widgets){$aOptions.widgets}{^pfTableFormGeneratorBootstrap2Widgets::create[]}]

@generate[aModel;aOptions][locals]
## aOptions.argName
  ^pfAssert:isTrue($aModel is pfSQLTable)[Модель "$aModel.CLASS_NAME" должна быть наследником pfSQLTable.]
  $aOptions[^hash::create[$aOptions]]
  $aOptions.argName[^if(def $aOptions.agrName){$aOptions.argName}{$_defaultArgName}]
  $result[^hash::create[]]

  ^aModel.FIELDS.foreach[k;v]{
    ^if(^_hasWidget[$v;$aModel]){
      $result.[^result._count[]][^_makeWidgetLine[$v;$aOptions]]
    }
  }
  $result[@form^[$aOptions.argName^;aOptions^]^[locals^]
  ^^cleanMethodArgument^[^]
  ^^cleanMethodArgument^[$aOptions.argName^]
  ^_widgets.formWidget{
    ^result.foreach[k;v]{$v^#0A^#0A}
    ^_widgets.submitWidget[$aOptions]
  }
  ]
  $result[^result.match[(^^\s*^$)][gmx][^#0A]]
  $result[^result.match[\n{3,}][g][^#0A]]

@_hasWidget[aField;aModel]
  $result($aField.widget ne none)

@_makeWidgetLine[aField;aOptions]
  $result[^switch[$aField.widget]{
        ^case[;input;password]{^_widgets.inputWidget[$aField;$aField.widget;$aOptions]}
        ^case[hidden]{^_widgets.hiddenWidget[$aField;$aOptions]}
        ^case[textarea]{^_widgets.textareaWidget[$aField;$aOptions]}
        ^case[checkbox;radio]{^_widgets.checkboxWidget[$aField;$aField.widget;$aOptions]}
        ^case[select]{^_widgets.selectWidget[$aField;$aOptions]}
      }]



######################################
##
##      Классы для виджетов
##
######################################

@CLASS
pfTableFormGeneratorBootstrap2Widgets

## Bootstrap 2

@BASE
pfClass

@create[aOptions]
  ^BASE:create[]

@formWidget[aBlock]
  $result[<form action="" method="post" class="form-horizontal">
    $aBlock
  </form>]

@inputWidget[aField;aType;aOptions]
  $result[
    <div class="control-group">
      <label for="f-$aField.name" class="control-label">$aField.label</label>
      <div class="controls">
        <input type="^if(def $aType){$aType}{text}" name="$aField.name" id="f-$aField.name" value="^$${aOptions.argName}.$aField.name" class="input-xxlarge" placeholder="" />
      </div>
    </div>]

@textareaWidget[aField;aOptions]
  $result[
    <div class="control-group">
      <label for="f-$aField.name" class="control-label">$aField.label</label>
      <div class="controls">
        <textarea name="$aField.name" id="f-$aField.name" class="input-xxlarge" rows="7" placeholder="" />^$${aOptions.argName}.$aField.name</textarea>
      </div>
    </div>]

@checkboxWidget[aField;aType;aOptions][locals]
  $lVarName[^$${aOptions.argName}.$aField.name]
  $aType[^if(def $aType){$aType}{checkbox}]
  $result[
    <div class="control-group">
      <div class="controls">
        <label class="$aType"><input type="$aType" name="$aField.name" id="f-${aField.name}1" value="1" ^^if($lVarName){checked="true"} /> $aField.label</label>
      </div>
    </div>]

@selectWidget[aField;aOptions]
  $result[
    <div class="control-group">
      <label for="f-$aField.name" class="control-label">$aField.label</label>
      <div class="controls">
        <select name="$aField.name" id="f-$aField.name" class="input-xxlarge" placeholder="">
          <option value=""></option>
^#          <option value="" ^^if(^$${aOptions.argName}.$aField.name eq ""){selected="true"}></option>
        </select>
      </div>
    </div>]

@hiddenWidget[aField;aOptions]
  $result[    <input type="hidden" name="$aField.name" value="^$${aOptions.argName}.$aField.name" />]

@submitWidget[aOptions]
  ^cleanMethodArgument[]
  $result[^^antiFlood.field^[^]
    <div class="control-group">
      <div class="controls">
        <input type="submit" id="f-sub" value="Сохранить" class="btn btn-primary" />
        или <a href="^^linkTo^[/^]" class="action">Ничего не менять</a>
      </div>
    </div>
  ]

###################################################################################################

@CLASS
pfTableFormGeneratorBootstrap3Widgets

## Bootstrap 3

@BASE
pfClass

@create[aOptions]
  ^BASE:create[]

@formWidget[aBlock]
  $result[<form action="" method="post" class="form-horizontal form-default">
    $aBlock
  </form>]

@inputWidget[aField;aType;aOptions]
  $result[
    <div class="form-group">
      <label for="f-$aField.name" class="control-label col-sm-3">$aField.label</label>
      <div class="col-sm-9">
        <input type="^if(def $aType){$aType}{text}" name="$aField.name" id="f-$aField.name" value="^$${aOptions.argName}.$aField.name" class="form-control" placeholder="" />
      </div>
    </div>]

@textareaWidget[aField;aOptions]
  $result[
    <div class="form-group">
      <label for="f-$aField.name" class="control-label col-sm-3">$aField.label</label>
      <div class="col-sm-9">
        <textarea name="$aField.name" id="f-$aField.name" class="form-control" rows="7" placeholder="" />^$${aOptions.argName}.$aField.name</textarea>
      </div>
    </div>]

@checkboxWidget[aField;aType;aOptions][locals]
  $lVarName[^$${aOptions.argName}.$aField.name]
  $aType[^if(def $aType){$aType}{checkbox}]
  $result[
    <div class="form-group">
      <div class="col-sm-offset-3 col-sm-9">
        <div class="$aType"><label><input type="$aType" name="$aField.name" id="f-${aField.name}1" value="1" ^^if($lVarName){checked="true"} /> $aField.label</label></div>
      </div>
    </div>]

@selectWidget[aField;aOptions]
  $result[
    <div class="form-group">
      <label for="f-$aField.name" class="control-label col-sm-3">$aField.label</label>
      <div class="col-sm-9">
        <select name="$aField.name" id="f-$aField.name" class="form-control" placeholder="">
          <option value=""></option>
^#          <option value="" ^^if(^$${aOptions.argName}.$aField.name eq ""){selected="true"}></option>
        </select>
      </div>
    </div>]

@hiddenWidget[aField;aOptions]
  $result[    <input type="hidden" name="$aField.name" value="^$${aOptions.argName}.$aField.name" />]

@submitWidget[aOptions]
  ^cleanMethodArgument[]
  $result[^^antiFlood.field^[^]
    <div class="form-group">
      <div class="col-sm-offset-3 col-sm-9">
        <input type="submit" id="f-sub" value="Сохранить" class="btn btn-primary" />
        или <a href="^^linkTo^[/^]" class="action">Ничего не менять</a>
      </div>
    </div>
  ]
