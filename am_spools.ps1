#In order to benchmark the system over time, we schedule the ABAPMETER in the system
#The downside is the ABAPMETER does not write to a single file, but to spool requests
#We have to download every spool request and also copy the table of request numbers and dates
#Then join the date from the spool_list.txt to the ABAPMETER table for that spool request

Param
(
	[Parameter(Mandatory = $true)]
	[String]$sid
)

[System.Collections.ArrayList]$out_table = @("DateTime|AS Instance    |Bsc ABAP|Sort i.t.|Cp int tbl|Read Table|Calc. int.|Calc. real|Acc buffer|Acc DB|E. Acc DB|(R)FC_PING|RFC_PING l|Read SORT|Read HASHE|P. Read HA|P. Read SO|1 Step Del|3 Step Del|Ins. SORT|Ins. HASH|Nat. Join|Par. Join|Nest. Loop|Par. Nest.|")

#load the spool list to get the date and time
#$spools = [IO.File]::ReadAllText(".\spool_list.txt")
$spools = Get-Content ".\spool_list.txt"

$count = 0
$filter = "$($sid)*TXT"

Get-ChildItem -Filter $filter | % {
	
	$i = $_	
	$i.Name -Match "($sid)0*(\d*)\.TXT" > $null
	
	$request_id = $matches[2]
	
	$pattern = " $($request_id)\|"
	
	$spools -Match $pattern | % {
		
		$_ -Match "(\d\d)\.(\d\d)\.(\d\d\d\d)\|(\d\d):(\d\d)"  > $null
		
		$datetime = "$($matches[3])/$($matches[2])/$($matches[1]) $($matches[4]):$($matches[5])"
	}
	
	$content = Get-Content $i.Name
	
	$pattern = "_$($sid)_\d\d"
	$content -Match $pattern | % {
	
		$newrow = "$($datetime)$($_)"
		$out_table.Add($newrow) > $null
	}
	
	$count = $count + 1
	#$count
	
	if (($count % 100) -eq 0) {$count}
	
}
#$out_table -join [Environment]::NewLine
$out_filename = "am_output_$($sid).txt"
Set-Content $out_filename ($out_table -join [Environment]::NewLine)