#!/bin/bash

#@ Introduction |
#@ This script aims to deploy rdee-core into Linux OS, including all other rdee-series packages

# Prepare
#@ .General-Process
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo -e "\033[31mError!\033[0m The script can only be executed rather than be sourced!"
    exit 101
fi
scriptDir=$(cd $(dirname "${BASH_SOURCE[0]}") && readlink -f .)
workDir=$PWD
cd $scriptDir

#@ .Pre-Check
#@ ..Git
gitVer=$(git --version 2>/dev/null)
valid_Git=1
if [[ -z $gitVer ]]; then
    valid_Git=0
# elif [[ $(echo $gitVer | grep -Po '(?<= )\d') != 2 ]]; then
#    valid_Git=0
fi

#@ ..module
module >&/dev/null
valid_Module=1
if [[ $? == 127 ]]; then
    valid_Modulee=0
fi

#@ ..python
valid_python=1
pyver=none
if [[ -z $(which python 2>/dev/null) ]]; then
    valid_python=0
else
    pyver=$(python --version | cut -d' ' -f2)
    if [[ $(echo $pyver | cut -d. -f1) != 3 || $(echo $pyver | cut -d. -f2) -lt 6 ]]; then
        valid_python=0
    fi
fi

#@ .preliminary-functions
function success() {
    echo -e '\033[32m'"$1"'\033[0m'
}
function error() {
    echo -e '\033[31m'"Error"'\033[0m' "$1"
    exit 101
}
function progress() {
    echo -e '\033[33m-- '"($(date '+%Y/%m/%d %H:%M:%S')) ""$1"'\033[0m'
}

#@ .Global-Variables
#@ ..WSL-detection
[[ -n "$WSL_DISTRO_NAME" ]] && isWSL=1 || isWSL=0
if [[ $isWSL == 1 ]]; then
    winuser=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r') #>- "| tr -d '\r'" is necessary or the username is followed by a ^M
fi

#@ .arguments
#@ ..defaultArg
reHome_fromArg=
deploy_mode=auto # setenv, module, module+
profile=
shop_help=0
with_repos=
utest=0
verbose=0
#@ <..resolve>
ARGS=$(getopt -o r:p:hd:w:uv --long reHome:,deploy_mode:,with_repos:,profile:,help -n "$0" -- "$@")
eval set -- "$ARGS"
while true; do
    case "$1" in
    -r | --reHome)
        reHome_fromArg=$2
        shift 2
        ;;
    -d | --deploy_mode)
        deploy_mode=$2
        shift 2
        ;;
    -p | --profile)
        profile=$2
        shift 2
        ;;
    -h | --help)
        show_help=1
        shift 1
        ;;
    -w | --with_repos)
        with_repos=$2
        shift 2
        ;;
    -u)
        utest=1
        shift 1
        ;;
    -v)
        verbose=1
        shift 1
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Unknown option $1"
        exit 200
        ;;
    esac
done

#@ .help
if [[ $show_help == 1 ]]; then
    echo -e "
usage: ./rdee.init.sh [options]

options:
    ● \033[32m-h\033[0m
        show help information
    ● \033[32m-e\033[0m
        Do not do any operation rather than echo
    ● \033[32m-r\033[0m, default:\$HOME
        set reHome path
    ● \033[32m-p\033[0m, [optional]
        set target profile to be updated.
"
    exit 0
fi

#@ .dependent
#@ ..project
VERSION=$(cat $scriptDir/../VERSION)
proj=$(basename $(realpath $scriptDir/..))

if [[ $utest == 0 ]]; then
    #@ .reHome
    if [[ -n "$reHome_fromArg" ]]; then #@ branch set reHome in arguments manually
        reHome=$reHome_fromArg
    elif [[ -z ${reHome} ]]; then #@ branch set default reHome
        reHome=${HOME}
    fi #@ branch omit branch which set reHome in environment variables
    echo -e "\033[32m reHome \033[0m = $reHome"

    #@ ..re-dir
    reRec=$reHome/recRoot
    reGit=$reRec/GitRepos
    reSoft=$reHome/Software
    reMANA=$reSoft/mana
    reModel=$reHome/models
    reTool=$reHome/Tool
    reTemp=$reHome/temp
    reTest=$reHome/test

    #@ Main
    #@ .File-Orgnization
    #@ ..WSL-only
    if [[ $isWSL == 1 ]]; then

        reDesktop=$reHome/Desktop
        reOnedrive=$reHome/Onedrive
        reBaidusync=$reHome/Baidusync
        reDownloads=$reHome/Downloads

        ln -Tsf /mnt/d/recRoot $reRec

        ln -Tsf /mnt/d/Baidusyncdisk $reBaidusync
        ln -Tsf /mnt/c/Users/${winuser}/OneDrive $reOnedrive
        ln -Tsf /mnt/c/Users/${winuser}/Desktop $reDesktop
        ln -Tsf /mnt/c/Users/${winuser}/Downloads $reDownloads

        mkdir -p $reHome/Software
        ln -Tsf /mnt/d/recRoot/DataVault/INSTALL $reHome/Software/src
    fi
    #@ ..bin
    mkdir -p $scriptDir/export/bin
    cd $scriptDir/export/bin
    for file in $scriptDir/../bin/*; do
        ln -sf $file .
    done

    #@ .Core | Write setenvfile & modulefile
    #@ ..
    if [[ "$deploy_mode" == setenv ]]; then
        cat <<EOF >$scriptDir/export/setenv.rdee.sh
#!/bin/bash

export reHome=${reHome}
export reRec=${reRec}
export reGit=${reGit}
export reSoft=${reSoft}
export reMANA=${reMANA}
export reModel=${reModel}
export reTool=${reTool}
export reTemp=${reTemp}
export reTest=${reTest}


alias cdR='cd $reRec'
alias cdG='cd $reGit'

export PATH=${scriptDir}/export/bin:\$PATH

export ANSI_RED='\033[31m'
export ANSI_GREEN='\033[32m'
export ANSI_YELLOW='\033[33m'
export ANSI_NC='\033[0m'

alias ..='cd ..'
alias ...='cd ../..'

alias rp='realpath'
alias ls='ls --color=auto'
alias ll='ls -alFh'
alias la='ls -A'


alias pso='ps -o ruser=userForLongName -e -o pid,ppid,c,stime,tty,time,cmd'
alias psu='ps -u \`whoami\` -o pid,tty,time,cmd'
alias du1='du --max-depth=1 -h'
alias dv='dirs -v'
alias topu='top -u \`whoami\`'

alias gf='gfortran'


alias web='echo "plz copy : export http_proxy=127.0.0.1:port; export https_proxy=127.0.0.1:port"'
alias unweb='unset https_proxy; unset http_proxy'

export pipsrc_tsh=https://pypi.tuna.tsinghua.edu.cn/simple

EOF
        if [[ $isWSL == 1 ]]; then
            cat <<EOF >>$scriptDir/export/setenv.rdee.sh
# >>>>>>>>>>>>>> WSL settings
export winuser=$winuser
export Onedrive=$reOnedrive
alias cdO='cd \$Onedrive/recRoot'
export Baidusync=$reBaidusync
alias cdB='cd \$Baidusync/recRoot'
export winHome=/mnt/c/Users/${winuser}
export Desktop=$reDesktop
alias cdU='cd \$winHome'
alias cdD='cd \$Desktop'

alias ii='explorer.exe'
EOF
            if [[ $(ls /mnt/d/DAPP/SumatraPDF/SumatraPDF*exe) != "" ]]; then
                echo 'alias pdf=/mnt/d/DAPP/SumatraPDF/SumatraPDF*exe' >>$scriptDir/export/setenv.rdee.sh
            fi
        fi
        if [[ -n $profile ]]; then
            if [[ $valid_python == 0 ]]; then
                error "Add statement in profile requires python with version >= 3.6, now is ${pyver}"
            fi
            cat <<EOF >.temp.$proj
# >>>>>>>>>>>>>>>>>>>>>>>>>>> [rdee]
source $scriptDir/export/setenv.rdee.sh

EOF
            python $scriptDir/../bin/fileop.ra-block.py $profile .temp.$proj

            if [[ $? -eq 0 ]]; then
                success "Succeed to add source statements in $profile"
            else
                error "Failed add source statements in $profile"
            fi
            rm -f .temp.$proj
        fi

    elif [[ $deploy_mode == module ]]; then
        mkdir -p $scriptDir/export/modulefiles/rdee
        cat <<EOF >$scriptDir/export/modulefiles/rdee/default
setenv reHome ${reHome}
setenv reRec ${reRec}
setenv reGit ${reGit}
setenv reSoft ${reSoft}
setenv reMANA ${reMANA}
setenv reModel ${reModel}
setenv reTool ${reTool}
setenv reTemp ${reTemp}
setenv reTest ${reTest}


set-alias cdR {cd $reRec}
set-alias cdG {cd $reGit}


setenv ANSI_RED {\033[31m}
setenv ANSI_GREEN {\033[32m}
setenv ANSI_YELLOW {\033[33m}
setenv ANSI_NC {\033[0m}

set-alias .. {cd ..}
set-alias ... {cd ../..}


set-alias rp realpath

set-alias ll {ls -alF}
set-alias ls {ls --color=auto}
set-alias la {ls -A}


set-alias pso {ps -o ruser=userForLongName -e -o pid,ppid,c,stime,tty,time,cmd}
set-alias psu {ps -u \`whoami\` -o pid,tty,time,cmd}
set-alias grep {grep --color=auto}
set-alias du1 {du --max-depth=1 -h}
set-alias dv {dirs -v}
set-alias topu {top -u \`whoami\`}
set-alias cd0 {cd \`readlink -f .\`}

set-alias gf {gfortran}


set-alias web {echo "plz copy : export http_proxy=127.0.0.1:port; export https_proxy=127.0.0.1:port"}
set-alias unweb {unset https_proxy; unset http_proxy}

setenv pipsrc_tsh https://pypi.tuna.tsinghua.edu.cn/simple

EOF

        if [[ $isWSL == 1 ]]; then
            cat <<EOF >>$scriptDir/export/modulefiles/rdee/default
setenv winuser $winuser
setenv Onedrive $reOnedrive
setenv Baidusync $reBaidusync
setenv winHome /mnt/c/Users/${winuser}
setenv Desktop $reDesktop

set-alias cdO "cd \$env(Onedrive)/recRoot"
set-alias cdB "cd \$env(Baidusync)/recRoot"
set-alias cdU "cd \$env(winHome)"
set-alias cdD "cd \$env(Desktop)"

set-alias ii {explorer.exe}

EOF
            if [[ $(ls /mnt/d/DAPP/SumatraPDF/SumatraPDF*exe) != "" ]]; then
                echo 'set-alias pdf {/mnt/d/DAPP/SumatraPDF/SumatraPDF*exe}' >>$scriptDir/export/modulefiles/rdee/default
            fi
        fi
        if [[ -n $profile ]]; then
            if [[ $valid_python == 0 ]]; then
                error "Add statement in profile requires python with version >= 3.6, now is ${pyver}"
            fi
            cat <<EOF >.temp.$proj
# >>>>>>>>>>>>>>>>>>>>>>>>>>> [rdee]
module use $scriptDir

EOF
            python $scriptDir/../bin/fileop.ra-block.py $profile .temp.$proj

            if [[ $? -eq 0 ]]; then
                success "Succeed to add source statements in $profile"
            else
                error "Failed add source statements in $profile"
            fi
            rm -f .temp.$proj
        fi
    elif [[ $deploy_mode == "auto" ]]; then
        #@ ..confirm-deploy-mode
        if [[ -e $scriptDir/export/setenv.rdee.sh ]]; then
            deploy_mode=setenv
        elif [[ -e $scriptDir/export/modulefiles ]]; then
            deploy_mode=module
        else
            error "deploy_mode=auto requires an already-existed deployment"
        fi
    else
        error "Unexpected deploy_mode=${deploy_mode}"
    fi

    if [[ -n "$with_repos" ]]; then
        if [[ $valid_python == 0 ]]; then
            error "Add statement in profile requires python with version >= 3.6, now is ${pyver}"
        fi
        IFS=, read -ra repos <<<$with_repos
        for repo in "${repos[@]}"; do
            if [[ "$repo" =~ : ]]; then
                repo_name=$(echo $repo | cut -d ':' -f1)
                repo_branch=$(echo $repo | cut -d ':' -f2)
            else
                repo_name=$repo
                repo_branch=
            fi

            repo_dir=$scriptDir/../../$repo_name

            if [[ ! -e $repo_dir ]]; then
                cd $scriptDir/../..
                if [[ -n "$repo_branch" ]]; then
                    git clone --depth 1 -b $repo_branch https://github.com/Roadelse/${repo_name}.git
                else
                    git clone --depth 1 https://github.com/Roadelse/${repo_name}.git
                fi
                if [[ $? -ne 0 ]]; then
                    error "Failed to git clone repository: ${repo_name} from GitHub with selective branch=${repo_branch}"
                fi
            elif [[ -n "$repo_branch" ]]; then
                cd $scriptDir/../../$repo_name
                git checkout $repo_branch
                if [[ $? != 0 ]]; then
                    error "Cannot checkout specified branch=${repo_branch} in ${repo_name}"
                fi
            fi

            cd $scriptDir
            if [[ $verbose == 1 ]]; then
                bash $repo_dir/deploy/deploy.Linux.sh -d $deploy_mode
            else
                bash $repo_dir/deploy/deploy.Linux.sh -d $deploy_mode >&/dev/null
            fi
            if [[ $? -ne 0 ]]; then
                error "Failed to deploy ${repo_name}"
            fi

            cd $scriptDir/export/bin
            if [[ $deploy_mode == setenv ]]; then
                envpaths=($($scriptDir/tools/extract-repo-env.py $repo_dir/deploy/export/setenv.${repo_name}.sh .temp.$proj))
                python $scriptDir/../bin/fileop.ra-block.py $scriptDir/export/setenv.rdee.sh .temp.$proj
            else
                envpaths=($($scriptDir/tools/extract-repo-env.py $repo_dir/deploy/export/modulefiles/${repo_name}/default .temp.rdee-core))
                python $scriptDir/../bin/fileop.ra-block.py $scriptDir/export/modulefiles/rdee/default .temp.$proj
            fi
            rm -f .temp.$proj
            for ep in "${envpaths[@]}"; do
                for f in $(ls $ep/* -d); do
                    ln -sf $f .
                done
            done

            success "Succeed to add ${repo_name} into rdee project"
        done
    fi
else
    if [[ $verbose == 1 ]]; then
        bash ./deploy.Linux.sh -d setenv --with_repos=rdee-python:dev,rdee-bash -v
    else
        bash ./deploy.Linux.sh -d setenv --with_repos=rdee-python:dev,rdee-bash
    fi
    if [[ $? != 0 ]]; then
        error "Failed to deploy rdee-core firstly"
    fi
    # exit
    source $scriptDir/export/setenv.rdee.sh
    if [[ ${PYTHONPATH} =~ $(realpath $scriptDir/../../rdee-python/deploy/export) ]]; then
        success "deploy rdee-core with rdee-python | passed"
    else
        error "Failed to deploy rdee-core with rdee-python"
    fi
    alias iR >&/dev/null
    if [[ $? == 0 ]]; then
        success "deploy rdee-core with rdee-bash | passed"
    else
        error "Failed to deploy rdee-core with rdee-bash"
    fi
    rm -rf $scriptDir/export
fi
