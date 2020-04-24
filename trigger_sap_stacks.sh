#!/bin/bash


cur_user=$(whoami)

if [[ ! "$cur_user" =~ "adm" ]]; then
  echo "must be run as a <sid>adm user"
  exit 1
fi

instance_no=
interval=1
count=10

usage() { echo "$0 usage:" && grep "[[:space:]].)\ #" $0 | sed 's/#//' | sed -r 's/([a-z])\)/-\1/'; exit $1; }
[ $# -eq 0 ] && usage 0

while getopts ":hn:i:c:" arg; do
  case $arg in
    n) # SAP instance number; required
      instance_no=${OPTARG}
      ;;
    i) # interval between call stacks; optional, default 1 second
      interval=${OPTARG}
      ;;
    c) # number of call stacks to collect; optiona, default 10
      count=${OPTARG}
      ;;
    h | *)
      usage 0
  esac
done

if [ -z $instance_no ]; then
  echo "SAP instance number is required"
  usage 1
fi

#make sure sapcontrol exists
if [ ! -f "${DIR_LIBRARY}/sapcontrol" ]; then
  echo "couldn't locate executable sapcontrol; is DIR_LIBRARY set to the 'run' directory?"
  exit 1
fi


wppids=$(${DIR_LIBRARY}/sapcontrol -nr "${instance_no}" -function ABAPGetWPTable | grep -Po "(DIA|UPD|UP2|BTC|SPO), \d+" | grep -Po "\d+$")

#echo "${wppids}"

for wppid in $wppids; do
#old, pre 74x method, doesn't work in kernels > 74x
#the WPs cant handle multiple signals at the same time, so a small delay between raising & lowering the trace level
(for ((i=0; i < ${count}; i++)); do kill -USR2 ${wppid}; sleep 0.02; kill -USR1 ${wppid}; sleep ${interval}; done)  &

#using sapstack, too slow for proper profiling
(for ((i=0; i < ${count}; i++)); do sapstack ${wppid}; date; sleep ${interval} done) >> wpstack_${wppid} &

done

wait

echo "done"
exit 0