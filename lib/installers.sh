
ZInstaller_code_jumpscale() {
    local branch="${1:-master}"
    echo "[+] loading or updating jumpscale source code (branch:$branch)"
    ZCodeGetJS -r core9 -b $branch > ${ZLogFile} 2>&1 || die || return 1
    # popd
    ZCodeGetJS -r lib9 -b $branch > ${ZLogFile} 2>&1 || die || return 1
    # popd
    ZCodeGetJS -r prefab9 -b $branch > ${ZLogFile} 2>&1 || die || return 1
    # popd
    # ZCodeGetJS -r builder_bootstrap -b $branch > ${ZLogFile} 2>&1 || die || return 1
    # popd
    ZCodeGetJS -r developer -b $branch > ${ZLogFile} 2>&1 || die || return 1
    popd
    echo "[+] update jumpscale code done"
}

ZInstaller_python() {
    echo "[+]   installing python"
    container 'apt-get install -y python3  python3-cryptography python3-paramiko python3-psutil' || return 1

    echo "[+]   installing pip system"
    container "curl -sk https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py" || return 1
    container 'python3 /tmp/get-pip.py' || return 1

    echo "[+]   installing some pip dependencies"
    container 'pip3 install --upgrade pip' || return 1
    container 'pip3 install tmuxp' || return 1
    container 'pip3 install gitpython' || return 1

}


ZInstaller_js9() {
    echo "[+] install js9"
    # ZSSH "ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts"
    echo "[+]   synchronizing developer files"
    container 'rsync -rv /opt/code/jumpscale/developer/files_guest/ /' || return 1

    echo "[+]   installing jumpscale core9"
    container "source ~/.jsenv.sh && pip3 install -e /opt/code/jumpscale/core9" || return 1
    echo "[+]   installing jumpscale prefab9"
    container "source ~/.jsenv.sh && pip3 install -e /opt/code/jumpscale/prefab9" || return 1
    echo "[+]   installing jumpscale lib9"
    container "source ~/.jsenv.sh && pip3 install --no-deps -e /opt/code/jumpscale/lib9" || return 1

    echo "[+]   installing binaries files"
    container 'find  /opt/code/jumpscale/core9/cmds -exec ln -s {} "/usr/local/bin/" \;' || return 1
    container 'find  /opt/code/jumpscale/developer/cmds_guest -exec ln -s {} "/usr/local/bin/" \;' || return 1

    container 'rm -rf /usr/local/bin/cmds' || return 1
    container 'rm -rf /usr/local/bin/cmds_guest' || return 1

    echo "[+]   initializing jumpscale"
    container 'python3 -c "from JumpScale9 import j; j.do.initEnv()"' || return 1
    container 'python3 -c "from JumpScale9 import j; j.tools.jsloader.generate()"' || return 1

    echo "[+] js9 installed (OK)"

}

ZInstaller_js9() {
    echo "[+] install docgenerator"
    container 'ls /' || return 1
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
