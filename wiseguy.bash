#!/bin/bash

set -e

case "$(uname)" in
    Darwin* )
        wiseguy_host_os=OSX
        ;;
    linux* )
        wiseguy_host_os=Linux
        ;;
    * )
        abend "Homeport will only run on OS X or Linux."
        ;;
esac

if [ "$1" == "module" ]; then
    echo $0
    echo "Please do not execute these programs directly. Use `wiseguy`."
    exit 1
fi

function wiseguy_readlink() {
    file=$1
    if [ "$wiseguy_host_os" = "OSX" ]; then
        if [ -L "$file" ]; then
            readlink $1
        else
            echo "$file"
        fi
    else
        readlink -f $1
    fi
}

wiseguy_file=$0

while [ -L "$wiseguy_file" ]; do
    expanded=$(wiseguy_readlink "$wiseguy_file")
    pushd "${wiseguy_file%/*}" > /dev/null
    pushd "${expanded%/*}" > /dev/null
    wiseguy_path=$(pwd)
    popd > /dev/null
    popd > /dev/null
    wiseguy_file="$wiseguy_path/${wiseguy_file##*/}"
done

pushd "${wiseguy_file%/*}" > /dev/null
wiseguy_path=$(pwd)
popd > /dev/null

source "$wiseguy_path/lib/common.bash"
source "$wiseguy_path/lib/externalized.bash"
source "$wiseguy_path/lib/getopt.bash"

if [ -e ~/.wiseguy.conf ]; then
    source ~/.wiseguy.conf
fi

wiseguy_exec "$@"
