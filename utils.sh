#!/bin/bash

set -x

export ZBRANCH=${ZBRANCH:-"master"}
export ZCODEDIR=${ZCODEDIR:-"~/code"}



# ------
# Functions definitions: here are useful functions we use
# ------
branchExists() {
    local repository="$1"
    local branch="$2"

    echo "* Checking if ${repository}/${ZBRANCH} exists"
    httpcode=$(curl -o /dev/null -I -s --write-out '%{http_code}\n' https://github.com/${repository}/tree/${ZBRANCH})

    if [ "$httpcode" = "200" ]; then
        return 0
    else
        return 1
    fi
}


dockerRemove(){
    echo "[+] remove docker $1"
    docker rm  -f "$1" || true
    # docker inspect $iname >  /dev/null 2>&1 &&  docker rm  -f "$iname" > /dev/null 2>&1
}

dockerRemoveImage(){
    echo "[+] remove docker image $1"
    docker rmi  -f "$1"  > ${logfile} 2>&1 || true
}


dockerRun() {
    local bname="$1"
    local iname="$2"
    local port="${3:-2222}"
    local addarg="${4:-}"

    #addarg: -p 10700-10800:10700-10800

    echo "[+] start docker $bname -> $iname (port:$port)"

    existing="$(docker ps -aq -f name=^/${iname}$)"

    if [[ ! -z "$existing" ]]; then
        dockerremove $iname
    fi

    mounted_volumes="\
        -v ${GIGDIR}/:/root/gig/ \
        -v ${GIGDIR}/code/:/opt/code/ \
        -v ${GIGDIR}/private/:/optvar/private \
        -v ${HOME}/.cache/pip/:/root/.cache/pip/ \
    "

    # mount optvar/data to all platforms except for windows to avoid fsync mongodb error
    # related: https://docs.mongodb.com/manual/administration/production-notes/#fsync-on-directories
    if ! grep -q Microsoft /proc/version; then
        mounted_volumes="$mounted_volumes \
            -v ${GIGDIR}/data/:/optvar/data \
        "
    fi

    docker run --name $iname \
        --hostname $iname \
        -d \
        -p ${port}:22 ${addarg} \
        --device=/dev/net/tun \
        --cap-add=NET_ADMIN --cap-add=SYS_ADMIN \
        --cap-add=DAC_OVERRIDE --cap-add=DAC_READ_SEARCH \
        ${mounted_volumes} \
        $bname > ${logfile} 2>&1 || die "docker could not start, please check ${logfile}"

    sleep 1

    ssh_authorize "${iname}"


}

ZGetCode() {
    mkdir -p $ZCODEDIR
    #giturl like: git@github.com:mathieuancelin/duplicates.git 
    local name="$1"    
    local giturl="$2"
    local branch=${3:-${ZBRANCH}}
    echo "* get code $giturl ($branch)"
    pushd $ZCODEDIR

    if ! grep -q ^github.com ~/.ssh/known_hosts 2> /dev/null; then
        ssh-keyscan github.com >> ~/.ssh/known_hosts 2>&1
    fi

    if [ ! -e $ZCODEDIR/$name ]; then    
        git clone -b ${branch} $giturl || return 1
    else
        pushd $ZCODEDIR/$name
        git pull || return 1
        popd
    fi
    popd
}

die() {
    echo "[-] something went wrong: $1"
    cat $logfile
    exit 1
}

# die and get docker log back to host
# $1 = docker container name, $2 = logfile name, $3 = optional message
dockerdie() {
    if [ "$3" != "" ]; then
        echo "[-] something went wrong in docker $1: $3"
        exit 1
    fi

    echo "[-] something went wrong in docker: $1"
    docker exec -t $iname cat "$2"

    exit 1
}

dockercommit() {
    echo "[+] Commit docker: $1"
    docker commit $1 jumpscale/$2 > ${logfile} 2>&1 || return 1
    if [ "$3" != "" ]; then
        dockerremove $1
    fi
}

ssh_authorize() {
    if [ "$1" = "" ]; then
        echo "[-] ssh_authorize: missing container target"
        return
    fi

    echo "[+] authorizing local ssh keys on docker: $1"
    SSHKEYS=$(ssh-add -L)
    docker exec -t "$1" /bin/sh -c "echo ${SSHKEYS} >> /root/.ssh/authorized_keys"
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

container() {
    catcherror
    ssh -A root@localhost -p ${port} "$@" > ${logfile} 2>&1
}


