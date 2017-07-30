ZInstall_DMG() {
    VOLUME=`hdiutil attach $1 | grep Volumes | awk '{print $3}'` > ${ZLogFile} 2>&1  || die || return 1
    cp -rf $VOLUME/*.app /Applications > ${ZLogFile} 2>&1  || die || return 1
    hdiutil detach $VOLUME > ${ZLogFile} 2>&1 
}

IPFS_get() {
    mkdir -p /tmp/zdownloads
    pushd /tmp/zdownloads > /dev/null 2>&1

    ipfs get $1 -o $2 > ${ZLogFile} 2>&1 || die "could not ipfs download $2" || return 1

    popd > /dev/null 2>&1
}


IPFS_get_install_dmg() {
    mkdir -p /tmp/zdownloads
    IPFS_get $1 $2.dmg || return 1
    pushd /tmp/zdownloads > /dev/null 2>&1
    VOLUME=`hdiutil attach $2.dmg | grep Volumes | awk '{print $3}'` > ${ZLogFile} 2>&1 || die || return 1
    cp -rf $VOLUME/*.app /Applications > ${ZLogFile} 2>&1 || die || return 1
    hdiutil detach $VOLUME > ${ZLogFile} 2>&1
    popd > /dev/null 2>&1
}

IPFS_get_mount_dmg() {
    mkdir -p /tmp/zdownloads
    pushd /tmp/zdownloads > /dev/null 2>&1
    IPFS_get $1 $2.dmg || die || return 1
    VOLUME=`hdiutil attach $2.dmg | grep Volumes | awk '{print $3}'`  > ${ZLogFile} 2>&1 || die || return 1
    popd > /dev/null 2>&1
}


#args: $hash $name $dest
#will use rsync to sync remotely
IPFS_get_dir(){
    mkdir -p /tmp/zdownloads || die || return 1
    pushd /tmp/zdownloads > /dev/null 2>&1
    ipfs get $1 -o $2  > ${ZLogFile} 2>&1 || die || return 1
    mkdir -p $3  > ${ZLogFile} 2>&1 || die || return 1
    rsync -rav  --delete-after  /tmp/zdownloads/$2/ $3/  > ${ZLogFile} 2>&1 || die || return 1
    popd > /dev/null 2>&1

}
