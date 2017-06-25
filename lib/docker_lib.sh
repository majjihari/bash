
######### DOCKER

container() {
    ZDockerConfig
    ssh -A root@localhost -p $RPORT "$@" > ${ZLogFile} 2>&1 | tee > $ZLogFile 2>&1 || die "ssh error"
}

# die and get docker log back to host
# $1 = docker container name, $2 = ZLogFile name, $3 = optional message
dockerdie() {
    if [ "$3" != "" ]; then
        echo "[-] something went wrong in docker $1: $3"
        exit 1
    fi

    echo "[-] something went wrong in docker: $1"
    docker exec -t $iname cat "$2"

    exit 1
}

ZDockerConfig() {
    export CONTAINERDIR=~/gig
    mkdir -p ${CONTAINERDIR}/code
    mkdir -p ${CONTAINERDIR}/private
    mkdir -p ${CONTAINERDIR}/.cache/pip
}

ZDockerCommit() {
    echo "[+] Commit docker: $1"
    docker commit $1 jumpscale/$2 > ${ZLogFile} 2>&1 || return 1
    if [ "$3" != "" ]; then
        dockerremove $1
    fi
}

ZDockerSSHAuthorize() {
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
    docker exec -t $ZDockerName  sv start sshd > ${ZLogFile} 2>&1

    echo "[+]   Waiting for ssh to allow connections"
    while ! ssh-keyscan -p $RPORT localhost 2>&1 | grep -q "OpenSSH"; do
        sleep 0.2
    done

    echo "[+]   remove machine from localhost"
    sed -i.bak /localhost.:$RPORT/d ~/.ssh/known_hosts
    rm -f ~/.ssh/known_hosts.bak
    ssh-keyscan -p $RPORT localhost 2>&1 | grep -v '^#' >> ~/.ssh/known_hosts

    ZDockerSSHAuthorize $ZDockerName

    container 'echo export "LC_ALL=C.UTF-8" >> /root/.profile'
    container 'echo "export LANG=C.UTF-8" >> /root/.profile'


}

ZDockerRemove(){
    ZDockerConfig
    echo "[+] remove docker $1"
    docker rm  -f "$1" || true
    # docker inspect $iname >  /dev/null 2>&1 &&  docker rm  -f "$iname" > /dev/null 2>&1
}

ZDockerRemoveImage(){
    ZDockerConfig
    echo "[+] remove docker image $1"
    docker rmi  -f "$1"  > ${ZLogFile} 2>&1 || true
}

ZDockerRunUbuntu() {
    ZDockerConfig
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
    ZDockerConfig
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
        $bname > ${ZLogFile} 2>&1 || die "docker could not start, please check ${ZLogFile}"

    sleep 1

    # ssh_authorize "${iname}"


}
