

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
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile
    local RPORT=${RPORT:-22}
    local OPTIND
    local all=0
    local rsource=""
    local rdest=""
    # local rexclude=--exclude='.git/' --exclude='*.pyc'

    while getopts "s:d:ah" opt; do
        case $opt in
           s  ) rsource=$OPTARG ;;
           d  ) rdest=$OPTARG ;;
           a  ) all=1 ;;
           h  ) RSyncToUsage ; return 0 ;;
           \? )  RSyncToUsage ; return 0 ;;
        esac
    done

    if [ "$RNODE" == "localhost" ] ; then
        die "RSyncTo only meant to be used when RNODE is not a local docker" || return 1
    fi

    if [ "$RNODE" == "" ] ; then
        die "RNode not specified" || return 1
    fi

    if [ "$RPORT" == "" ] ; then
        die "RPORT not specified" || return 1
    fi    

    if [ "$rdest" != "" ] ; then
        ZEXEC -c "mkdir -p $rdest" >> $ZLogFile 2>&1 || die "could not mkdir $rdest as part of rsync: $@" || return 1
    fi

    if [ "$rsource" != "" ] && [ "$rdest" != "" ] ; then
        if [ $all -eq 1 ] ; then
            rsync -rav -e "ssh -p $RPORT" "$rsource" root@$RNODE:$rdest >> $ZLogFile 2>&1 || die "could not rsync: $@" || return 1
        else
            n=0
            until [ $n -ge 10 ]
            do
                rsync --progress -rav --exclude='.git/' --exclude='*.pyc' -e "ssh -p $RPORT" "$rsource" root@$RNODE:$rdest && break  
                n=$[$n+1]
            done
            return $?
        fi
        die "could not rsync to node: $rdest of '$rsource'" || return 1
    else
        $@ || die "could not rsync to node, check syntax: $@"
    fi

)}



RSync_ZTools() {(
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile
    if [ "$RNODE" == "localhost" ] ; then
        return 0
    fi
    RSyncTo  -s "$ZUTILSDIR/bash/" -d "/opt/code/github/jumpscale/bash/" || return 1
)}

RSync() {
    Z_exists_dir "$1" || return 1
    Z_mkdir "$2" || return 1
    rsync -rav  --exclude='.git/' --exclude='*.pyc' --delete-after  "$1" "$2"  >> ${ZLogFile} 2>&1 || die "rsync $1 $2" || return 1
}

RSync_move() {
    RSync "$1" "$2" || return 1
    rm -rf "$1"
}