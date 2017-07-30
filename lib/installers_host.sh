


ZInstaller_code_jumpscale_host() {
    if doneCheck "ZInstaller_code_jumpscale_host" ; then
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
    doneSet "ZInstaller_code_jumpscale_host"
}


ZInstaller_js9_host() {

    ZCodeConfig

    ZInstaller_base_host

    ZInstaller_code_jumpscale_host

    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

    echo "[+] install js9"
    pip3 install -e $ZCODEDIR/github/jumpscale/core9 || die "could not install core9 of js9" || return 1
    
    echo "[+]   installing jumpscale lib9"
    pip3 install --no-deps -e $ZCODEDIR/github/jumpscale/lib9 || die "could not install lib9 of js9" || return 1

    echo "[+]   installing jumpscale prefab9"
    pip3 install -e $ZCODEDIR/github/jumpscale/prefab9 || return 1

    echo "[+]   installing binaries files"
    find  $ZCODEDIR/github/jumpscale/core9/cmds -exec ln -s {} "/usr/local/bin/" \; || return 1

    rm -rf /usr/local/bin/cmds || return 1
    rm -rf /usr/local/bin/cmds_guest || return 1

    echo "[+]   initializing jumpscale"
    python3 -c 'from JumpScale9 import j;j.tools.jsloader.generate()' || return 1
    
    echo "[+] js9 installed (OK)"

}



ZInstall_docker_host() {
    echo '[${FUNCNAME[0]}]' > $ZLogFile

    if [ "$(expr substr $(uname -s) 1 5)" = "Linux" ]; then
        dist=$(grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}' || true)
        if [ "$dist" = "Ubuntu" ]; then
            apt-get update
            apt-get install -y docker.io
        fi
    fi

    echo "[-] plateforme not supported"
}


ZInstaller_base_host(){

    if doneCheck "ZInstaller_base_host" ; then
        echo "ZInstaller_base_host already installed"
       return 0
    fi    

    if [ "$(uname)" == "Darwin" ]; then        
        brew upgrade || die "could not upgrade all brew installed components" || return 1
        brew install mc curl wget python3 unzip rsync || die "could not install base components" || return 1
        brew install phantomjs || die "could not install phantomjs" || return 1
        brew install node || die "could not install nodejs" || return 1
        sudo npm install -g mermaid || die "could not install mermaid" || return 1

        rm -rf /tmp/apps
        mkdir -p /tmp/apps
        pushd /tmp/apps
        wget https://cakebrew-377a.kxcdn.com/cakebrew-1.2.3.dmg || die "could not download cakebrew" || return 1
        ZInstall_DMG cakebrew-1.2.3.dmg 
        popd

        brew install git pdf2svg graphviz sshfs tmux curl || die "could not install git, graphiz, sshfs, tmux or curl" || return 1
        brew install ipfs || die "could not install ipfs" || return 1
        brew services start ipfs || die "could not autostart ipfs" || return 1

        echo "[+]   installing pip system"
        curl -sk https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py || die "could not download pip" || return 1
        python3 /tmp/get-pip.py || return 1

        echo "[+]   installing some pip dependencies"
        
        pip3 install --upgrade pip || return 1        
        pip3 install tmuxp || return 1
        pip3 install gitpython || return 1

        echo "[+]   installing some python pips (pylint, flake, ...)"
        pip3 install --upgrade pylint autopep8 flake8
        

    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        dist=''
        dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`
        if [ "$dist" == "Ubuntu" ]; then
            echo "found ubuntu"
            die "not implemented yet"
        fi
    else
        die "platform not supported"
    fi  

    doneSet "ZInstaller_base_host"
}



# ZInstaller_ipfs_host() {
#     # container "cd tmp; mkdir -p ipfs; cd ipfs; wget --inet4-only https://dist.ipfs.io/go-ipfs/v0.4.10/go-ipfs_v0.4.10_linux-amd64.tar.gz"
#     if [ "$(uname)" == "Darwin" ]; then
#         rm -rf /tmp/ipfs
#         mkdir -p /tmp/ipfs
#         pushd /tmp/ipfs
#         wget --inet4-only https://dist.ipfs.io/go-ipfs/v0.4.10/go-ipfs_v0.4.10_darwin-amd64.tar.gz

#         popd

#     elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
#         dist=''
#         dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`
#         if [ "$dist" == "Ubuntu" ]; then
#             echo "found ubuntu"
#             die "not implemented yet"
#         fi
#     else
#         die "platform not supported"
#     fi    

# }

