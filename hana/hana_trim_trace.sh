#!/bin/bash
#
# Author: Jennifer Gray
#
# This script filters Hana traces based on timestamps. Must be in the HDB<#> directory
# of a system-info dump. Not guaranteed to work on backint.log files
#
# usage: trim_trace [-from <YYYY-MM-DD hh:mm:ss>] [-to <YYYY-MM-DD hh:mm:ss>] <filename>
#

processing_args="true"

ts_from="0000-00-00 00:00:00"
  ts_to="9999-99-99 99:99:99"


#process the provided arguements
while [ "$processing_args" = "true" ]
do

	if [ "$1" == "-from" ]
	then
		shift
		
		ts_from="$1"
		shift
		
	elif [ "$1" == "-to" ]
	then
		shift

		ts_to="$1"
		shift
	else
		processing_args="false"
	fi

done

#validate the timestamps
if [ ! -z "$ts_from" ]
then

	if [ -z "`echo "$ts_from" | egrep -e "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"`" ]; then
		echo "from timestamp format is invalid"
		echo "usage: trim_trace [-from <YYYY-MM-DD hh:mm:ss>] [-to <YYYY-MM-DD hh:mm:ss>] <filename>"
		exit 2
	fi
fi

if [ ! -z "$ts_to" ]
then

	if [ -z "`echo "$ts_to" | egrep -e "[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"`" ]; then
		echo "to timestamp format is invalid"
		echo "usage: trim_trace [-from <YYYY-MM-DD hh:mm:ss>] [-to <YYYY-MM-DD hh:mm:ss>] <filename>"
		exit 2
	fi
fi


# create the target directory
dir_name="trimmed_${ts_from}__${ts_to}"

dir_name=`echo "$dir_name" | sed "s/[: ]/_/g"`

mkdir "./$dir_name"


# process each file
while (( "$#" )); do

new_file_path="./${dir_name}/$1"
	
	# determine what type of trace it is
	# table loads & unloads
	if [[ "$1" == *"loads"* ]]
	then

awk -v ts_from="$ts_from" -v ts_to="$ts_to" -F ";" '{
timestamp=substr($3,1,19);
sub(/T/, " ", timestamp);
if ((timestamp >= ts_from) && (timestamp <= ts_to))
print;
fi
}' "$1" > "$new_file_path"
	
	# backup.log file
	elif [[ "$1" == *"backup"* ]]
	then

awk -v ts_from="$ts_from" -v ts_to="$ts_to" '{
timestamp=substr($1,1,19);
sub(/T/, " ", timestamp);
if ((timestamp >= ts_from) && (timestamp <= ts_to))
print;
fi
}' "$1" > "$new_file_path"
		
	# normal trace file
	else
	
awk -v ts_from="$ts_from" -v ts_to="$ts_to" 'BEGIN {flag=0}
$2 ~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/ && $3 ~ /[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{6}/ {
timestamp=$2" "$3;
timestamp=substr(timestamp,1,19);
if ((timestamp >= ts_from) && (timestamp <= ts_to))
flag=1;
else
flag=0;
}
flag' "$1" > "$new_file_path"

	fi

sync

	# remove any empty files (i.e. no matches in the specified time range)
	size=`du "$new_file_path" | cut -f 1`
	if [[ "$size" == "0" ]]
	then
		rm "$new_file_path"
	
	# fix the last modified date
	else
		realdate="$(/bin/tac "$new_file_path" | /bin/egrep -m 1 -o -e "[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}:[0-9]{2}" | head -n 1)"	

		touch -d "$realdate" "$new_file_path"
	fi
	
	shift
done;

