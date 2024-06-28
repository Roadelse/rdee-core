#!/bin/bash


function genenv(){

	target_dir=`realpath $1`  # target directory
	if [[ ! -e ${target_dir}/lib && ! -e ${target_dir}/include ]]; then
		echo -e '\033[31mUnexpected target directory without lib/ and include/\033[0m'
		exit 011
	fi

	bname=`basename $target_dir`
	
	mkdir -p $target_dir/modulefiles

	modfile=$target_dir/modulefiles/$bname
	cat > $modfile << EOF
#%Module 1.0

EOF

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

	cat > $stvfile << EOF
#!/bin/bash

EOF

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


for d in $*; do
	genenv $d
done