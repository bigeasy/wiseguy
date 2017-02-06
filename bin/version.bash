#!/bin/bash

set -e

homeport module <<usage
    usage: homeport version

    description:

        Print the current version of Homeport.
usage

echo "1.0.8"
