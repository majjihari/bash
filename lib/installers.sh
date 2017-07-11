
ZInstaller_code_jumpscale() {
    local branch="${1:-master}"
    echo "[+] loading or updating jumpscale source code (branch:$branch)"
    ZCodeGetJS -r core9 -b $branch > ${ZLogFile} 2>&1 || die
    # popd
    ZCodeGetJS -r lib9 -b $branch > ${ZLogFile} 2>&1 || die
    # popd
    ZCodeGetJS -r prefab9 -b $branch > ${ZLogFile} 2>&1 || die
    # popd
    ZCodeGetJS -r builder_bootstrap -b $branch > ${ZLogFile} 2>&1 || die
    # popd
    ZCodeGetJS -r developer -b $branch > ${ZLogFile} 2>&1 || die
    # popd
    echo "[+] update jumpscale code done"
}

ZInstaller_python() {
    echo "[+]   installing python"
    container apt-get install -y python3  python3-cryptography python3-paramiko python3-psutil

    echo "[+]   installing pip system"
    container "curl -sk https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py"
    container python3 /tmp/get-pip.py

    echo "[+]   installing some pip dependencies"
    container pip3 install --upgrade pip
    container pip3 install tmuxp
    container pip3 install gitpython

}


ZInstaller_js9() {
    echo "[+] install js9"
    # ZSSH "ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts"
    echo "[+]   synchronizing developer files"
    container rsync -rv /opt/code/github/jumpscale/developer/files_guest/ /

    echo "[+]   installing jumpscale core9"
    container "source ~/.jsenv.sh && pip3 install -e /opt/code/github/jumpscale/core9"
    echo "[+]   installing jumpscale prefab9"
    container "source ~/.jsenv.sh && pip3 install -e /opt/code/github/jumpscale/prefab9"
    echo "[+]   installing jumpscale lib9"
    container "source ~/.jsenv.sh && pip3 install --no-deps -e /opt/code/github/jumpscale/lib9"

    echo "[+]   installing binaries files"
    container 'find  /opt/code/github/jumpscale/core9/cmds -exec ln -s {} "/usr/local/bin/" \;'
    container 'find  /opt/code/github/jumpscale/developer/cmds_guest -exec ln -s {} "/usr/local/bin/" \;'

    container rm -rf /usr/local/bin/cmds
    container rm -rf /usr/local/bin/cmds_guest

    echo "[+]   initializing jumpscale"
    container 'python3 -c "from JumpScale9 import j; j.do.initEnv()"'
    container 'python3 -c "from JumpScale9 import j; j.tools.jsloader.generate()"'

    echo "[+] js9 installed (OK)"

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
