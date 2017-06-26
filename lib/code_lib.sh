
############ CODE

ZCodeConfig() {
    export ZCODEDIR=~/code
}


ZGetCodeJSUsage() {
   cat <<EOF
Usage: ZGetCode [-r reponame] [-g giturl] [-a account] [-b branch]
   -r reponame: name or repo which is being downloaded
   -b branchname: defaults to master
   -h: help
EOF
}


ZGetCodeJS() {
    ZCodeConfig
    local OPTIND
    local account='jumpscale'
    local reponame=''
    local branch='master'
    while getopts "a:r:u:b:h" opt; do
        case $opt in
           r )  reponame=$OPTARG ;;
           b )  branch=$OPTARG ;;
           h )  ZGetCodeJSUsage ; return 0 ;;
           \? )  ZGetCodeJSUsage ; return 1 ;;
        esac
    done

    if [ -z "$reponame" ]; then
        ZGetCodeJSUsage
        return
    fi

    local giturl="git@github.com:Jumpscale/$reponame.git"

    ZGetCode -r $reponame -a $account -u $giturl -b $branch

}

ZGetCodeUsage() {
   cat <<EOF
Usage: ZGetCode [-r reponame] [-g giturl] [-a account] [-b branch]
   -a account: will default to 'varia', but can be account name
   -r reponame: name or repo which is being downloaded
   -u giturl: e.g. git@github.com:mathieuancelin/duplicates.git
   -b branchname: defaults to master
   -h: help
EOF
}
#to return to original dir do pushd
ZGetCode() {
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
           h )  ZGetCodeUsage ; return 0 ;;
           \? )  ZGetCodeUsage ; return 1 ;;
        esac
    done
    if [ -z "$giturl" ]; then
        ZGetCodeUsage
        return
    fi

    if [ -z "$reponame" ]; then
        ZGetCodeUsage
        return
    fi

    mkdir -p $ZCODEDIR/$account
    echo "[+] get code $giturl ($branch)"

    pushd $ZCODEDIR/$account > /dev/null 2>&1

    if ! grep -q ^github.com ~/.ssh/known_hosts 2> /dev/null; then
        ssh-keyscan github.com >> ~/.ssh/known_hosts 2>&1 > $ZLogFile || die
    fi

    if [ ! -e $ZCODEDIR/$account/$reponame ]; then
        echo " [+] clone"
        git clone -b ${branch} $giturl $reponame 2>&1 > $ZLogFile || die
    else
        pushd $ZCODEDIR/$account/$reponame > /dev/null 2>&1
        echo " [+] pull"
        git pull  2>&1 > $ZLogFile || die
        popd > /dev/null 2>&1
    fi
    popd > /dev/null 2>&1
    # pushd $ZCODEDIR/$account/$reponame  > /dev/null 2>&1
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
