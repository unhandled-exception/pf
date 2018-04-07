# PF Library

#@module   SQLite Class
#@author   Oleg Volchkov <oleg@volchkov.net>
#@web      http://oleg.volchkov.net

## Класс для работы с SQLite-сервером.

@CLASS
pfSQLite

@USE
pf/sql/pfSQL.p

@BASE
pfSQL

#----- Constructor -----

@create[aConnectString;aOptions]
  ^cleanMethodArgument[]
  ^BASE:create[$aConnectString;$aOptions]
  $_serverType[sqlite]

#--- Public ---

@startTransaction[aOptions]
  ^void{begin transaction}

@commit[aOptions]
  ^void{commit transaction}

@rollback[]
  ^void{rollback transaction}
    
#--- DATE functions ---

@today[]
  $result[date('now')]

@now[]
  $result[datetime('now')]

@year[sSource]
  $result[strftime('%Y',$sSource)]

@month[sSource]
  $result[strftime('%m',$sSource)]

@day[sSource]
  $result[strftime('%d',$sSource)]

@ymd[sSource]
  $result[strftime('%Y-%m-%d',$sSource)]

@time[sSource]
  $result[time($sSource)]

@dateDiff[t;sDateFrom;sDateTo]
  $result[^if(def $sDateTo){julianday($sDateTo)}{^now[]} - julianday($sDateFrom)]

@dateSub[sDate;iDays]
  $result[date(^if(def $sDate){$sDate}{^today[]}, '+$iDays day')]

@dateAdd[sDate;iDays]
  $result[date(^if(def $sDate){$sDate}{^today[]}, '-$iDays day')]


#---- functions available not for all sql servers ----

@dateFormat[sSource;sFormatString]
  $result[strftime('^if(def $sFormatString){$sFormatString}{%Y-%m-%d}',$sSource)]

@lastInsertId[sTable]
  $result(^int{select last_insert_rowid()}[$.limit(1) $.default{0}])

#--- STRING functions ---

@substring[sSource;iPos;iLength]
  $result[substring($sSource,^if(def $iPos){$iPos}{1},^if(def $iLength){$iLength}{1})]

@upper[sField]
  $result[upper($sField)]

@lower[sField]
  $result[lower($sField)]

#--- MISC functions ---

@password[sPassword]
   $result['^math:md5[$sPassword]']

@leftJoin[sType;sTable;sJoinConditions;last]
  ^switch[^sType.lower[]]{
    ^case[from]{
      $result[LEFT JOIN $sTable ON ($sJoinConditions)]
    }
    ^case[where]{
      $result[1 = 1 ^if(!def $last){ AND}]
    }
    ^case[DEFAULT]{
      ^throw[pfSQLite;Unknown join type '$sType']
    }
  }
  
  