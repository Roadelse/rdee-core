#!/bin/bash

#@ Union several softwares, i.e., link files of their bin/, include/ and lib/ into one directory

if [[ $# -lt 2 ]]; then
    echo -e '\033[31m Error \033[0m | requires at least one outdir and one indir'
    exit 101
fi

outdir=`realpath $1`
indirs=${@:2}
indirs_abs=()

for d in ${indirs[@]}; do
    if [[ ! -e $d ]]; then
        echo -e '\033[31m Error \033[0m | indir does not exist: '${d}
        exit 101
    fi
done

mkdir -p $outdir/bin
mkdir -p $outdir/include
mkdir -p $outdir/lib

# cd $outdir
for d in ${indirs[@]}; do
    echo "... linking $d"
    [[ -e $d/bin ]] && ln -sf `realpath $d`/bin/* $outdir/bin
    [[ -e $d/lib ]]  && ln -sf `realpath $d`/lib/* $outdir/lib
    [[ -e $d/include ]] && ln -sf `realpath $d`/include/* $outdir/include
done

