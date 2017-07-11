#!/bin/bash
# export ZBRANCH=${ZBRANCH:-master}
# export ZCODEDIR=${ZCODEDIR:-~/code}

export ZLogFile='/tmp/z.log'

die() {
    echo "ERROR"
    echo "[-] something went wrong: $1"
    rm -f /tmp/sdwfa #to remove temp passwd for restic, just to be sure
    cat $ZLogFile
    return 1
}


# #
# # Warning: this is bash specific
# #
# catcherror_handler() {
#     if [ "${ZLogFile}" != "" ]; then
#         echo "[-] line $1: script error, backlog from ${ZLogFile}:"
#         cat ${ZLogFile}
#         exit 1
#     fi
#
#     echo "[-] line $1: script error, no logging file defined"
#     exit 1
# }
#
# catcherror() {
#     trap 'catcherror_handler $LINENO' ERR
# }



ZTestUsage() {
   cat <<EOF
Usage: ZTest [-n $name] [-p $port]
   -n $name: name of container
   -p $port: port on which to install
   -h: help
EOF
}
set +x

ZTest() {
    local OPTIND
    local iname=''
    local port=''
    while getopts "n:p:h" opt; do
        case $opt in
           n )  iname=$OPTARG ;;
           p )  port=$OPTARG ;;
           h )  ZTestUsage ; return 0 ;;
           \? )  ZTestUsage ; return 1 ;;
        esac
    done
    if [ -z "$iname" ]; then ZTestUsage;return 0; fi
    if [ -z "$port" ]; then port=22; fi
    echo iname:$iname
    echo port:$port


}
