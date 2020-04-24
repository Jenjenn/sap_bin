#!/bin/bash
#
# Author: Jennifer Gray
#
# Trace files in a HANA system-info dump are saved per host
# To make analyzing easier this script copies all *.trc and *.log files into
# a new trace directory. Must be in the HDBXX directory of the dump.
#
# usage: gather_trace


mkdir "trace"

find . -not -path './trace/*' -type f \( -iname '*.trc' -o -iname '*.log' \) -print0 | while IFS= read -r -d $'\0' line; do
	
	hostname=`echo "$line" | cut -d '/' -f 2`
	database=""
	
	dirdepth=`echo "$line" | grep -o "/" | wc -l`

	# file belongs to a tennant DB
	if [[ "$dirdepth" == "4" ]]
	then
		database=`echo "$line" | cut -d '/' -f 4`
		database="${database}."
	fi

	
	newfilename=""
	
	if [[ "$line" == *"backup.log"* ]]
	then
		newfilename="${database}backup_${hostname}.log"
	elif [[ "$line" == *"backint.log"* ]]
	then
		newfilename="${database}backint_${hostname}.log"
	else
		newfilename=`echo "$line" | sed -e "s/^\.\/[^\/]*\/trace\///" | sed -e "s/\//\./"`
	fi

	# echo "$newfilename"

	cp --preserve=timestamps "$line" "./trace/$newfilename"
done



