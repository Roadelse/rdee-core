#!/bin/bash


To Be Continued

infile="$1"

if [[ -z "$infile" ]]; then
    echo "Requires infile argument"
    exit 101
fi

function rmep(){
    # remove environment path, with seperator of :
    # $1: PATH, $2: detailed path
    # echo $1
    # echo $2
    rst=$(echo :${!1} | sed "s|:$2||g")
    if [[ "$rst" =~ ^: ]]; then
        export $1=${rst:1}
    else
        export $1=${rst}
    fi
}


while read -r Line; do
    if [[ $Line =~ ^# ]]; then
        continue
    elif [[ -z "$Line" ]]; then
        continue
    if [[  ]]


