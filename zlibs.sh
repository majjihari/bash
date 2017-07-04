#!/bin/bash
set +x

export ZUTILSDIR=${ZUTILSDIR:-~/code/jumpscale}
export ZLogFile='/tmp/zutils.log'
export ZINTERACTIVE=1
echo 'Initialzing environement' > $ZLogFile

[[ $ZINTERACTIVE -eq 1 ]] && echo "[+] interactive interface enabled"

die() {
    echo "[-] something went wrong: $1"
    rm -f /tmp/sdwfa #to remove temp passwd for restic, just to be sure
    cat $ZLogFile
    exit
}

catcherror_handler() {
    if [ "${ZLogFile}" != "" ]; then
        echo "[-] line $1: script error, backlog from ${ZLogFile}:"
        cat ${ZLogFile}
        return 1
    fi

    echo "[-] line $1: script error, no logging file defined"
    return 1
}

catchfatal_handler() {
    if [ "${ZLogFile}" != "" ]; then
        echo "[-] script error, backlog from ${ZLogFile}:"
        cat ${ZLogFile}
        exit 1
    fi

    echo "[-] script error, no logging file defined"
    exit 1
}

catcherror() {
    trap 'catcherror_handler $LINENO' ERR
}

catchfatal() {
    trap 'catchfatal_handler $LINENO' ERR
}

catcherror

if [ ! -d "${ZUTILSDIR}/bash" ]; then
    echo "[-] ${ZUTILSDIR}/bash: directory not found"
    return
fi

pushd $ZUTILSDIR/bash > /dev/null 2>&1
. lib/code_lib.sh
. lib/config_lib.sh
. lib/docker_lib.sh
. lib/restic_lib.sh
. lib/ssh_lib.sh
. lib/installers.sh
. lib/tmux.sh
. lib/rsync.sh
. lib/lede.sh
popd > /dev/null 2>&1
