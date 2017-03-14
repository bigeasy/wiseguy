#!/bin/bash

set -e

homeport module <<usage
    usage: wg months

    description:

        Split diary entries into individual months.
usage

output=$1
started=$(mktemp)

IFS=''
while read line; do
    if [[ "$line" =~ ^\#\#[[:space:]]([^~]+)([[:space:]]+~+(.*))? ]]; then
        date=${BASH_REMATCH[1]}
        tags=${BASH_REMATCH[3]}
        if [ "$wiseguy_host_os" = "Linux" ]; then
            date=$(date --date="$date" +%s)
        else
            date=$(date -j -f "%a %b %d %T %Z %Y" "$date" "+%s")
        fi
        file=$(date -j -f '%s' "$date" +%Y-%m).diary.md
        if [ ! -e $output/$file ] || [ $started -ot $output/$file ]; then
            mkdir -p $output
            rm -f $output/$file
        fi
        echo "$line" >> $output/$file
    else
        echo "$line" >> $output/$file
    fi
done

rm $started
