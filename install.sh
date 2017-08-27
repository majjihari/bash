#!/bin/bash

set -e

if [ -z "$HOMEDIR" ] ; then
    export HOMEDIR="$HOME"
fi

if [ -z "$HOMEDIR" ] ; then
    echo "[-] ERROR, could not specify homedir"
    exit 1
fi

#first check is in home
if [ -e ~/code/github/jumpscale ]; then
    export ZUTILSDIR=~/code/github/jumpscale
fi

#then in /opt
if [ -e /opt/code/github/jumpscale ]; then
    export ZUTILSDIR=/opt/code/github/jumpscale
fi

if [ "$(uname)" == "Darwin" ]; then
    xcode-select -v 2>&1 >> /dev/null
    if [ $? -ne 0 ]; then
        xcode-select --install
    fi
    brew -v 2>&1 >> /dev/null
    if [ $? -ne 0 ]; then
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
    curl -V 2>&1 >> /dev/null
    if [ $? -ne 0 ]; then
        brew install curl
    fi
    export ZUTILSDIR=${ZUTILSDIR:-~/code/github/jumpscale}
else
    #TODO: *2 need to support windows as well
    apt-get update
    apt-get install curl -y
    apt-get install git wget -y
    export ZUTILSDIR=${ZUTILSDIR:-/opt/code/github/jumpscale}
fi

#if not exist then do in /opt/code...


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
    # local giturl=git@github.com:Jumpscale/bash.git
    local giturl=https://github.com/Jumpscale/bash.git
    local branch=${ZUTILSBRANCH:-master}
    echo "[+] get code $giturl ($branch)"
    pushd $ZUTILSDIR 2>&1 > $ZLogFile

    if ! grep -q ^github.com ~/.ssh/known_hosts 2> /dev/null; then
        ssh-keyscan github.com >> ~/.ssh/known_hosts 2>&1 > $ZLogFile || die || return 1
    fi

    if [ ! -e $ZUTILSDIR/bash ]; then
        echo " [+] clone zutils"
        git clone -b ${branch} $giturl bash 2>&1 > $ZLogFile || die || return 1
    else
        pushd $ZUTILSDIR/bash
        echo " [+] pull"
        git pull  2>&1 > $ZLogFile || die || return 1
        popd > /dev/null 2>&1
    fi
    popd > /dev/null 2>&1
}


if [ ! -f $HOMEDIR/.bash_profile ]; then
   touch $HOMEDIR/.bash_profile
fi

rm -f ~/jsenv.sh
rm -f ~/jsinit.sh

sed -i.bak '/export SSHKEYNAME/d' $HOMEDIR/.bash_profile
sed -i.bak '/jsenv.sh/d' $HOMEDIR/.bash_profile
sed -i.bak '/jsenv.sh/d' $HOMEDIR/.profile
sed -i.bak '/.*zlibs.sh/d' $HOMEDIR/.bash_profile
echo ". ${ZUTILSDIR}/bash/zlibs.sh" >> $HOMEDIR/.bash_profile

if [ ! -e ~/.iscontainer ] || [ -n $ZHOSTONLY ]; then
    ZUtilsGetCode
    . ${ZUTILSDIR}/bash/zlibs.sh
    ZInstaller_js9_host
else
    . ${ZUTILSDIR}/bash/zlibs.sh
fi

echo "[+] Install OK"
