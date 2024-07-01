#!/bin/bash


function genenv(){

    if [[ -n `echo $1 | grep ':'` ]]; then
        target_dir=$(realpath `echo $1 | cut -d: -f1`)
        ename=`echo $1 | cut -d: -f2`
    else
        target_dir=`realpath $1`      # target directory
        ename=
    fi

    if [[ ! -e ${target_dir}/lib && ! -e ${target_dir}/include ]]; then
        echo -e '\033[31mUnexpected target directory without lib/ and include/\033[0m'
        exit 011
    fi

    bname=`basename $target_dir`

    mkdir -p $target_dir/modulefiles

    modfile=$target_dir/modulefiles/$bname
    echo -e '#%Module 1.0\n\n' > $modfile
    
    if [[ -n $ename ]]; then
        if [[ -n `echo $ename | grep '+'` ]]; then
            enames=(`python -c "print('${ename}'.replace('+', ' '))"`)
        else
            enames=($ename)
        fi
        for en in "${enames[@]}"; do
            echo -e "setenv $en $target_dir\n" >> $modfile
        done
    fi

    if [[ -e $target_dir/bin ]]; then

        cat >> $modfile << EOF
prepend-path PATH $target_dir/bin

EOF
    fi

    if [[ -e $target_dir/lib ]]; then

        cat >> $modfile << EOF
prepend-path LD_LIBRARY_PATH $target_dir/lib
prepend-path LIBRARY_PATH $target_dir/lib

EOF
    fi


    mkdir -p $target_dir/setenvfiles
    stvfile=$target_dir/setenvfiles/setenv.$bname.sh


    echo -e '#!/bin/bash\n\n' > $stvfile

    if [[ -n $ename ]]; then
        # echo ename=$ename
        if [[ -n `echo $ename | grep '+'` ]]; then
            enames=(`python -c "print('${ename}'.replace('+', ' '))"`)
        else
            enames=($ename)
        fi
        for en in "${enames[@]}"; do
            echo -e "export $en=$target_dir\n" >> $stvfile
        done
    fi

    if [[ -e $target_dir/bin ]]; then

        cat >> $stvfile << EOF
export PATH=$target_dir/bin:\$PATH

EOF
    fi

    if [[ -e $target_dir/lib ]]; then

        cat >> $stvfile << EOF
export LD_LIBRARY_PATH=$target_dir/lib:\$LD_LIBRARY_PATH
export LIBRARY_PATH=$target_dir/lib:\$LIBRARY_PATH

EOF
    fi

}


function clearenv(){
    if [[ ! -d "$1" || ! -d "$1"/setenvfiles ]]; then
        echo -e "\033[33m Warning \033[0m | $1 is not valid, skip"
        return
    fi
    echo 1233
    rm -rf $1/setenvfiles
    rm -rf $1/modulefiles

}


function show_help(){
    echo -e '
gen-envfiles.sh [-h, -c] <target-directories>

[~] Arguments
    ● -h
    show help message
    ● -c
        remove existed modulefiles/ and setenvfiles/ rather then creation
    ● <target-directories>
        Generate env files for each directory
        <dir:ename> would add an environment variable pointing to the dir at the env-file
'
}


clear=0
while getopts "hc" arg; do
    case $arg in
    h)
        show_help
        exit 0
        ;;
    c)
        clear=1
        ;;
    esac
done
shift $((OPTIND-1))


for d in $*; do
    echo "handling $d"
    if [[ $clear == 0 ]]; then
        genenv $d
    else
        clearenv $d
    fi
done