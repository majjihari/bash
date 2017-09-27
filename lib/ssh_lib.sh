
ZSSHTEST() {
    echo '' >> $ZLogFile
    ZNodeEnvDefaults
    ssh root@$RNODE -p $RPORT 'ls /' >> $ZLogFile 2>&1 || die "could not connect over ssh to $RNODE:$RPORT" || return 1
    #TODO: check and if not connect, ask the params again, till its all ok
}


ZSSH_RFORWARD_Usage() {
   cat <<EOF
Forward remote port to a local one (e.g. give people access to your machine or a machine in your network)
Usage: ZEXEC [-l]
   -a: host, is obligatary (is where people will have to connect to to get access to your local machine)
   -l: local address, std is localhost
   -p: local port, std is 22
   -r: remote port, std is 2244
   -u: user, std = root
   -h: help

executes a command local or over ssh (using variable RNODE & RPORT)
will std run in background (tmux)

EOF
}
ZSSH_RFORWARD() {(
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile
    local raddress=""
    local laddress=localhost
    local lport=22
    local rport=2244
    local user='root'

    local OPTIND
    while getopts "a:l:p:r:u:h" opt; do
        case $opt in
           a )  raddress=$OPTARG ;;
           l )  laddress=$OPTARG ;;
           p )  lport=$OPTARG ;;
           r )  rport=$OPTARG ;;
           u )  user=$OPTARG ;;
           h )  ZSSH_RFORWARD_Usage ; return 0 ;;
           \? )  ZSSH_RFORWARD_Usage ; return 0 ;;
        esac
        # shift
    done
    if [ "$raddress" != "" ] ; then
        ssh -R $rport:$laddress:$lport $user@$raddress || die "could not to remote portforward: $@" || return 1
    else
        die "could not forward remote port to local, check syntax: $@"
    fi

)}




ZEXECUsage() {
   cat <<EOF
Usage: ZEXEC [-c command to execute] [-b] [-h]
   -c: command to execute
   -z: import ZUtils before calling command
   -i: interactive mode
   -t: tmux mode, the command will be executed in tmux (local or remote), not implemented yet
   -l: local execution (not over ssh)
   -h: help

executes a command local or over ssh (using variable RNODE & RPORT)

is non interactive by default.
to see output: do e.g. 'cat $ZLogFile'

EOF
}
ZEXEC() {(
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile
    local OPTIND
    local cmd=""
    local interactive=0
    local localcmd=0
    local iimport=""
    ZNodeEnvDefaults || return 1
    while getopts "c:hzitl" opt; do
        case $opt in
           c )  cmd=$OPTARG ;;
           i )  interactive=1 ;;
           l )  localcmd=1 ;;
           h )  ZEXECUsage ; return 0 ;;
           z )  iimport='. /opt/code/github/jumpscale/bash/zlibs.sh;';RSync_ZTools || die "could not rsync bash" || return 1;;
        esac
    done
    if [ "$cmd" = "" ] ; then
        die "syntax error in ZEXEC, cmd not specified: $@" || return 1
    fi

    if [ $localcmd -eq 0 ] ; then
        if [ $interactive -eq 1 ] ; then
            ssh -qAt root@$RNODE -p $RPORT "TERM=xterm;$iimport$cmd" >> $ZLogFile 2>&1 || die "ssh $@" || return 1
            # ssh -A root@$RNODE -p $RPORT "$cmd" && return 1
        else
            # ssh -A root@$RNODE -p $RPORT "$cmd" >> $ZLogFile 2>&1 || die "could not ssh command: $cmd" && return 1
            ssh -qAt root@$RNODE -p $RPORT "TERM=xterm;$iimport$cmd"  >> $ZLogFile 2>&1 || die "ssh $@" || return 1
            # cat $ZLogFile
        fi
    else

        if [ $interactive -eq 1 ] ; then
            $cmd || return 1
        else
            $cmd  >> $ZLogFile 2>&1 || die "error in ZEXEC local execute: $@" || return 1
        fi
    fi


)}



#goal is to allow people to get into their container without thinking
ZSSH() {(
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile
    ZNodeEnvDefaults
    if [ -n "$1" ]; then
        ssh -At root@$RNODE -p $RPORT "TERM=xterm;. /opt/code/github/jumpscale/bash/zlibs.sh;$@;bash -i"  || return 1
    else
        ssh -At root@$RNODE -p $RPORT "TERM=xterm;. /opt/code/github/jumpscale/bash/zlibs.sh;bash -i"  || return 1
    fi

)}

ZNodeUbuntuPrepare() {
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile
    ZNodeEnvDefaults  || return 1
    ZSSH 'apt-get update;apt-get upgrade -y'  || return 1
    ZDockerInstall  || return 1
    ZSSH "curl https://raw.githubusercontent.com/Jumpscale/bash/master/install.sh?$RANDOM > /tmp/install.sh;sh /tmp/install.sh"  || return 1
}



ZNodePortSet() {
    echo '' >> $ZLogFile
    if [ ! -n "$1" ]; then
        read -p "port of node: " RPORT
    else
        RPORT=$1
    fi
    export RPORT
}

ZNodeSet() {
    echo '' >> $ZLogFile
    if [ ! -n "$1" ]; then
        read -p "ipaddr or hostname of node: " RNODE
    else
        RNODE=$1
    fi
    export RNODE
}

ZNodeEnvDefaults() {
    echo '' >> $ZLogFile
    export RNODE=${RNODE:-'localhost'}
    if [ "$RNODE" == "localhost" ] ; then
        export RPORT=${RPORT:-2222}
    else
        export RPORT=${RPORT:-22}
    fi    
    

}

ZNodeEnv() {
    echo "node          :  $RNODE"
    echo "sshport       :  $RPORT"
}

ZKeysGenDocker() {
    if [ -z "$SSH_AUTH_SOCK" ] ; then
        #start ssh-agent if not running yet
        eval `ssh-agent -s`
    fi
    if [ -z "$SSH_AUTH_SOCK" ] ; then
        echo "[-] could not find SSH_AUTH_SOCK, please load ssh-agent"
        return 1
    fi

    local SSHKEYNAME="docker"
    local KEYPATH="$HOME/.ssh/$SSHKEYNAME"
    local EMAILADDR="info@nothing.com"

    ssh-keygen -t rsa -b 4096 -f $KEYPATH -C "$EMAILADDR"  -N ""

    if ! ssh-add -l | grep -q $SSHKEYNAME; then
        echo "[+] Will now try to load sshkey: $HOMEDIR/.ssh/$SSHKEYNAME"
        ssh-add $HOMEDIR/.ssh/$SSHKEYNAME
        echo "ssh key $SSHKEYNAME loaded"
    fi    

}

ZKeysLoad() {
    
    if [ -z "$SSH_AUTH_SOCK" ] ; then
        #start ssh-agent if not running yet
        eval `ssh-agent -s`
    fi

    if [ -z "$SSH_AUTH_SOCK" ] ; then
        echo "[-] could not find SSH_AUTH_SOCK, please load ssh-agent"
        return 1
    fi

    local KEYPATH="$HOME/.ssh/$SSHKEYNAME"

    ssh-add -l > /dev/null 2>&1 
    if  [ $? -ne 0 ] || [ "$SSHKEYNAME" = "" ] || [ -z "$SSHKEYNAME" ] ; then
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

            if [ -z $SSHKEYNAME ]; then
                echo "    . Key name not given, should we generate a sshkey name? press 'y'"
                read -n 1 answer
                if [ "$answer" = "y" ]; then
                    read -p '    . Please specify name of key you want to generate: ' SSHKEYNAME
                    read -p '    . Please specify email addr: ' EMAILADDR
                    KEYPATH="$HOME/.ssh/$SSHKEYNAME"
                    if [ -z $SSHKEYNAME ] || [ -z $EMAILADDR ] ; then
                        echo "[-] Please specify sshkeyname & emailaddr, cannot continue."
                        return 1
                    fi
                    ssh-keygen -t rsa -b 4096 -f $KEYPATH -C "$EMAILADDR"
                fi
            else
                if [ ! -f $KEYPATH ]; then
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