#!/bin/bash

set -e

homeport module <<usage
    usage: homeport version

    description:

        Print the current version of Homeport.
usage

pushd "$wiseguy_path/../.." > /dev/null
project_path=$(pwd)
popd > /dev/null

rm -f "$project_path"/node_modules/.bin/wg
ln -s "$wiseguy_path/wiseguy.bash" "$project_path"/node_modules/.bin/wg
