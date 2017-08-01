

ZResticBuild() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    ZCodeGet restic git@github.com:restic/restic.git || return 1
    go run build.go 2>&1 > $ZLogFile || die 'could not build restic' || return 1
    mv restic /usr/local/bin/ || die 'could not build restic (move)' || return 1
    # rm -rf $ZCODEDIR/restic
    Z_popd || return 1
}

ZResticEnv() {
    # ZResticEnvSet
    echo "node          :  $RNODE"
    echo "sshport       :  $RPORT"
    echo "name          :  $RNAME"
    # echo "source        :  $RSOURCE"
    echo "destination   :  $RDEST"
    echo "passwd        :  $RPASSWD"
}

ZResticEnvSet() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    #set params for ssh, test connection
    ZSSHTEST || return 1
    if [ ! -n "$RNAME" ]; then
        read -p "name for backup: " RNAME
    fi
    # if [ ! -n "$RSOURCE" ]; then
    #     read -p "source of backup (what to backup): " RSOURCE
    #     if [ ! -e $RSOURCE ]; then
    #         die 'Could not find sourcedir: $RSOURCE'
    #     fi
    # fi
    if [ ! -n "$RDEST" ]; then
        read -p "generic backup dir on ssh host: " RDEST
    fi

    if [ ! -n "$RPASSWD" ]; then
        read -s -p "backuppasswd: " RPASSWD
    fi

    export RDEST
    export RNAME
    export RPASSWD
    export RSOURCE

}


ZResticEnvReset() {
    unset RNODE
    unset RNAME
    unset RSOURCE
    unset RDEST
    unset RDESTPORT
    unset RPASSWD
}

ZResticInit() {
    ZResticEnvSet
    echo $RPASSWD > /tmp/sdwfa
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa init | tee $ZLogFile || die || return 1
    rm -f /tmp/sdwfa
}


ZResticBackup() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    ZResticEnvSet || return 1
    local RSOURCE=$1
    local RTAG=$2
    touch $ZLogFile #to make sure we don't show other error
    echo $RPASSWD > /tmp/sdwfa
    # echo $RSOURCE
    if [ ! -e $RSOURCE ]; then
        die "Could not find sourcedir: $RSOURCE" || return 1
    fi
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa backup --tag $RTAG $RSOURCE  || die || return 1
    rm -f /tmp/sdwfa
}

ZResticCheck() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    touch $ZLogFile #to make sure we don't show other error
    echo $RPASSWD > /tmp/sdwfa
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa  check 2>&1 | tee $ZLogFile || die || return 1
    rm -f /tmp/sdwfa
    echo "* CHECK OK"
}


ZResticSnapshots() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    touch $ZLogFile #to make sure we don't show other error
    echo $RPASSWD > /tmp/sdwfa
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa  snapshots 2>&1 | tee $ZLogFile || die || return 1
    rm -f /tmp/sdwfa
}

ZResticMount() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    touch $ZLogFile #to make sure we don't show other error
    mkdir -p ~/restic > $ZLogFile 2>&1  || die || return 1
    echo $RPASSWD > /tmp/sdwfa
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa  --allow-root mount ~/restic 2>&1 | tee $ZLogFile || die || return 1
    rm -f /tmp/sdwfa
    # Z_pushd ~/restic || return 1
    umount ~/restic 2>&1  /dev/null
}
