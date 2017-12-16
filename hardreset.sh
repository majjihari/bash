#!/bin/bash

set -e

sudo rm -rf $TMPDIR/zutils_done > /dev/null 2>&1
sudo rm -rf /tmp/zutils_done > /dev/null 2>&1
sudo rm -rf /opt/code/github/jumpscale/bash > /dev/null 2>&1

if [ -z "$HOMEDIR" ] ; then
    export HOMEDIR="$HOME"
fi

if [ -z "$HOMEDIR" ] ; then
    echo "[-] ERROR, could not specify homedir"
    exit 1
fi

export ZLogFile='/tmp/zutils.log'

die() {
    echo "ERROR"
    echo "[-] something went wrong: $1"
    rm -f /tmp/sdwfa #to remove temp passwd for restic, just to be sure
    cat $ZLogFile
    # return 1
    exit 1
}

if [ ! -f $HOMEDIR/.bash_profile ]; then
   touch $HOMEDIR/.bash_profile
fi

if [ ! -f $HOMEDIR/.bash_profile ]; then
   sed -i.bak '/jsenv.sh/d' $HOMEDIR/.profile
fi

rm -f ~/jsenv.sh
rm -f ~/jsinit.sh

sed -i.bak '/export SSHKEYNAME/d' $HOMEDIR/.bash_profile
sed -i.bak '/jsenv.sh/d' $HOMEDIR/.bash_profile
sed -i.bak '/.*zlibs.sh/d' $HOMEDIR/.bash_profile

if [ "$(uname)" == "Darwin" ]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"
    sudo rm -rf /usr/local/bin/
    sudo rm -rf /usr/local/Caskroom/
    sudo rm -rf /usr/local/etc/
    sudo rm -rf /usr/local/include/
    sudo rm -rf /usr/local/lib/
    sudo rm -rf /usr/local/remotedesktop/
    sudo rm -rf /usr/local/share/
    sudo rm -rf /usr/local/var/
    rm -rf $HOMEDIR/code/github/jumpscale
    rm -rf $HOMEDIR/opt
    rm -rf $HOMEDIR/.jsconfig/
    rm -f $HOMEDIR/.jumpscale9.toml
    rm -f $HOMEDIR/.profile_js
    rm -rf $HOMEDIR/docker
    rm -rf $HOMEDIR/cfg
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

    brew install wget
    brew install mc
    brew install git
    brew install curl

else
    echo "ONLY OSX SUPPORTED FOR NOW"
fi

echo "[+] Hardreset OK"
