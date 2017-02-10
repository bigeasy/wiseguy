#!/bin/bash

set -e

homeport module <<usage
    usage: wg make <target>

    description:

        Create something form the Wiseguy Makefile.
usage

pushd "$wiseguy_path/../.." > /dev/null
project_path=$(pwd)
popd > /dev/null

name=$(jq -r '.name' < package.json)

WISEGUY_SUBPROJECT_NAME=
if [[ "$name" = *.* ]]; then
	WISEGUY_SUBPROJECT_NAME=${name#*.}
elif [ -e "../package.json" ]; then
	parent=$(jq -r '.name' < "../package.json")
	if [ "$parent" = "$name" ]; then
        WISEGUY_SUBPROJECT_NAME=root
    fi
fi

export WISEGUY_SUBPROJECT_NAME

make -f "$wiseguy_path/Makefile" "$@"
