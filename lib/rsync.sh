

RSyncToUsage() {
   cat <<EOF
Usage: RSync [-ah]
   -s: source
   -d: destination on the remote node
   -a: sync all do not do the std excludes of git, pyc, ...
   -h: help

Does RSYNC over ssh from local machine to the remote machine

EOF
}

RSyncTo() {(
    echo '' > $ZLogFile
    set -x
    local OPTIND
    local all=0
    local rsource=""
    local rdest=""
    local rexclude=--exclude='.git/' --exclude='*.pyc'
    ZNodeEnvSet
    while getopts "s:d:ah" opt; do
        case $opt in
           s  ) rsource=$OPTARG ;;
           d  ) rdest=$OPTARG ;;
           a  ) all=1 ;;
           h  ) RSyncToUsage ; return 0 ;;
           \? )  RSyncToUsage ; return 0 ;;
        esac
    done
    if [ "$rsource" != "" ] && [ "$rdest" != "" ] ; then
        if [ $all -eq 1 ] ; then
            rexclude=""
        fi
        rsync -rav -e "ssh -p $RPORT" $rexclude $rsource root@$RNODE:$rdest || die "could not rsync: $@"

    else
        $@ || die "could not rsync to node, check syntax: $@"
    fi

)}



RSync_bash() {(
    echo '' > $ZLogFile
    # ZEXEC 'mkdir -p /root/code/jumpscale/bash && rm -rf /root/code/'
    set -x
    RSyncTo  -s "$ZUTILSDIR/bash/" -d "/root/code/jumpscale/bash/"
)}
