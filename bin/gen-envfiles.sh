#!/bin/bash


function genenv(){

	if [[ -n `echo $1 | grep ':'` ]]; then
		target_dir=$(realpath `echo $1 | cut -d: -f1`)
		ename=`echo $1 | cut -d: -f2`
	else
		target_dir=`realpath $1`	  # target directory
		ename=
	fi

	if [[ ! -e ${target_dir}/lib && ! -e ${target_dir}/include ]]; then
		echo -e '\033[31mUnexpected target directory without lib/ and include/\033[0m'
		exit 011
	fi

	bname=`basename $target_dir`

	mkdir -p $target_dir/modulefiles

	modfile=$target_dir/modulefiles/$bname
	echo -e '%Module 1.0\n\n' > $modfile
	
	if [[ -n $ename ]]; then
		echo -e "setenv $ename $target_dir\n" >> $modfile
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
		echo -e "export $ename=$target_dir\n" >> $stvfile
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


function show_help(){
	echo -e '
gen-envfiles.sh [-h] <target-directories>

[~] Arguments
	● -h
		show help message
	● <target-directories>
		Generate env files for each directory
		<dir:ename> would add an environment variable pointing to the dir at the env-file
'
}


while getopts "e" arg; do
    case $arg in
    h)
        show_help
		exit 0
        ;;
    esac
done
shift $((OPTIND-1))


for d in $*; do
	genenv $d
done