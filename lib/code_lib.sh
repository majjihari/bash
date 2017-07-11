
############ CODE

ZCodeConfig() {
    export ZCODEDIR=~/code
}


ZCodeGetJSUsage() {
   cat <<EOF
Usage: ZCodeGet [-r reponame] [-g giturl] [-a account] [-b branch]
   -r reponame: name or repo which is being downloaded
   -b branchname: defaults to master
   -h: help

check's out jumpscale repo to ~/code/jumpscale/$reponame
branchname can optionally be specified.

if specified but repo exists then a pull will be done & branch will be ignored !!!

if reponame not specified then will checkout
- bash
- lib9
- core9
- ays9
- prefab

EOF
}


ZCodeGetJS() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    ZCodeConfig
    local OPTIND
    local account='jumpscale'
    local reponame=''
    local branch='master'
    while getopts "r:b:h" opt; do
        case $opt in
           r )  reponame=$OPTARG ;;
           b )  branch=$OPTARG ;;
           h )  ZCodeGetJSUsage ; return 0 ;;
           \? )  ZCodeGetJSUsage ; return 1 ;;
        esac
    done

    if [ -z "$reponame" ]; then
        ZCodeGetJS -r core9 || die || return 1
        ZCodeGetJS -r lib9 || die || return 1
        ZCodeGetJS -r bash || die || return 1
        ZCodeGetJS -r ays9 || die || return 1
        ZCodeGetJS -r prefab || die || return 1
        return
    fi

    local giturl="git@github.com:Jumpscale/$reponame.git"

    ZCodeGet -r $reponame -a $account -u $giturl -b $branch

}

ZCodeGetUsage() {
   cat <<EOF
Usage: ZCodeGet [-r reponame] [-g giturl] [-a account] [-b branch]
   -a account: will default to 'varia', but can be account name
   -r reponame: name or repo which is being downloaded
   -u giturl: e.g. git@github.com:mathieuancelin/duplicates.git
   -b branchname: defaults to master
   -h: help

check's out any git repo repo to ~/code/$account/$reponame
branchname can optionally be specified.

if specified but repo exists then a pull will be done & branch will be ignored !!!

EOF
}
#to return to original dir do pushd
ZCodeGet() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    ZCodeConfig
    local OPTIND
    local account='varia'
    local reponame=''
    local giturl=''
    local branch='master'
    while getopts "a:r:u:b:h" opt; do
        case $opt in
           a )  account=$OPTARG ;;
           r )  reponame=$OPTARG ;;
           u )  giturl=$OPTARG ;;
           b )  branch=$OPTARG ;;
           h )  ZCodeGetUsage ; return 0 ;;
           \? )  ZCodeGetUsage ; return 1 ;;
        esac
    done
    if [ -z "$giturl" ]; then
        ZCodeGetUsage
        return 0
    fi

    if [ -z "$reponame" ]; then
        ZCodeGetUsage
        return 0
    fi

    mkdir -p $ZCODEDIR/$account
    echo "[+] get code $giturl ($branch)"

    pushd $ZCODEDIR/$account > /dev/null 2>&1

    if ! grep -q ^github.com ~/.ssh/known_hosts 2> /dev/null; then
        ssh-keyscan github.com >> ~/.ssh/known_hosts 2>&1 > $ZLogFile || die || return 1
    fi

    if [ ! -e $ZCODEDIR/$account/$reponame ]; then
        echo " [+] clone"
        git clone -b ${branch} $giturl $reponame 2>&1 > $ZLogFile || die || return 1
    else
        pushd $ZCODEDIR/$account/$reponame > /dev/null 2>&1
        echo " [+] pull"
        git pull  2>&1 > $ZLogFile || die || return 1
        popd > /dev/null 2>&1
    fi
    popd > /dev/null 2>&1
    # pushd $ZCODEDIR/$account/$reponame  > /dev/null 2>&1
}

ZCodePushUsage(){
   cat <<EOF
Usage: ZCodePush [-r reponame] [-a account] [-m message]
   -a account: will default to 'varia', but can be account name
   -r reponame: name or repo
   -m message for commit: required !
   -h: help

   will add/remove files, commit, pull & push

EOF
}

ZCodePush() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    ZCodeConfig
    local OPTIND
    local account='varia'
    local reponame=''
    local message=''
    while getopts "a:r:m:h" opt; do
        case $opt in
           a )  account=$OPTARG ;;
           r )  reponame=$OPTARG ;;
           m )  message=$OPTARG ;;
           h )  ZCodePushUsage ; return 0 ;;
           \? )  ZCodePushUsage ; return 1 ;;
        esac
    done
    if [ -z "$message" ]; then
        ZCodePushUsage
        return
    fi

    if [ -z "$account" ]; then
        ZCodePushUsage
        return
    fi

    if [ -z "$reponame" ]; then
        echo "walk over directories: $ZCODEDIR/$account"

        ls -d $ZCODEDIR/$account/*/ | {
            while read DIRPATH ; do
                DIRNAME=$(basename $DIRPATH)
                ZCodePush -a $account -r $DIRNAME -m $message || die || return 1
            done
        }
        return
    fi

    echo "[+] commit-pull-push  code $ZCODEDIR/$account/$reponame"

    pushd $ZCODEDIR/$account > /dev/null 2>&1

    if [ ! -e $ZCODEDIR/$account/$reponame ]; then
        die "could not find $ZCODEDIR/$account/$reponame" || return 1
    else
        pushd $ZCODEDIR/$account/$reponame > /dev/null 2>&1
        echo " [+] add"
        git add . -A  2>&1 > $ZLogFile #|| die "ZCodePush (add) $@" || return 1
        echo " [+] commit"
        git commit -m '$message'  2>&1 > $ZLogFile #|| die "ZCodePush (commit) $@" || return 1
        echo " [+] pull"
        git pull  2>&1 > $ZLogFile || die "ZCodePush (pull) $@" || return 1
        echo " [+] push"
        git push  2>&1 > $ZLogFile || die "ZCodePush (push) $@" || return 1
        popd > /dev/null 2>&1
    fi
    popd > /dev/null 2>&1
}

ZCodePushJSUsage(){
    cat <<EOF
Usage: ZCodePushJS [-r reponame] [-a account] [-m message]
    -r reponame: name or repo
    -m message for commit: required !
    -h: help

    will add/remove files, commit, pull & push

EOF
}

ZCodePushJS(){
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    ZCodeConfig
    local OPTIND
    local reponame=''
    local message=''
    while getopts "r:m:h" opt; do
        case $opt in
           r )  reponame=$OPTARG ;;
           m )  message=$OPTARG ;;
           h )  ZCodePushJSUsage ; return 0 ;;
           \? )  ZCodePushJSUsage ; return 1 ;;
        esac
    done
    if [ -z "$message" ]; then
        ZCodePushJSUsage
        return
    fi

    if [ "$reponame" = "" ]; then
        ZCodePush -a jumpscale -m $message || die "$@" || return 1
    else
        ZCodePush -a jumpscale -r $reponame -m $message || die "$@" || return 1
    fi
}

# ZBranchExists() {
#     local giturl="$1"
#     local branch=${2:-${ZBRANCH}}
#
#     echo "[+] Checking if ${repository}/${ZBRANCH} exists"
#     httpcode=$(curl -o /dev/null -I -s --write-out '%{http_code}\n' $giturl/tree/${branch})
#
#     if [ "$httpcode" = "200" ]; then
#         return 0
#     else
#         return 1
#     fi
# }
