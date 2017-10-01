#!/usr/bin/env bash

######### DOCKER

ZDockerInstallSSH(){
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile
    echo "[+] install docker on remote machine."
    ZEXEC -c "wget -qO- https://get.docker.com/ | sh" || return 1

}

ZDockerInstallLocal(){
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile
    if [ "$(uname)" == "Darwin" ]; then
        echo "[?] Make sure docker has been installed on OSX"
        return 0
    fi
    echo "[+] install docker on local machine."
    wget -qO- https://get.docker.com/ | sh >> ${ZLogFile} 2>&1 || die "could not install docker" || return 1

}


container() {
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile

    ZDockerConfig || return 1

    if [ ! "$RNODE" = 'localhost' ]; then
        die "rnode needs to be localhost" || return 1
        return 1
    fi

    if [[ -z "$RPORT" ]]; then
        die "rnode port to exist" || return 1
        return 1
    fi

    ssh -A root@$RNODE -p $RPORT "$@" 2>&1 >> $ZLogFile || die "could not ssh command: $@" || return 1

}

ZDockerConfig() {
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile
    if [ -e ~/.iscontainer ] ; then echo "Docker tools cannot be run in container" ; return 0 ; fi
    ZNodeEnvDefaults || return 1
    ZCodeConfig || return 1
    export ZDockerName=${ZDockerName:-"build"}
    export CONTAINERDIR=~/js9host/
    Z_mkdir ${CONTAINERDIR}/.cache/pip || return 1
    Z_mkdir ${CONTAINERDIR}/cfg || return 1
}

ZDockerCommitUsage() {
   cat <<EOF
Usage: ZDockerCommit [-b $bname] [-i $iname] [-p port]
   -b  bname: name of base image to commit to e.g. jumpscale/ub1704
   -i  iname: name of docker which needs to be committed, will default be global arg ZDockerName
   -s: stop active docker
   -h: help
EOF
}

ZDockerCommit() {
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile

    ZDockerConfig
    local OPTIND
    local bname=''
    local iname=$ZDockerName
    local stop=0
    while getopts "b:i:hs" opt; do
        case $opt in
           b )  bname=$OPTARG ;;
           i )  iname=$OPTARG ;;
           s )  stop=1 ;;
           h )  ZDockerCommitUsage ; return 0 ;;
           \? )  ZDockerCommitUsage ; return 1 ;;
        esac
    done
    if [ -z "$bname" ]; then ZDockerCommitUsage;return 0; fi
    echo "[+] Commit docker: $iname to $bname"
    docker commit $iname $bname || "cannot docker commit $iname $bname" || return 1
    export ZDockerImage=$bname
    if [ "$stop" == "1" ]; then
        ZDockerRemove $iname
    fi
}

ZDockerSSHAuthorize() {
    if [ -e ~/.iscontainer ] ; then echo "Docker tools cannot be run in container" ; return 0 ; fi
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile

    local ZDockerName="${1:-$ZDockerName}"
    local RPORT="${RPORT:-2222}"
    echo "[+] authorizing local ssh keys on docker: $ZDockerName"

    echo "[+]   start ssh"
    docker exec -t "${ZDockerName}" rm -f /etc/service/sshd/down
    docker exec -t "${ZDockerName}" /etc/my_init.d/00_regen_ssh_host_keys.sh
    docker exec -t "${ZDockerName}" sv start sshd >> ${ZLogFile} 2>&1

    echo "[+]   Waiting for ssh to allow connections"
    while ! ssh-keyscan -p $RPORT localhost 2>&1 | grep -q "OpenSSH"; do
        sleep 0.2
    done

    sed -i.bak /localhost.:$RPORT/d ~/.ssh/known_hosts
    rm -f ~/.ssh/known_hosts.bak
    ssh-keyscan -p $RPORT localhost 2>&1 | grep -v '^#' >> ~/.ssh/known_hosts

    # authorizing keys
    ssh-add -L | while read key; do
        docker exec -t "${ZDockerName}" /bin/sh -c "echo $key >> /root/.ssh/authorized_keys"
    done

    ZNodeSet 'localhost'
    ZNodePortSet $RPORT

    echo "[+] SSH authorized"
}

ZDockerEnableSSH(){

    export ZDockerName="${1:-build}"

    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile

    local ZDockerName="${1:-$ZDockerName}"

    echo "[+]   configuring services"
    docker exec -t $ZDockerName mkdir -p /var/run/sshd >> ${ZLogFile} 2>&1 || die || return 1
    docker exec -t $ZDockerName  rm -f /etc/service/sshd/down
    docker exec -t $ZDockerName  /etc/my_init.d/00_regen_ssh_host_keys.sh
    #

    ZDockerSSHAuthorize $ZDockerName || return 1

    container 'echo export "LC_ALL=C.UTF-8" >> /root/.profile' || return 1
    container 'echo "export LANG=C.UTF-8" >> /root/.profile' || return 1

    echo "[+] SSH enabled OK"

}

ZDockerRemove(){
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile

    ZDockerConfig
    local ZDockerName="${1:-$ZDockerName}"
    echo "[+] remove docker $ZDockerName"
    docker rm  -f "$ZDockerName" || true
}

ZDockerRemoveImage(){
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile
    ZDockerConfig
    local ZDockerImage="${1:-$ZDockerImage}"
    echo "[+] remove docker image $ZDockerImage"
    docker rmi  -f "$ZDockerImage"  >> ${ZLogFile} 2>&1 || true
}

ZDockerRemoveImagesAll(){
    docker stop $(docker ps -a -q) 2>&1 > /dev/null
    docker rm $(docker ps -a -q) 2>&1 > /dev/null
    docker rmi -f $(docker images -a -q) 2>&1 > /dev/null
    docker rmi -f $(docker images -f dangling=true -q) 2>&1 > /dev/null
}

ZDockerBuildUbuntu() {

    local OPTIND
    local force=0

    while getopts "f" opt; do
        case $opt in
           f )  force=1 ;;
        esac
    done

    if [ $force -eq 0 ] && ZDoneCheck "ZDocker_BuildUbuntu" && ZDockerImageExist "jumpscale/ubuntu" ; then
        echo "[+] no need to build ubuntu, already done"
        return 0
    fi
    ZDoneReset #reset all done state, need to restart from scratch

    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile

    ZDockerConfig || die || return
    local OPTIND
    local bname='phusion/baseimage'
    local iname='build'
    local port=2222
    local addarg=''
    while getopts "b:i:p:a:h" opt; do
        case $opt in
           b )  bname=$OPTARG ;;
           i )  iname=$OPTARG ;;
           p )  port=$OPTARG ;;
           a )  addarg=$OPTARG ;;
           h )  ZDockerRunUsage ; return 0 ;;
           \? )  ZDockerRunUsage ; return 1 ;;
        esac
    done

    export SSHNOAUTH=1

    if [[ ! -z "$addarg" ]]; then
        ZDockerRun -b $bname -i $iname -p $port -a $addarg || return 1
    else
        ZDockerRun -b $bname -i $iname -p $port || return 1
    fi

    unset SSHNOAUTH

    #basic deps
    echo "[+] apt update"
    docker exec -t $ZDockerName apt-get update >> ${ZLogFile} 2>&1 || die "apt-get update"  || return 1
    echo "[+] apt upgrade"
    docker exec -t $ZDockerName apt-get upgrade -y >> ${ZLogFile} 2>&1 || die "apt-get upgrade" || return 1
    echo "[+] setting up basic tools (aptget install)"
    docker exec -t $ZDockerName apt-get install curl mc openssh-server git net-tools iproute2 tmux localehelper psmisc telnet rsync sudo -y >> ${ZLogFile} 2>&1 || die "basic linux deps" || return 1

    ZDockerEnableSSH || return 1

    echo "[+] setting up default environment"
    container 'echo "" > /etc/motd' || return 1
    container 'touch /root/.iscontainer' || return 1

    ZDockerCommit -b jumpscale/ubuntu -s || return 1

    echo "[+] DOCKER UBUNTU OK"

    ZDoneSet "ZDocker_BuildUbuntu"
}

ZDockerRunSomethingUsage() {
   cat <<EOF
Usage: ZDockerRun... [-i $iname] [-p port]
   -i iname: name of docker which will be spawned, default to 'build'
   -p port: ssh port for docker defaults to 2222
   -a addarg: is additional arguments for docker e.g. -p 10700-10800:10700-10800
   -h: help

EOF
}

ZDockerRunUbuntu() {
    if [ -e ~/.iscontainer ] ; then echo "Docker tools cannot be run in container" ; return 0 ; fi

    ZDockerBuildUbuntu || die "could not build ubuntu." || return 1

    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile

    local OPTIND
    local bname='jumpscale/ubuntu'
    local iname='build'
    local port=2222
    local addarg=''

    while getopts "i:p:a:h" opt; do
        case $opt in
           i )  iname=$OPTARG ;;
           p )  port=$OPTARG ;;
           a )  addarg=$OPTARG ;;
           h )  ZDockerRunSomethingUsage ; return 0 ;;
           \? )  ZDockerRunSomethingUsage ; return 1 ;;
        esac
    done

    existing="$(docker images ${bname} -q)"

    if [[ -z "$existing" ]]; then
        ZDockerBuildUbuntu -f || return 1
    fi

    if [[ ! -z "$addarg" ]]; then
        ZDockerRun -b $bname -i $iname -p $port -a $addarg || return 1
    else
        ZDockerRun -b $bname -i $iname -p $port || return 1
    fi

    echo '[+] Ubuntu Docker Is Active (OK)'

}


ZDockerRunUsage() {
   cat <<EOF
Usage: ZDockerRun [-b $bname] [-i $iname] [-p port]
   -b bname: name of base image, defaults to jumpscale/js9
   -i iname: name of docker which will be spawned, default to 'default'
   -p port: ssh port for docker defaults to 2223
   -a addarg: is additional arguments for docker e.g. -p 10700-10800:10700-10800
   -h: help

EOF
}

ZDockerRun() {
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile

    mkdir -p ${HOME}/.cfg/

    ZDockerConfig || return 1
    local OPTIND
    local bname='jumpscale/js9'
    local iname='default'
    local port=2223
    local addarg=''
    while getopts "b:i:p:a:h" opt; do
        case $opt in
           b )  bname=$OPTARG ;;
           i )  iname=$OPTARG ;;
           p )  port=$OPTARG ;;
           a )  addarg=$OPTARG ;;
           h )  ZDockerRunUsage ; return 0 ;;
           \? )  ZDockerRunUsage ; return 1 ;;
        esac
    done
    ZNodePortSet $port || return 1
    ZNodeSet localhost || return 1
    export ZDockerName=$iname

    echo "[+] start docker $bname -> $iname (port:$port)"

    existing="$(docker ps -aq -f name=^/${iname}$)" || return 1

    if [[ ! -z "$existing" ]]; then
        ZDockerRemove $iname || return 1
    fi

    mounted_volumes="\
        -v ${CONTAINERDIR}/:/host \
        -v ${ZCODEDIR}/:/opt/code \
        -v ${CONTAINERDIR}/cfg:/hostcfg \
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
        $bname >> ${ZLogFile} 2>&1 || die "docker could not start, please check ${ZLogFile}" || return 1

    sleep 1

    #only authorize when var not set
    if [[ -z "$SSHNOAUTH" ]]; then
        ZDockerSSHAuthorize || return 1
    fi



}

ZDockerActiveUsage() {
   cat <<EOF
Usage: ZDockerRun [-b $bname] [-c command] [-i $iname] [-p port]
   -b bname: name of base image, defaults to jumpscale/js9 (which is jumpscale sandbox)
   -c cmd: name of command to execute when bname not found as image on docker
   -i iname: name of docker which will be spawned, default to 'build'
   -p port: ssh port for docker defaults to 2222
   -a addarg: is additional arguments for docker e.g. -p 10700-10800:10700-10800
   -h: help

will see if that docker is alreay up & if yes will use that docker if not will create it

EOF
}

ZDockerActive() {
    echo FUNCTION: ${FUNCNAME[0]} >> $ZLogFile

    if [ ! `which docker` ]; then
        ZDockerInstallLocal || die "Failed to install docker" || return 1
    fi

    ZDockerConfig || return 1

    local OPTIND
    local bname='jumpscale/js9'
    local iname='build'
    local port=2222
    local addarg=''
    local cmd=''
    while getopts "b:c:i:p:a:h" opt; do
        case $opt in
           b )  bname=$OPTARG ;;
           c )  cmd=$OPTARG ;;
           i )  iname=$OPTARG ;;
           p )  port=$OPTARG ;;
           a )  addarg=$OPTARG ;;
           h )  ZDockerActiveUsage ; return 0 ;;
           \? )  ZDockerActiveUsage ; return 1 ;;
        esac
    done

    if ! ZDockerImageExist "$bname " ; then
        #means docker image does not exist yet
        if [ ! "$cmd" = "" ]; then
            echo "[+] need to build the docker with command: $cmd"
            `$cmd`
        else
            ZDockerRemove $iname 2>&1 > /dev/null
            return 1
        fi
    fi

    # container "ls /"
    local res=`docker inspect -f '{{.State.Running}}' $iname`
    if [ ! "$res" = "true" ]; then
        #so is not up & running
        echo "[+] docker from image $bname is not active, will try to start"
        if [[ ! -z "$addarg" ]]; then
            ZDockerRun -b "$bname" -i "$iname" -p "$port" -a "$addarg" || return 1
        else
            ZDockerRun -b "$bname" -i "$iname" -p $port || return 1
        fi
        echo "[+] docker from image $bname is active, access it through 'ZSSH'"
        return 0
    fi

    return 1



}

ZDockerRemove(){
    docker stop $1 > /dev/null 2>&1
    docker rm -f $1 > /dev/null  2>&1
}

ZDockerImageExist() {
    docker images | grep "$1 "> /dev/null 2>&1
    if [ !  $? -eq 0 ]; then
        #means docker image does not exist yet
        return 1
    fi
    return 0
}
