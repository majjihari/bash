



ZInstall_python() {

    local OPTIND
    local force=0

    while getopts "f" opt; do
        case $opt in
           f )  force=1 ;;
        esac
    done

    ZDockerActive -b "jumpscale/ubuntu" -c "ZDockerBuildUbuntu -f" || return 1

    if [ $force -eq 0 ] && ZDoneCheck "ZInstall_python" && ZDockerImageExist "jumpscale/ubuntu_python" ; then
        echo "[+] install python & deps already done."
       return 0
    fi

    ZDoneUnset "ZInstall_python"
    ZDoneUnset "ZInstall_js9"    

    echo "[+] installing python"
    container 'apt-get update' || return 1
    container 'apt-get install -y curl mc openssh-server git net-tools iproute2 tmux localehelper psmisc telnet' || return 1
    if [[ $1 == "full" ]]; then
        container 'apt-get install -y python3' || return 1
    else
        container 'apt-get install -y python3 python3-cryptography python3-paramiko python3-psutil' || return 1
    fi

    echo "[+] installing pip system"
    container "curl -sk https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py" || return 1
    container 'python3 /tmp/get-pip.py' || return 1

    echo "[+] installing some pip dependencies"
    container 'pip3 install --upgrade pip' || return 1
    container 'pip3 install tmuxp' || return 1
    container 'pip3 install gitpython' || return 1

    ZDockerCommit -b jumpscale/ubuntu_python || die "docker commit" || return 1

    ZDoneSet "ZInstall_python"

    echo "[+] python installed in container(OK)"

}


ZInstall_js9() {

    local OPTIND
    local force=0

    while getopts "f" opt; do
        case $opt in
           f )  force=1 ;;
        esac
    done

    ZDockerActive -b "jumpscale/ubuntu_python" -c "ZInstall_python -f" || return 1

    if [ $force -eq 0 ] && ZDoneCheck "ZInstall_js9" && ZDockerImageExist "jumpscale/js9" ; then
        echo "[+] install js9 in container already done."
       return 0
    fi
    ZDoneUnset "ZInstall_js9"

    ZInstall_code_jumpscale_host || return 1

    echo "[+] install js9"
    container "cp /opt/code/github/jumpscale/core9/mascot /root/.mascot.txt"

    container "ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts" || return 1
    container "pip3 install -e /opt/code/github/jumpscale/core9" || return 1
    
    echo "[+] initializing jumpscale first time."
    #will also install the jumpscale command files
    container 'js9_init' || return 1

    echo "[+] installing jumpscale prefab9"
    container "pip3 install -e /opt/code/github/jumpscale/prefab9" || return 1


    echo "[+] installing jumpscale lib9 without deps"
    container "pip3 install --no-deps -e /opt/code/github/jumpscale/lib9" || return 1
    
    echo "[+] initializing jumpscale"
    container 'js9_init' || return 1

    container 'js9 "j.tools.develop.dockerconfig()"'

    ZDockerCommit -b jumpscale/js9 || die "docker commit" || return 1

    echo "[+] js9 installed (OK)"

    ZDoneSet "ZInstall_js9"

}

ZInstall_js9_full() {

    local OPTIND
    local force=0

    while getopts "f" opt; do
        case $opt in
           f )  force=1 ;;
        esac
    done

    #check the docker image is there
    ZDockerActive -b "jumpscale/js9" -c "ZInstall_js9 -f" || return 1

    if [ $force -eq 0 ] && ZDoneCheck "ZInstall_js9_full" && ZDockerImageExist "jumpscale/js9_full" ; then
        echo "[+] install js9 in container already done."
       return 0
    fi
    ZDoneUnset "ZInstall_js9"

    echo "[+] installing jumpscale build dependencies"
    container "apt-get install build-essential python3-dev libvirt-dev libssl-dev libffi-dev libssh-dev -y" || return 1
    echo "[+] installing jumpscale core9"
    container "pip3 install Cython>=0.25.2 asyncssh>=1.9.0 numpy>=1.12.1 tarantool>=0.5.4" || return 1
    
    echo "[+] install lib9 with dependencies (can take long time)"
    container 'cd  /opt/code/github/jumpscale/lib9 && bash install.sh;' || return 1

    echo "[+] initializing jumpscale"
    container 'js9_init' || return 1

    ZDockerCommit -b jumpscale/js9_full || die "docker commit" || return 1

    ZDoneSet "ZInstall_js9_full"

}

ZInstall_docgenerator() {

    local OPTIND
    local force=0

    while getopts "f" opt; do
        case $opt in
           f )  force=1 ;;
        esac
    done

    ZDockerActive -b "jumpscale/js9" -c "ZInstall_js9 -f" || return 1

    if [ $force -eq 0 ] && ZDoneCheck "ZInstall_js9_docgenerator" && ZDockerImageExist "jumpscale/js9_docgenerator" ; then
        echo "[+] install js9 docgenerator in container already done."
       return 0
    fi
    ZDoneUnset "ZInstall_js9_docgenerator"

    echo "[+] initializing jumpscale"
    container 'js9_init' || return 1
    container 'apt update; apt upgrade -y; apt install bzip2 -y'

    echo "[+] install docgenerator (can take long time)"
    container 'python3 -c "from js9 import j;j.tools.docgenerator.install()"' || return 1

    ZDockerCommit -b jumpscale/js9_docgenerator || die "docker commit" || return 1

    ZDoneSet "ZInstall_js9_docgenerator"

}

ZInstall_ays9() {
    ZDockerRunUbuntu || return 1
    if ZDoneCheck "ZInstall_js9_ays9" ; then
        echo "[+] install ays9 already done."
       return 0
    fi
    ZDoneUnset "ZInstall_js9"
    local port=${RPORT:-2222}
    local addarg="${RNODE:-localhost}"
    echo "[+] install AYS9"
    local branch="${1:-master}"
    echo "[+] loading or updating AYS source code (branch:$branch)"
    ZCodeGetJS -r ays9 -b $branch || return 1
    echo "[+] installing jumpscale ays9"
    ZNodeSet $addarg  || return 1
    ZNodePortSet $port || return 1
    container "pip3 install -e /opt/code/github/jumpscale/ays9" || return 1
    container "js9_init" || return 1
    ZDoneSet "ZInstall_js9_ays9"
}

ZInstall_portal9() {
    ZDockerRunUbuntu || return 1
    if ZDoneCheck "ZInstall_js9_portal9" ; then
        echo "[+] install portal9 already done."
       return 0
    fi
    ZDoneUnset "ZInstall_js9"
    local port=${RPORT:-2222}
    local addarg="${RNODE:-localhost}"
    echo "[+] install Portal9"
    local branch="${1:-master}"
    echo "[+] loading or updating Portal source code (branch:$branch)"
    ZCodeGetJS -r python-snippets -b master  || return 1
    
    echo "[+] installing jumpscale portal9"
    ZNodeSet $addarg || return 1
    ZNodePortSet $port || return 1
    container "cd  /opt/code/github/jumpscale/portal9 && bash install.sh;" || return 1
    container "js9_init" || return 1
    ZDoneSet "ZInstall_js9_portal9"
}

ZInstall_issuemanager() {
    ZDockerRunUbuntu  || return 1
    if ZDoneCheck "ZInstall_js9_issuemanager" ; then
        echo "[+] Issue Manager already installed"
       return 0
    fi
    ZDoneUnset "ZInstall_js9"
    ZInstall_js9_full || return 1
    ZInstall_portal9 || return 1
    echo "[+] Installing IssueManager"
    container 'python3 -c "from js9 import j;j.tools.prefab.local.apps.issuemanager.install()"' || return 1
    container 'python3 -c "from js9 import j;j.tools.prefab.local.apps.issuemanager.start()"' || return 1
    ZDoneSet "ZInstall_js9_issuemanager"
}

ZInstall_zerotier() {
    ZDockerRunUbuntu ||  return 1
    container "apt-get install gpgv2 -y" || return 1
    container "curl -s 'https://pgp.mit.edu/pks/lookup?op=get&search=0x1657198823E52A61' | gpg --import" || return 1
    container "curl -s https://install.zerotier.com/ | bash || true" || return 1
}

ZInstall_openvpn() {
    echo "[+] install openvpn docker"
    mkdir -p /etc/ovpn
    docker run --name=openvpn-as -p 8081:80 -v /etc/ovpn:/config -e INTERFACE=eth0 --net=host --privileged linuxserver/openvpn-as 
# -e PGID=<gid> -e PUID=<uid> \
# -e TZ=<timezone> \
# -e INTERFACE=<interface> \
# --net=host --privileged \
# linuxserver/openvpn-as
}