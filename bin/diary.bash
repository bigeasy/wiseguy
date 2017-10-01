#!/bin/bash

set -e

homeport module <<usage
    usage: wg make <target>

    description:

        Create something form the Wiseguy Makefile.
usage

write_line () {
    local date=$1 tags=$2 body=$3
    jq -c -n --arg date "$date" --arg tags "$tags" --arg body "$body" '{
        date: ($date + "000"),
        tags: $tags | split(",") | map(ltrimstr(" ") | rtrimstr(" ")),
        body: $body
    }'
}

emit=0
body=
IFS=''
while read line; do
    if [[ "$line" =~ ^\#\#[[:space:]]([^~]+)([[:space:]]+~+(.*))? ]]; then
        if [ $emit -eq 1 ]; then
            write_line "$date" "$tags" "$body"
        fi
        emit=1
        body=
        date=${BASH_REMATCH[1]}
        tags=${BASH_REMATCH[3]}
        if [ "$wiseguy_host_os" = "Linux" ]; then
            date=$(date --date="$date" +%s)
        else
            date=$(gdate --date="$date" +%s)
        fi
    else
        body+="$line"$'\n'
    fi
done

write_line "$date" "$tags" "$body"
