@CLASS
pfModelBase

@USE
pf/types/pfClass.p

@BASE
pfClass

@create[aOptions]
  ^BASE:create[]

  ^if(!($aOptions is hash)){$aOptions[^hash::create[]]}
  
# Если нам передали sql-класс, то пришем его в переменную $_sql
	^if(def $aOptions.sql && $aOptions.sql is pfSQL){
		$_sql[$aOptions.sql]
	}{
		 ^throw[pf.model.base;SQL class not defined!]
	 }

@GET_CSQL[]
  $result[$_sql]
