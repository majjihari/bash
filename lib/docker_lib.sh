
######### DOCKER

ZDockerInstall(){
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    catcherror
    echo "[+] install docker on remote machine."
    ssh -A root@$RNODE -p $RPORT "wget -qO- https://get.docker.com/ | sh" > ${ZLogFile} 2>&1 || die "could install docker"

}

container() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    catcherror

    ZDockerConfig
    if [ "$RNODE" = '' ]; then
        die "rnode cannot be empty"
        return 1
    fi
    if [ ! "$RNODE" = 'localhost' ]; then
        die "rnode needs to be localhost"
        return 1
    fi

    if [[ -z "$RPORT" ]]; then
        die "rnode port to exist"
        return 1
    fi

    ssh root@$RNODE -p $RPORT "$@" > $ZLogFile 2>&1 || die "could not ssh command: $@" || return 1
    ssh -A root@localhost -p $RPORT "$@" > ${ZLogFile} 2>&1 || die "could not ssh command: $@" || return 1
}

# die and get docker log back to host
# $1 = docker container name, $2 = ZLogFile name, $3 = optional message
dockerdie() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    if [ "$3" != "" ]; then
        echo "[-] something went wrong in docker $1: $3"
        exit 1
    fi

    echo "[-] something went wrong in docker: $1"
    docker exec -t $iname cat "$2"

    exit 1
}

ZDockerConfig() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    catcherror
    ZCodeConfig
    export CONTAINERDIR=~/docker
    mkdir -p ${CONTAINERDIR}/private
    mkdir -p ${CONTAINERDIR}/.cache/pip
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
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    catcherror

    ZDockerConfig
    local OPTIND
    local bname=''
    local iname=$ZDockerName
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
    docker commit $iname $bname > ${ZLogFile} 2>&1 || return 1
    export ZDockerImage=$bname
    if [ "$stop" == "1" ]; then
        ZDockerRemove $iname
    fi
}

ZDockerSSHAuthorize() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    catcherror

    local ZDockerName="${1:-$ZDockerName}"
    echo "[+] authorizing local ssh keys on docker: $ZDockerName"

    echo "[+]   start ssh"
    docker exec -t "${ZDockerName}" rm -f /etc/service/sshd/down
    docker exec -t "${ZDockerName}" /etc/my_init.d/00_regen_ssh_host_keys.sh
    docker exec -t "${ZDockerName}" sv start sshd > ${ZLogFile} 2>&1

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
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    catcherror

    local ZDockerName="${1:-$ZDockerName}"

    echo "[+]   configuring services"
    docker exec -t $ZDockerName mkdir -p /var/run/sshd
    docker exec -t $ZDockerName  rm -f /etc/service/sshd/down
    #
    echo "[+]   regen ssh keys"
    docker exec -t $ZDockerName  rm -f /etc/service/sshd/down
    docker exec -t $ZDockerName  /etc/my_init.d/00_regen_ssh_host_keys.sh
    #

    ZDockerSSHAuthorize $ZDockerName

    container 'echo export "LC_ALL=C.UTF-8" >> /root/.profile'
    container 'echo "export LANG=C.UTF-8" >> /root/.profile'

    echo "[+] SSH enabled OK"

}

ZDockerRemove(){
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    catcherror

    ZDockerConfig
    local ZDockerName="${1:-$ZDockerName}"
    echo "[+] remove docker $ZDockerName"
    docker rm  -f "$ZDockerName" || true
    # docker inspect $iname >  /dev/null 2>&1 &&  docker rm  -f "$iname" > /dev/null 2>&1
}

ZDockerRemoveImage(){
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    catcherror

    ZDockerConfig
    local ZDockerImage="${1:-$ZDockerImage}"
    echo "[+] remove docker image $ZDockerImage"
    docker rmi  -f "$ZDockerImage"  > ${ZLogFile} 2>&1 || true
}

ZDockerBuildUbuntu() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    catcherror

    ZDockerConfig
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
    docker exec -t $ZDockerName apt update
    docker exec -t $ZDockerName apt upgrade -y
    docker exec -t $ZDockerName apt install curl mc openssh-server git net-tools iproute2 tmux localehelper psmisc telnet rsync -y

    ZDockerEnableSSH

    echo "[+]   setting up default environment"
    container 'echo "" > /etc/motd'
    container touch /root/.iscontainer

    ZDockerCommit -b jumpscale/ubuntu -s #also stop

    echo "[+] DOCKER UBUNTU OK"
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
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFileecho '[${FUNCNAME[0]}]' > $ZLogFile
    # [[ $ZINTERACTIVE -eq 1 ]] && catcherror
    catcherror

    local OPTIND
    local bname='jumpscale/ubuntu'
    local iname='build'
    local port=2222
    local addarg=''

    while getopts "b:i:p:a:h" opt; do
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
        ZDockerBuildUbuntu
    fi

    if [[ ! -z "$addarg" ]]; then
        ZDockerRun -b $bname -i $iname -p $port -a $addarg || return 1
    else
        ZDockerRun -b $bname -i $iname -p $port || return 1
    fi

    echo '[+] Ubuntu Docker Is Active (OK)'
}

ZDockerBuildJS9() {(
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    catcherror

    ZDockerRunUbuntu $@

    echo "[+]   installing basic dependencies"
    container apt-get update
    container apt-get install -y curl mc openssh-server git net-tools iproute2 tmux localehelper psmisc telnet

    echo "[+] JS9 BUILD"
    ZInstaller_code_jumpscale
    ZInstaller_python
    ZInstaller_js9
)}

ZDockerRunJS9() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    ZDockerRunUbuntu $@

    local OPTIND
    local bname='jumpscale/ubuntu'
    local iname='build'
    local port=2222
    local addarg=''
    while getopts "b:i:p:a:h" opt; do
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
        ZDockerBuildUbuntu
    fi

    if [[ ! -z "$addarg" ]]; then
        ZDockerRun -b $bname -i $iname -p $port -a $addarg || return 1
    else
        ZDockerRun -b $bname -i $iname -p $port || return 1
    fi



}

ZDockerRunUsage() {
   cat <<EOF
Usage: ZDockerRun [-b $bname] [-i $iname] [-p port]
   -b bname: name of base image, defaults to jumpscale/jsbase (which is ubuntu with some basic tools)
   -i iname: name of docker which will be spawned, default to 'build'
   -p port: ssh port for docker defaults to 2222
   -a addarg: is additional arguments for docker e.g. -p 10700-10800:10700-10800
   -h: help

EOF
}

ZDockerRun() {
    echo FUNCTION: ${FUNCNAME[0]} > $ZLogFile
    catcherror

    ZDockerConfig
    local OPTIND
    local bname='jumpscale/js9_base'
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
    ZNodePortSet $port
    ZNodeSet localhost
    export ZDockerName=$iname

    echo "[+] start docker $bname -> $iname (port:$port)"

    existing="$(docker ps -aq -f name=^/${iname}$)"

    if [[ ! -z "$existing" ]]; then
        ZDockerRemove $iname
    fi

    mounted_volumes="\
        -v ${CONTAINERDIR}/:/root/host \
        -v ${ZCODEDIR}/:/opt/code \
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
        $bname > ${ZLogFile} 2>&1 || die "docker could not start, please check ${ZLogFile}"

    sleep 1

    #only authorize when var not set
    if [[ -z "$SSHNOAUTH" ]]; then
        ZDockerSSHAuthorize || die
    fi



}
