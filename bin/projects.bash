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

found=0
for package in $(find "$project_path" -maxdepth 2 -mindepth 2 -name package.json); do
    found=1
    dirname "$package"
done

if [ $found -eq 0 ]; then
    echo "$project_path"
fi
