ZInstall_DMG() {
    VOLUME=`hdiutil attach $1 | grep Volumes | awk '{print $3}'`
    cp -rf $VOLUME/*.app /Applications
    hdiutil detach $VOLUME
}

IPFS_get() {
    mkdir -p /tmp/zdownloads
    pushd /tmp/zdownloads > /dev/null 2>&1

    ipfs get $1 -o $2 || die "could not ipfs download $2" || return 1

    popd
}


IPFS_get_install_dmg() {
    mkdir -p /tmp/zdownloads
    IPFS_get $1 $2.dmg || return 1
    pushd /tmp/zdownloads > /dev/null 2>&1
    VOLUME=`hdiutil attach $2.dmg | grep Volumes | awk '{print $3}'` || die || return 1
    cp -rf $VOLUME/*.app /Applications || die || return 1
    hdiutil detach $VOLUME || die || return 1
    popd
}

IPFS_get_mount_dmg() {
    mkdir -p /tmp/zdownloads
    pushd /tmp/zdownloads > /dev/null 2>&1
    IPFS_get $1 $2.dmg || die || return 1
    VOLUME=`hdiutil attach $2.dmg | grep Volumes | awk '{print $3}'` || die || return 1
    popd
}


#args: $hash $name $dest
#will use rsync to sync remotely
IPFS_get_dir(){
    mkdir -p /tmp/zdownloads || die || return 1
    pushd /tmp/zdownloads > /dev/null 2>&1
    ipfs get $1 -o $2 || die || return 1
    mkdir -p $3 || die || return 1
    rsync -rav  --delete-after  /tmp/zdownloads/$2/ $3/ || die || return 1

}
