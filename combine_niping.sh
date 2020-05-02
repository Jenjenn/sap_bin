#!/bin/bash
#
# Author: I844387
#
# usage: combine_niping <niping_file_1> <niping_file_2> ...
#
# Example 1:
# combine_niping file1 file2 file3 > output
#
# Example 2:
# combine_niping * > output
#
# Will combine all niping files in your current directory into a pivot-table friendly output file
# Then copy and paste the results into excel for easy charting
#

if ! [ -x "$(command -v dos2unix)" ]; then
  echo 'Error: this script requires dos2unix and gawk to be installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v gawk)" ]; then
  echo 'Error: this script requires dos2unix and gawk to be installed.' >&2
  exit 1
fi


echo "connection|timestamp|rtt(ms)|"

# process each file
while (( "$#" )); do

# Windows-style line endings don't play nicely with awk
dos2unix "$1"

gawk --posix '
BEGIN {
flag=0;
timestamp="";
split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec",months)
for (i in months) {
	month_nums[months[i]]=i
	}
}

$4 ~ /[0-9]{2}:[0-9]{2}:[0-9]{2}/ {
	timestamp=$5"/"month_nums[$2]"/"$3" "$4
}

$1 ~ /[0-9]{1,10}:/ && $2 ~ /[0-9]{1,5}\.[0-9]{3}/ {
	if (timestamp !="")
	{
		split(FILENAME, fn, /\./);
		print fn[1]"|"timestamp"|"$2"|";
	}
}

' "$1"


sync

shift

done;

