

ZInstaller_code_jumpscale() {
    ZDockerRunUbuntu || die || return 1
    ZInstaller_python
    if doneCheck "ZInstaller_code_jumpscale" ; then
        echo "[+] update jumpscale code was already done."
       return 0
    fi
    local branch="${1:-master}"
    echo "[+] loading or updating jumpscale source code (branch:$branch)"
    ZCodeGetJS -r core9 -b $branch > ${ZLogFile} 2>&1 || die || return 1
    ZCodeGetJS -r lib9 -b $branch > ${ZLogFile} 2>&1 || die || return 1
    ZCodeGetJS -r prefab9 -b $branch > ${ZLogFile} 2>&1 || die || return 1
    # ZCodeGetJS -r builder_bootstrap -b $branch > ${ZLogFile} 2>&1 || die || return 1
    ZCodeGetJS -r developer -b $branch > ${ZLogFile} 2>&1 || die || return 1
    echo "[+] update jumpscale code done"
    doneSet "ZInstaller_code_jumpscale"
}

ZInstaller_python() {
    ZDockerRunUbuntu || die || return 1
    if doneCheck "ZInstaller_python" ; then
        echo "[+] install python & deps already done."
       return 0
    fi
    echo "[+]   installing python"
    container 'apt-get update' || return 1
    container 'apt-get install -y curl mc openssh-server git net-tools iproute2 tmux localehelper psmisc telnet' || return 1
    if [[ $1 == "full" ]]; then
        container 'apt-get install -y python3' || return 1
    else
        container 'apt-get install -y python3 python3-cryptography python3-paramiko python3-psutil' || return 1
    fi

    echo "[+]   installing pip system"
    container "curl -sk https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py" || return 1
    container 'python3 /tmp/get-pip.py' || return 1

    echo "[+]   installing some pip dependencies"
    container 'pip3 install --upgrade pip' || return 1
    container 'pip3 install tmuxp' || return 1
    container 'pip3 install gitpython' || return 1

    doneSet "ZInstaller_python"

}


ZInstaller_js9() {
    ZDockerRunUbuntu || die || return 1
    if doneCheck "ZInstaller_js9" ; then
        echo "[+] install js9 already done."
       return 0
    fi
    ZInstaller_code_jumpscale
    echo "[+] install js9"
    # ZSSH "ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts"
    echo "[+]   synchronizing developer files"
    container 'rsync -rv /opt/code/github/jumpscale/developer/files_guest/ /' || return 1
    if [[ $1 == "full" ]]; then
        echo "[+]   installing jumpscale build dependencies"
        container "apt-get install build-essential python3-dev libvirt-dev libssl-dev libffi-dev libssh-dev -y" || return 1
        echo "[+]   installing jumpscale core9"
        container "pip3 install Cython>=0.25.2 asyncssh>=1.9.0 numpy>=1.12.1 tarantool>=0.5.4" || return 1
    fi
    container "source ~/.jsenv.sh && pip3 install -e /opt/code/github/jumpscale/core9" || return 1
    echo "[+]   installing jumpscale prefab9"
    container "source ~/.jsenv.sh && pip3 install -e /opt/code/github/jumpscale/prefab9" || return 1
    echo "[+]   installing jumpscale lib9"
    if [[ $1 == "full" ]]; then
        container "source ~/.jsenv.sh && pip3 install -e /opt/code/github/jumpscale/lib9" || return 1
    else
        container "source ~/.jsenv.sh && pip3 install --no-deps -e /opt/code/github/jumpscale/lib9" || return 1
    fi



    echo "[+]   installing binaries files"
    container 'find  /opt/code/github/jumpscale/core9/cmds -exec ln -s {} "/usr/local/bin/" \;' || return 1
    container 'find  /opt/code/github/jumpscale/developer/cmds_guest -exec ln -s {} "/usr/local/bin/" \;' || return 1

    container 'rm -rf /usr/local/bin/cmds' || return 1
    container 'rm -rf /usr/local/bin/cmds_guest' || return 1

    echo "[+]   initializing jumpscale"
    container 'js9_init' || return 1
    echo "[+] js9 installed (OK)"

    doneSet "ZInstaller_js9"

}

ZInstaller_js9_full() {
    ZDockerRunUbuntu || die || return 1
    if doneCheck "ZInstaller_js9_full" ; then
        echo "[+] install js9 libs full, already done."
       return 0
    fi

    ZInstaller_js9
    echo "[+] install lib9 with dependencies (can take long time)"
    container 'source ~/.jsenv.sh && cd  /opt/code/github/jumpscale/lib9 && bash install.sh;' || return 1

    ZDockerCommit -b jumpscale/js9_full || die "docker commit" || return 1

    doneSet "ZInstaller_js9_full"

}

ZInstaller_docgenerator() {
    ZDockerRunUbuntu || die || return 1
    if doneCheck "ZInstaller_docgenerator" ; then
        echo "[+] install docgenerator already done."
       return 0
    fi
    ZInstaller_js9_full
    echo "[+] install docgenerator (can take long time)"
    container 'python3 -c "from js9 import j;j.tools.jsloader.generate()"' || return 1
    container 'python3 -c "from js9 import j;j.tools.docgenerator.installDeps()"' || return 1

    ZDockerCommit -b jumpscale/js9_docgenerator || die "docker commit" || return 1

    # doneSet "ZInstaller_docgenerator"

}

ZInstaller_ays9() {
    ZDockerRunUbuntu || die || return 1
    if doneCheck "ZInstaller_ays9" ; then
        echo "[+] install ays9 already done."
       return 0
    fi
    local port=${RPORT:-2222}
    local addarg="${RNODE:-localhost}"
    echo "[+] install AYS9"
    local branch="${1:-master}"
    echo "[+] loading or updating AYS source code (branch:$branch)"
    ZCodeGetJS -r ays9 -b $branch > ${ZLogFile} 2>&1 || die || return 1
    echo "[+]   installing jumpscale ays9"
    ZNodeSet $addarg
    ZNodePortSet $port
    container "source ~/.jsenv.sh && pip3 install -e /opt/code/github/jumpscale/ays9" || return 1
    container "js9_init"
    doneSet "ZInstaller_ays9"
}

ZInstaller_portal9() {
    ZDockerRunUbuntu || die || return 1
    if doneCheck "ZInstaller_portal9" ; then
        echo "[+] install portal9 already done."
       return 0
    fi
    local port=${RPORT:-2222}
    local addarg="${RNODE:-localhost}"
    echo "[+] install Portal9"
    local branch="${1:-master}"
    echo "[+] loading or updating Portal source code (branch:$branch)"
    ZCodeGetJS -r portal9 -b $branch > ${ZLogFile} 2>&1 || die || return 1
    echo "[+]   installing jumpscale portal9"
    ZNodeSet $addarg
    ZNodePortSet $port
    container "source ~/.jsenv.sh && pip3 install -e /opt/code/github/jumpscale/portal9" || return 1
    container "js9_init"
    doneSet "ZInstaller_portal9"
}

ZInstall_docker() {
    echo '[${FUNCNAME[0]}]' > $ZLogFile
    catcherror

    if [ "$(expr substr $(uname -s) 1 5)" = "Linux" ]; then
        dist=$(grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}' || true)
        if [ "$dist" = "Ubuntu" ]; then
            apt-get update
            apt-get install -y docker.io
        fi
    fi

    echo "[-] plateforme not supported"
}

ZInstall_zerotier() {
    ZDockerRunUbuntu || die || return 1
    container "apt-get install gpgv2 -y"
    container "curl -s 'https://pgp.mit.edu/pks/lookup?op=get&search=0x1657198823E52A61' | gpg --import"
    container "curl -s https://install.zerotier.com/ | bash || true"
}
