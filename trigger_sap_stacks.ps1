$duration=60
$outdir=pwd
$job={
	param($d,$p,$dur)
	function of{$args|out-file  $d'\WP_'$p'_stack' -append}
	$start=get-date
	while(((get-date)-$start).totalseconds -lt $dur){
		of (sapstack $p)
		of (get-date -format "yyyy/MM/dd HH:mm:ss.fff")
		}
	}
$pids=((sapcontrol -prot PIPE -nr 00 -function ABAPGetWPTable) -match 'DIA') | % {($_ -split ', ')[2]}
foreach($p in $pids){sajb -scriptblock $job -argumentlist $outdir, $p, $duration}
while(get-job | where state -eq running){sleep 10;}