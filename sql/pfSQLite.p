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
  $_serverType[SQLite]

#----- Public -----
@setServerEnvironment[]
  ^if($isNaturalTransaction){
    ^void:sql{SET AUTOCOMMIT=0}
  }

@startTransaction[aOptions]
## Открывает транзакцию. 
  ^void{begin transaction}

@commit[aOptions]
## Комитит транзакцию. 
  ^void{commit transaction}

@rollback[]
## Откатывает текущую транзакцию.
  ^if($isTransaction && $isNaturalTransactions){
  	^void{rollback transaction}
  }{
  	 ^BASE:rollback[]
   }
    
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

@date_diff[t;sDateFrom;sDateTo]
  $result[^if(def $sDateTo){julianday($sDateTo)}{^now[]} - julianday($sDateFrom)]

@date_sub[sDate;iDays]
  $result[date(^if(def $sDate){$sDate}{^today[]}, '+$iDays day')]

@date_add[sDate;iDays]
  $result[date(^if(def $sDate){$sDate}{^today[]}, '-$iDays day')]


#---- functions available not for all sql servers ----

@date_format[sSource;sFormatString]
  $result[strftime('^if(def $sFormatString){$sFormatString}{%Y-%m-%d}',$sSource)]

@last_insert_id[sTable]
	$result(^int{select last_insert_rowid()}[$.limit(1) $.default{0}])

# @set_last_insert_id[sTable;sField]
# 	$result(^last_insert_id[$sTable])
# 	^void{UPDATE $sTable SET ^if(def $sField){$sField}{sort_order} = $result WHERE ${sTable}_id = $result}

#--- STRING functions ---

@substring[sSource;iPos;iLength]
  $result[substring($sSource,^if(def $iPos){$iPos}{1},^if(def $iLength){$iLength}{1})]

@upper[sField]
  $result[upper($sField)]

@lower[sField]
  $result[lower($sField)]

# @concat[sSource]
#   $result[CONCAT($sSource)]

#--- MISC functions ---

@password[sPassword]
   $result['^math:md5[$sPassword]']

@left_join[sType;sTable;sJoinConditions;last]
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
  
  