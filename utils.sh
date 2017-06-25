#!/bin/bash
set -x

#. ~/code/varia/bash/utils.sh



# unset ZCODEDIR
# unset ZBRANCH


export ZBRANCH=${ZBRANCH:-master}
export ZCODEDIR=${ZCODEDIR:-~/code}
export logfile='/tmp/z.log'

die() {
    echo "ERROR"
    echo "[-] something went wrong: $1"
    rm -f /tmp/sdwfa #to remove temp passwd for restic, just to be sure
    cat $logfile
    return 1
    # exit 1
}


#
# Warning: this is bash specific
#
catcherror_handler() {
    if [ "${logfile}" != "" ]; then
        echo "[-] line $1: script error, backlog from ${logfile}:"
        cat ${logfile}
        exit 1
    fi

    echo "[-] line $1: script error, no logging file defined"
    exit 1
}

catcherror() {
    trap 'catcherror_handler $LINENO' ERR
}
