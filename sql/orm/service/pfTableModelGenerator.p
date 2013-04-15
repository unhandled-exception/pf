@CLASS
pfTableModelGenerator

@USE
pf/types/pfClass.p
pf/types/pfString.p
pf/tests/pfAssert.p

@BASE
pfClass

@create[aTableName;aOptions]
## aOptions.sql
## aOptions.schema
  ^cleanMethodArgument[]
  ^pfAssert:isTrue($aOptions.sql is pfMySQL)[Не задан объект дл доступа к СУБД.]
  ^BASE:create[]

  $_sql[$aOptions.sql]
  ^defReadProperty[CSQL;_sql]

  $_schema[$aOptions.schema]
  $_tableName[$aTableName]
  ^if(!def $_tableName || !^CSQL.table{show tables ^if(def $_schema){from `$_schema`} like "$_tableName"}){
    ^throw[table.not.found]
  }

  $_fields[^_getFields[]]

@_getFields[][locals]
  $result[^hash::create[]]
  $lDDL[^CSQL.table{describe ^if(def $_schema){`$_schema`.}`$_tableName`}]
  $lHasPrimary(^lDDL.select($lDDL.Key eq "PRI") == 1)
  $self._primary[]

  ^lDDL.menu{
    $lName[^_makeName[$lDDL.Field]]
    $lData[^hash::create[]]

    ^if($lDDL.Field ne $lName){$lData.dbField[$lDDL.Field]}

    ^if($lDDL.Key eq "PRI" && $lHasPrimary){
      $lData.primary(true)
      $self._primary[$lName]
      ^if(!^lDDL.Extra.match[auto_increment][in]){
        $lData.sequence(false)
      }
    }

    $lType[^_parseType[$lDDL.Type]]
    ^switch[^lType.type.lower[]]{
      ^case[int;integer;smallint;mediumint]{$lData.processor[^if($lType.unsigned){uint}{int}]}
      ^case[tinyint]{
        $lData.processor[^if($lType.unsigned){uint}{int}]
        ^if(^lType.format.int(0) == 1
            || ^lDDL.Field.pos[is_] == 0){
          $lData.processor[bool]
          $lData.default(1)
        }
      }
      ^case[float;double;decimal;numeric]{
        $lData.processor[double]
        ^if(def $lType.format){
          $lData.format[^lType.format.match[^^(\d+)\,(\d+)^$][]{%${match.1}.${match.2}f}]
        }
      }
      ^case[date]{$lData.processor[date]}
      ^case[datetime]{$lData.processor[datetime]}
      ^case[time]{$lData.processor[time]}
    }

    ^if($lName eq "createdAt"){
      $lData.processor[auto_now]
      $lData.skipOnUpdate(true)
    }
    ^if($lName eq "updatedAt"){
      $lData.processor[auto_now]
    }

    $result.[$lName][$lData]
  }

@_parseType[aTypeString]
  $aTypeString[^aTypeString.lower[]]
  $result[^hash::create[]]
  ^aTypeString.match[^^(\w+)(\(.+?\))?(.+)?][]{
    $result.type[$match.1]
    $result.format[^match.2.trim[both;()]]
    $result.options[$match.3]
    ^if(^result.options.match[unsigned][in]){
      $result.unsigned(true)
    }
  }

@_makeName[aName]
  $aName[^aName.lower[]]
  $result[^aName.match[_(\w)][g]{^match.1.upper[]}]
  $result[^result.match[Id^$][][ID]]

@generate[aOptions]
  ^cleanMethodArgument[]
  $result[
  ^@CLASS
  ${_tableName}
  # Table ^if(def $_schema){`$_schema`.}`$_tableName`

  ^@USE
  pf/sql/orm/pfSQLTable.p

  ^@BASE
  pfSQLTable

  ^@create^[aTableName^;aOptions^]
    ^^BASE:create^[^$aTableName^;^^hash::create^[^$aOptions^]
  #    ^$.tableAlias^[^]
  #    ^$.allAsTable(true)
    ^]

  ^_classBody[]
  ]
  $result[^result.match[^^[ \t]{2}][gmx][]]
  $result[^result.match[(^^\s*^$){3,}][gmx][^#0A]]

@_classBody[][locals]
$result[
    ^^addFields^[
      ^_fields.foreach[k;v]{^$.$k^[^v.foreach[n;m]{^$.$n^if($m is bool){(^if($m){true}{false})}{^if($m is double){^($m^)}{^[$m^]}}}[ ]^]}[^#0A      ]
    ^]

  ^if(def $_primary){
    ^$_defaultOrderBy^[^$.${_primary}[asc]]
  }

  ^if(^_fields.contains[isActive] && def $_primary){
  $lArgument[a^pfString:changeCase[$_primary;first-upper]]
  ^@delete^[$lArgument^]
    ^$result^[^^modify^[^$$lArgument^;^$.isActive(false)^]^]

  ^@restore^[$lArgument^]
    ^$result^[^^modify^[^$$lArgument^;^$.isActive(true)^]^]
  }
]

