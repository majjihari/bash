


ZSSHTEST() {
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
ZEXEC() {
    local loc=0
    local OPTIND
    while getopts "lh" opt; do
        case $opt in
           l )  loc=1 ;;
           h )  ZEXECUsage ; return 0 ;;
        esac
    done

    #check that if RNODE is there RPORT needs to be there too

    if [ -z "$RNODE" ] && [ not "$RNODE" = "localhost" ] && [ not "$loc" = "1" ]; then
        ssh -A root@$RNODE -p $RPORT "$@" > $ZLogFile 2>&1 || die "could not ssh command: $@"
    else
        $@ > $ZLogFile 2>&1 || die "could not exec command: $@"
    fi
    ZNodeEnvSet

}

#interactive version
ZSSH() {
    ZNodeEnvSet
    ssh -A root@$RNODE -p $RPORT "$@" | tee $ZLogFile || die "could not ssh command: $@"
}

ZNodePortSet() {
    if [ ! -n "$1" ]; then
        read -p "port of node: " RPORT
    else
        RPORT=$1
    fi
    export RPORT
}

ZNodeSet() {
    if [ ! -n "$1" ]; then
        read -p "ipaddr or hostname of node: " RNODE
    else
        RNODE=$1
    fi
    export RNODE
}

ZNodeEnvSet() {
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
