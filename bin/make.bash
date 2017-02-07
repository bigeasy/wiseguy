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

#make -C "$project_path" -f "$wiseguy_path/Makefile" "$@"
make -f "$wiseguy_path/Makefile" "$@"
