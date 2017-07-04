


ZSSHTEST() {
    echo '' > $ZLogFile
    ZNodeEnvSet
    ssh root@$RNODE -p $RPORT 'ls /' > $ZLogFile 2>&1 || die "could not connect over ssh to $RNODE:$RPORT"
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
    echo '' > $ZLogFile
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
        esac

        shift
    done
    set -x
    if [ "$raddress" != "" ] ; then
        ssh -R $rport:$laddress:$lport $user@$raddress || die "could not to remote portforward: $@"
    else
        die "could not forward remote port to local, check syntax: $@"
    fi

)}




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
        ssh -A root@$RNODE -p $RPORT "bash . ~/code/jumpscale/bash/zlibs.sh"|| die "could not ssh command: $@"
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
    ZSSH "curl https://raw.githubusercontent.com/Jumpscale/bash/master/install.sh?$RANDOM > /tmp/install.sh;sh /tmp/install.sh"
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
        read -p "ssh node (ip addr or hostname): " RNODE
    fi
    export RNODE
}

ZNodeEnv() {
    echo "node          :  $RNODE"
    echo "sshport       :  $RPORT"
}
