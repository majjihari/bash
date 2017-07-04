

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
    local OPTIND
    local all=0
    local rsource=""
    local rdest=""
    # local rexclude=--exclude='.git/' --exclude='*.pyc'

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

    if [ "$rdest" != "" ] ; then
        ZEXEC "mkdir -p $rdest" || die "could not mkdir $rdest as part of rsync: $@" && return 1
    fi

    if [ "$rsource" != "" ] && [ "$rdest" != "" ] ; then
        if [ $all -eq 1 ] ; then
            rsync -rav -e "ssh -p $RPORT" $rsource root@$RNODE:$rdest > $ZLogFile 2>&1 || die "could not rsync: $@" && return 1
        else
            rsync -rav --exclude='.git/' --exclude='*.pyc' -e "ssh -p $RPORT" $rsource root@$RNODE:$rdest > $ZLogFile 2>&1 || die "could not rsync: $@" && return 1
        fi


    else
        $@ || die "could not rsync to node, check syntax: $@"
    fi

)}



RSync_bash() {(
    echo '' > $ZLogFile
    RSyncTo  -s "$ZUTILSDIR/bash/" -d "/root/code/jumpscale/bash/"
)}
