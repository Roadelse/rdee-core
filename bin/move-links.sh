#!/bin/bash

#@ Prepare
#@ .arguments
show_help=0
while getopts "h" arg; do
    case $arg in
    h)
        show_help=1
        ;;
    esac
done

#@ .help
if [[ $show_help == 1 ]]; then
    echo -e 'move-links.sh is used to generate codes for linking all symlinks in PWD

[Usage]
    .../move-links.sh
'
    exit 0
fi

#@ Main
readarray -t symfiles < <(find . -maxdepth 1 -type l)
for sf in "${symfiles[@]}"; do
    abspath=$(readlink -f $sf)
    if [[ -n "$abspath" ]]; then
        echo "ln -sf $abspath ."
    fi
done
