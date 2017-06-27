


ZSSHTEST() {
    echo '' > $ZLogFile
    ZNodeEnvSet
    ssh root@$RNODE -p $RPORT 'ls /' > $ZLogFile 2>&1 || die "could not connect over ssh to $RNODE:$RPORT"
    #TODO: check and if not connect, ask the params again, till its all ok
}


ZEXECUsage() {
   cat <<EOF
Usage: ZEXEC [-l]
   -l: local execution even if a docker exists
   -h: help

executes a command local or over ssh (using variable RNODE & RPORT)

EOF
}
ZEXEC() {(
    echo '' > $ZLogFile
    local loc=0
    local OPTIND
    while getopts "lh" opt; do
        case $opt in
           l )  loc=1 ;;
           h )  ZEXECUsage ; return 0 ;;
        esac

        shift
    done

    if [ "$RNODE" != "" ] && [ "$RPORT" != "" ] && [ $loc -ne 1 ]; then
        ssh -A root@$RNODE -p $RPORT "$@" || die "could not ssh command: $@"

    else
        $@ || die "could not execute locally command: $@"
    fi

)}

#goal is to allow people to get into their container without thinking
ZSSH() {(
    echo '' > $ZLogFile
    ZNodeEnvSet
    if [ -n "$1" ]; then
        ssh -A root@$RNODE -p $RPORT "TERM=xterm;$@" || die "could not ssh command: $@"
    else
        ssh -A root@$RNODE -p $RPORT || die "could not ssh command: $@"
    fi

)}

js9() {(
    echo '' > $ZLogFile
    ZNodeEnvSet
    ssh -A root@$RNODE -p $RPORT TERM=xterm;js9 "$@" || die "could not ssh command: $@"

)}

ZNodeUbuntuPrepare() {
    ZNodeEnvSet
    ZSSH 'apt-get update;apt-get upgrade -y'
    ZDockerInstall
    ZSSHi
}



ZNodePortSet() {
    echo '' > $ZLogFile
    if [ ! -n "$1" ]; then
        read -p "port of node: " RPORT
    else
        RPORT=$1
    fi
    export RPORT
}

ZNodeSet() {
    echo '' > $ZLogFile
    if [ ! -n "$1" ]; then
        read -p "ipaddr or hostname of node: " RNODE
    else
        RNODE=$1
    fi
    export RNODE
}

ZNodeEnvSet() {
    echo '' > $ZLogFile
    export RPORT=${RPORT:-22}
    if [ ! -n "$RNODE" ]; then
        read -s -p "ssh node (ip addr or hostname): " RNODE
    fi
    export RNODE
}

ZNodeEnv() {
    echo "node          :  $RNODE"
    echo "sshport       :  $RPORT"
}
