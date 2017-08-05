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
    apt-get install curl -y
    apt-get install git wget -y
    export ZUTILSDIR=${ZUTILSDIR:-/opt/code/github/jumpscale}
fi

#if not exist then do in /opt/code...


#IS COPY FROM IN SSH_LIB.SSH , DO MAINTAIN MASTER THERE !!!
ZKeysLoad() {
    
    pgrep ssh-agent > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        #start ssh-agent if not running yet
        echo "[+] did not find ssh-agent will start"
        eval `ssh-agent`
    fi

    if [ -z "$SSH_AUTH_SOCK" ] ; then
        #start ssh-agent if not running yet
        echo "[-] could not find SSH_AUTH_SOCK, please load ssh-agent"
        return 1
    fi

    local KEYPATH="$HOME/.ssh/$SSHKEYNAME"

    ssh-add -l > /dev/null 2>&1 
    if [ $? -ne 0 ]; then
        echo "[?] ssh-key not loaded or ssh-agent not loaded."

        export SSHKEYNAME=`echo $SSHKEYNAME | xargs`        
        local KEYPATH="$HOME/.ssh/$SSHKEYNAME"

        while [ ! -f $KEYPATH ] ; do
            echo "[+] Found following keys on filesystem (select one if relevant):"
            cd ~/.ssh;find . -type f -print -o -name . -o -prune| grep -v .pub|grep -v known_hosts| sed s/"\/"//| sed s/\./" - "/
            echo
            echo "    . Please give name of ssh key to load, if empty (press enter) will ask to generate"
            echo
            if [[ "$SHELL" == *"zsh" ]];then
                read 'SSHKEYNAME?SSHKEYNAME: '
            else
                read -p 'SSHKEYNAME: ' SSHKEYNAME
            fi

            local KEYPATH="$HOME/.ssh/$SSHKEYNAME"

            if [ $SSHKEYNAME = "" ]; then
                echo "    . Key name not given, should we generate a sshkey name? press 'y'"
                read -n 1 answer
                if [ "$answer" = "y" ]; then
                    read -p '    . Please specify name of key you want to generate: ' SSHKEYNAME
                    read -p '    . Please specify email addr: ' EMAILADDR
                    if [ -z $SSHKEYNAME ] || [ -z $EMAILADDR ] ; then
                        echo "[-] Please specify sshkeyname & emailaddr, cannot continue."
                        return 1
                    fi
                    ssh-keygen -t rsa -b 4096 -f KEYPATH -C "$EMAILADDR"
                fi
            else
                if [ ! -f KEYPATH ]; then
                    echo "[-] did not find the sshkeyname: $KEYPATH, please try again"
                fi
            fi

            #remove old
            sed -i.bak '/export SSHKEYNAME/d' $HOMEDIR/.bash_profile
            sed -i.bak '/.*zlibs.sh/d' $HOMEDIR/.bash_profile

            echo "export SSHKEYNAME=$SSHKEYNAME" >> $HOMEDIR/.bash_profile
            #re-insert source of zlibs.sh            
            echo ". ${ZUTILSDIR}/bash/zlibs.sh" >> $HOMEDIR/.bash_profile
            

        done
    fi

    if ! ssh-add -l | grep -q $SSHKEYNAME; then
        echo "[+] Will now try to load sshkey: $HOMEDIR/.ssh/$SSHKEYNAME"
        ssh-add $HOMEDIR/.ssh/$SSHKEYNAME
        echo "ssh key $SSHKEYNAME loaded"
    fi

}


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
    # local giturl=https://github.com/Jumpscale/bash.git
    local branch=master
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

ZKeysLoad
ZUtilsGetCode

. ${ZUTILSDIR}/bash/zlibs.sh

echo "[+] Install OK"