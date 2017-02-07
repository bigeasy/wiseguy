#!/bin/bash

set -e

homeport module <<usage
    usage: wiseguy projects

    description:

        List modules in this project.
usage

pushd "$wiseguy_path/../.." > /dev/null
project_path=$(pwd)
popd > /dev/null

name=$(jq -r < package.json '.name')

if [[ *.* = $name ]]; then
    echo ".."
else
    echo "."
fi
