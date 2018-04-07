# PF Library

#@module   MySQL Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

## Класс для работы с MySQL-сервером.

@CLASS
pfMySQL

@USE
pf/sql/pfSQL.p

@BASE
pfSQL

#----- Constructor -----

@create[aConnectString;aOptions]
  ^cleanMethodArgument[]
  ^BASE:create[$aConnectString;$aOptions]
  $_serverType[mysql]

@startTransaction[aOptions]
## Открывает транзакцию.
## aOptions.isNatural
  $result[]
  ^cleanMethodArgument[]
  ^void{start transaction}

@commit[aOptions]
## Комитит транзакцию.
  $result[]
  ^void{commit}

@rollback[aOptions]
## Откатывает транзакцию.
  $result[]
  ^void{rollback}

#--- DATE functions ---

@today[]
  $result[CURDATE()]

@now[]
  $result[NOW()]

@year[sSource]
  $result[YEAR($sSource)]

@month[sSource]
  $result[MONTH($sSource)]

@day[sSource]
  $result[DATE_FORMAT($sSource,'%d')]

@ymd[sSource]
  $result[DATE_FORMAT($sSource,'%Y-%m-%d')]

@time[sSource]
  $result[DATE_FORMAT($sSource,'%H:%i:%S')]

@dateDiff[t;sDateFrom;sDateTo]
  $result[^if(def $sDateTo){TO_DAYS($sDateTo)}{^now[]} - TO_DAYS($sDateFrom)]

@dateSub[sDate;iDays]
  $result[DATE_SUB(^if(def $sDate){$sDate}{^today[]}, INTERVAL $iDays DAY)]

@dateAdd[sDate;iDays]
  $result[DATE_ADD(^if(def $sDate){$sDate}{^today[]}, INTERVAL $iDays DAY)]


#---- functions available not for all sql servers ----

@dateFormat[sSource;sFormatString]
  $result[DATE_FORMAT($sSource, '^if(def $sFormatString){$sFormatString}{%Y-%m-%d}')]

@lastInsertId[sTable]
  $result[^string{SELECT last_insert_id()}[$.limit(1) $.default{0}][$.isForce(true)]]

@setLastInsertId[sTable;sField]
  $result[^lastInsertId[$sTable]]
  ^void{UPDATE $sTable SET ^if(def $sField){$sField}{sort_order} = $result WHERE ${sTable}_id = $result}

#--- STRING functions ---

@substring[sSource;iPos;iLength]
  $result[SUBSTRING($sSource,^if(def $iPos){$iPos}{1},^if(def $iLength){$iLength}{1})]

@upper[sField]
  $result[UPPER($sField)]

@lower[sField]
  $result[LOWER($sField)]

@concat[sSource]
  $result[CONCAT($sSource)]

#--- MISC functions ---

@password[sPassword]
  $result[PASSWORD($sPassword)]

@leftJoin[sType;sTable;sJoinConditions;last]
  ^switch[^sType.lower[]]{
    ^case[from]{
      $result[LEFT JOIN $sTable ON ($sJoinConditions)]
    }
    ^case[where]{
      $result[1 = 1 ^if(!def $last){ AND}]
    }
    ^case[DEFAULT]{
      ^throw[pfMySQL;Unknown join type '$sType']
    }
  }

