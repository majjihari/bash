
############ CODE

#to return to original dir do pushd
ZGetCode() {
    mkdir -p $ZCODEDIR
    #giturl like: git@github.com:mathieuancelin/duplicates.git
    local name="$1"
    local giturl="$2"
    local branch=${3:-${ZBRANCH}}
    echo "* get code $giturl ($branch)"
    pushd $ZCODEDIR

    if ! grep -q ^github.com ~/.ssh/known_hosts 2> /dev/null; then
        ssh-keyscan github.com >> ~/.ssh/known_hosts 2>&1 > $logfile || die
    fi

    if [ ! -e $ZCODEDIR/$name ]; then
        echo " * clone"
        git clone -b ${branch} $giturl $name 2>&1 > $logfile || die
    else
        pushd $ZCODEDIR/$name
        echo " * pull"
        git pull  2>&1 > $logfile || die
        popd
    fi
    popd
    pushd $ZCODEDIR/$name
}


ZBranchExists() {
    local giturl="$1"
    local branch=${2:-${ZBRANCH}}

    echo "* Checking if ${repository}/${ZBRANCH} exists"
    httpcode=$(curl -o /dev/null -I -s --write-out '%{http_code}\n' $giturl/tree/${branch})

    if [ "$httpcode" = "200" ]; then
        return 0
    else
        return 1
    fi
}
