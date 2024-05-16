#!/bin/bash

#@ Prepare
#@ .functions
function show_help() {
    echo 'remove-invalid-symlinks.sh

[Usage]
    Just run it, will remove invalid symlinks in the current directory
'
}

#@ .arguments
while getopts "h" arg; do
    case $arg in
    h)
        show_help
        exit 0
        ;;
    ?)
        show_help
        exit 101
        ;;
    esac
done

#@ Main
readarray -t symfiles < <(find . -maxdepth 1 -type l)
for sf in "${symfiles[@]}"; do
    abspath=$(readlink -f $sf)
    if [[ ! -e "$abspath" ]]; then
        echo "Removing invalid symlink $sf -> $abspath"
        rm -f $sf
    fi
done
