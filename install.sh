#!/bin/bash
set -x


export ZUTILSDIR=${ZUTILSDIR:-~}
export ZLogFile='/tmp/zutils.log'

die() {
    echo "ERROR"
    echo "[-] something went wrong: $1"
    rm -f /tmp/sdwfa #to remove temp passwd for restic, just to be sure
    cat $ZLogFile
    return 1
    # exit 1
}

ZUtilsGetCode() {
    mkdir -p $ZUTILSDIR
    #giturl like: git@github.com:mathieuancelin/duplicates.git
    local giturl=git@github.com:Jumpscale/bash.git
    local branch=master
    echo "* get code $giturl ($branch)"
    pushd $ZUTILSDIR

    if ! grep -q ^github.com ~/.ssh/known_hosts 2> /dev/null; then
        ssh-keyscan github.com >> ~/.ssh/known_hosts 2>&1 > $ZLogFile || die
    fi

    if [ ! -e $ZUTILSDIR/zutils ]; then
        echo " * clone zutils"
        git clone -b ${branch} $giturl zutils 2>&1 > $ZLogFile || die
    else
        pushd $ZCODEDIR/zutils
        echo " * pull"
        git pull  2>&1 > $ZLogFile || die
        popd
    fi
    popd
}

ZUtilsGetCode

. ${ZUTILSDIR}/zutils/zlibs.sh
