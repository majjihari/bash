#!/bin/bash
set -x

apt-get install git -y

#first check is in home
if [ -e ~/code/github/jumpscale ]; then
    export ZUTILSDIR=~/code/github/jumpscale
fi

#then in /opt
if [ -e /opt/code/github/jumpscale ]; then
    export ZUTILSDIR=/opt/code/github/jumpscale
fi

#if not exist then do in /opt/code...
export ZUTILSDIR=${ZUTILSDIR:-/opt/code/github/jumpscale}

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
    echo "[+] get code $giturl ($branch)"
    pushd $ZUTILSDIR

    if ! grep -q ^github.com ~/.ssh/known_hosts 2> /dev/null; then
        ssh-keyscan github.com >> ~/.ssh/known_hosts 2>&1 > $ZLogFile || die
    fi

    if [ ! -e $ZUTILSDIR/bash ]; then
        echo " [+] clone zutils"
        git clone -b ${branch} $giturl bash 2>&1 > $ZLogFile || die
    else
        pushd $ZUTILSDIR/bash
        echo " [+] pull"
        git pull  2>&1 > $ZLogFile || die
        popd > /dev/null 2>&1
    fi
    popd > /dev/null 2>&1
}

ZUtilsGetCode

. ${ZUTILSDIR}/bash/zlibs.sh
