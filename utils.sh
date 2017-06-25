#!/bin/bash
set -x

#. ~/code/varia/bash/utils.sh



# unset ZCODEDIR
# unset ZBRANCH


export ZBRANCH=${ZBRANCH:-master}
export ZCODEDIR=${ZCODEDIR:-~/code}
export logfile='/tmp/z.log'

#########CONFIG

ZCONFIG() {
    export CONTAINERDIR=~/gig
    mkdir -p ${CONTAINERDIR}/code
    mkdir -p ${CONTAINERDIR}/private
    mkdir -p ${CONTAINERDIR}/.cache/pip
}

#########ZNODE

ZSSHTEST() {
    ZNodeEnvSet
    ssh root@$RNODE -p $RPORT 'ls /' > $logfile 2>&1 || die "could not connect over ssh to $RNODE:$RPORT"
    #TODO: check and if not connect, ask the params again, till its all ok
}

ZSSH() {
    ZNodeEnvSet
    ssh root@$RNODE -p $RPORT "$@" > $logfile 2>&1 || die "could not ssh command: $@"
}

#interactive version
ZSSHi() {
    ZNodeEnvSet
    ssh root@$RNODE -p $RPORT "$@" | tee $logfile || die "could not ssh command: $@"
}

ZNodePortSet() {
    if [ ! -n "$1" ]; then
        read -p "port of node: " RPORT
    else
        RPORT=$1
    fi
    export RPORT
}

ZNodeSet() {
    if [ ! -n "$1" ]; then
        read -p "ipaddr or hostname of node: " RNODE
    else
        RNODE=$1
    fi
    export RNODE
}

ZNodeEnvSet() {
    export RPORT=${RPORT:-22}
    if [ ! -n "$RNODE" ]; then
        read -s -p "ssh node (ip addr or hostname): " RNODE
    fi
    export RNODE
}

ZNodeEnv() {
    echo "node          :  $RNODE"
    echo "sshport       :  $RPORT"
}

#########RESTIC

ZResticBuild() {
    ZGetCode restic git@github.com:restic/restic.git
    go run build.go 2>&1 > $logfile || die 'could not build restic'
    mv restic /usr/local/bin/ || die 'could not build restic'
    # rm -rf $ZCODEDIR/restic
    popd
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
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa init | tee $logfile || die
    rm -f /tmp/sdwfa
}


ZResticBackup() {
    ZResticEnvSet
    local RSOURCE=$1
    local RTAG=$2
    touch $logfile #to make sure we don't show other error
    echo $RPASSWD > /tmp/sdwfa
    echo $RSOURCE
    if [ ! -e $RSOURCE ]; then
        die "Could not find sourcedir: $RSOURCE" && return 1
    fi
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa backup --tag $RTAG $RSOURCE  || die
    rm -f /tmp/sdwfa
}

ZResticCheck() {
    touch $logfile #to make sure we don't show other error
    echo $RPASSWD > /tmp/sdwfa
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa  check 2>&1 | tee $logfile || die
    rm -f /tmp/sdwfa
    echo "* CHECK OK"
}


ZResticSnapshots() {
    touch $logfile #to make sure we don't show other error
    echo $RPASSWD > /tmp/sdwfa
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa  snapshots 2>&1 | tee $logfile || die
    rm -f /tmp/sdwfa
}

ZResticMount() {
    touch $logfile #to make sure we don't show other error
    mkdir -p ~/restic > $logfile 2>&1  || die
    echo $RPASSWD > /tmp/sdwfa
    restic -r sftp:root@$RNODE:$RDEST/$RNAME -p /tmp/sdwfa  --allow-root mount ~/restic 2>&1 | tee $logfile || die
    rm -f /tmp/sdwfa
    # pushd ~/restic
    umount ~/restic 2>&1  /dev/null
}


############ CODE

#to return to original dir do pushd
ZGetCode() {
    mkdir -p $ZCODEDIR
    #giturl like: git@github.com:mathieuancelin/duplicates.git
    local name="$1"
    local giturl="$2"
    local branch=${3:-${ZBRANCH}}
    echo "* get code $giturl ($branch)"
    pushd $ZCODEDIR

    if ! grep -q ^github.com ~/.ssh/known_hosts 2> /dev/null; then
        ssh-keyscan github.com >> ~/.ssh/known_hosts 2>&1 > $logfile || die
    fi

    if [ ! -e $ZCODEDIR/$name ]; then
        echo " * clone"
        git clone -b ${branch} $giturl $name 2>&1 > $logfile || die
    else
        pushd $ZCODEDIR/$name
        echo " * pull"
        git pull  2>&1 > $logfile || die
        popd
    fi
    popd
    pushd $ZCODEDIR/$name
}


ZBranchExists() {
    local giturl="$1"
    local branch=${2:-${ZBRANCH}}

    echo "* Checking if ${repository}/${ZBRANCH} exists"
    httpcode=$(curl -o /dev/null -I -s --write-out '%{http_code}\n' $giturl/tree/${branch})

    if [ "$httpcode" = "200" ]; then
        return 0
    else
        return 1
    fi
}

######### GOLANG

######### DOCKER

container() {
    ZCONFIG
    ssh -A root@localhost -p $RPORT "$@" > ${logfile} 2>&1 | tee > $logfile 2>&1 || die "ssh error"
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

ZDockerEnableSSH(){

    echo "[+]   configuring services"
    docker exec -t $ZDockerName mkdir -p /var/run/sshd
    docker exec -t $ZDockerName  rm -f /etc/service/sshd/down
    #
    echo "[+]   regen ssh keys"
    docker exec -t $ZDockerName  rm -f /etc/service/sshd/down
    docker exec -t $ZDockerName  /etc/my_init.d/00_regen_ssh_host_keys.sh
    #
    echo "[+]   start ssh"
    docker exec -t $ZDockerName  sv start sshd > ${logfile} 2>&1

    echo "[+]   Waiting for ssh to allow connections"
    while ! ssh-keyscan -p $RPORT localhost 2>&1 | grep -q "OpenSSH"; do
        sleep 0.2
    done

    echo "[+]   remove machine from localhost"
    sed -i.bak /localhost.:$RPORT/d ~/.ssh/known_hosts
    rm -f ~/.ssh/known_hosts.bak
    ssh-keyscan -p $RPORT localhost 2>&1 | grep -v '^#' >> ~/.ssh/known_hosts

    ssh_authorize $ZDockerName

    container 'echo export "LC_ALL=C.UTF-8" >> /root/.profile'
    container 'echo "export LANG=C.UTF-8" >> /root/.profile'


}

ZDockerRemove(){
    ZCONFIG
    echo "[+] remove docker $1"
    docker rm  -f "$1" || true
    # docker inspect $iname >  /dev/null 2>&1 &&  docker rm  -f "$iname" > /dev/null 2>&1
}

ZDockerRemoveImage(){
    ZCONFIG
    echo "[+] remove docker image $1"
    docker rmi  -f "$1"  > ${logfile} 2>&1 || true
}

ZDockerRunUbuntu() {
    ZCONFIG
    local bname="phusion/baseimage"
    local iname="${1:-ubuntu}"
    local port="${2:-2222}"
    local addarg="${3:-}"
    ZDockerRun $bname $iname $port $addarg || return 1

    #basic deps
    docker exec -t $ZDockerName apt update
    docker exec -t $ZDockerName apt upgrade -y
    docker exec -t $ZDockerName apt install curl mc openssh-server git net-tools iproute2 tmux localehelper psmisc telnet -y

    ZDockerEnableSSH
}

ZDockerRun() {
    ZCONFIG
    local bname="$1"
    local iname="$2"
    local port="${3:-2222}"
    local addarg="${4:-}"
    ZNodePortSet $port
    ZNodeSet localhost
    export ZDockerName=$iname

    #addarg: -p 10700-10800:10700-10800

    echo "[+] start docker $bname -> $iname (port:$port)"

    existing="$(docker ps -aq -f name=^/${iname}$)"

    if [[ ! -z "$existing" ]]; then
        ZDockerRemove $iname
    fi

    mounted_volumes="\
        -v ${CONTAINERDIR}/:/root/host/ \
        -v ${CONTAINERDIR}/code/:/opt/code/ \
        -v ${CONTAINERDIR}/private/:/optvar/private \
        -v ${CONTAINERDIR}/.cache/pip/:/root/.cache/pip/ \
    "

    # mount optvar/data to all platforms except for windows to avoid fsync mongodb error
    # related: https://docs.mongodb.com/manual/administration/production-notes/#fsync-on-directories
    # if ! grep -q Microsoft /proc/version; then
    #     mounted_volumes="$mounted_volumes \
    #         -v ${CONTAINERDIR}/data/:/optvar/data \
    #     "
    # fi

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

    # ssh_authorize "${iname}"


}

######### VARIA

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
