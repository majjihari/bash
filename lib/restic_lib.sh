

ZResticBuild() {
    ZGetCode restic git@github.com:restic/restic.git
    go run build.go 2>&1 > $ZLogFile || die 'could not build restic'
    mv restic /usr/local/bin/ || die 'could not build restic'
    # rm -rf $ZCODEDIR/restic
    popd > /dev/null 2>&1
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
    #set params for ssh, test connection
    ZSSHTEST
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
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa init | tee $ZLogFile || die
    rm -f /tmp/sdwfa
}


ZResticBackup() {
    ZResticEnvSet
    local RSOURCE=$1
    local RTAG=$2
    touch $ZLogFile #to make sure we don't show other error
    echo $RPASSWD > /tmp/sdwfa
    # echo $RSOURCE
    if [ ! -e $RSOURCE ]; then
        die "Could not find sourcedir: $RSOURCE" && return 1
    fi
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa backup --tag $RTAG $RSOURCE  || die
    rm -f /tmp/sdwfa
}

ZResticCheck() {
    touch $ZLogFile #to make sure we don't show other error
    echo $RPASSWD > /tmp/sdwfa
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa  check 2>&1 | tee $ZLogFile || die
    rm -f /tmp/sdwfa
    echo "* CHECK OK"
}


ZResticSnapshots() {
    touch $ZLogFile #to make sure we don't show other error
    echo $RPASSWD > /tmp/sdwfa
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa  snapshots 2>&1 | tee $ZLogFile || die
    rm -f /tmp/sdwfa
}

ZResticMount() {
    touch $ZLogFile #to make sure we don't show other error
    mkdir -p ~/restic > $ZLogFile 2>&1  || die
    echo $RPASSWD > /tmp/sdwfa
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa  --allow-root mount ~/restic 2>&1 | tee $ZLogFile || die
    rm -f /tmp/sdwfa
    # pushd ~/restic > /dev/null 2>&1
    umount ~/restic 2>&1  /dev/null
}
