


ZInstaller_code_jumpscale_host() {
    if ZDoneCheck "ZInstaller_code_jumpscale_host" ; then
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
    ZDoneSet "ZInstaller_code_jumpscale_host"
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

    if ZDoneCheck "ZInstaller_base_host" ; then
        echo "[+] ZInstaller_base_host already installed"
       return 0
    fi    

    if [ "$(uname)" == "Darwin" ]; then      
        echo "[+]   upgrade brew"  
        brew upgrade  > ${ZLogFile} 2>&1 || die "could not upgrade all brew installed components" || return 1

        echo "[+]   installing git, python, mc, tmux, curl, sshfs, curl, ipfs"
        brew install mc wget python3 git pdf2svg unzip rsync graphviz sshfs tmux curl phantomjs ipfs > ${ZLogFile} 2>&1 || die "could not install git, graphiz, sshfs, tmux or curl" || return 1
 
        echo "[+]   installing node"
        brew install node  > ${ZLogFile} 2>&1 || die "could not install nodejs" || return 1

        echo "[+]   installing mermaid"
        sudo npm install -g mermaid  > ${ZLogFile} 2>&1 || die "could not install mermaid" || return 1


        echo "[+]   installing cakebrew"
        IPFS_get_install_dmg QmbCWrGrRL8aaZYMxSym4H9mhFbuUbFhfKT3uZnxPGvhoe cakebrew  || return 1

        echo "[+]   start ipfs"
        brew services start ipfs  > ${ZLogFile} 2>&1 || die "could not autostart ipfs" || return 1

        echo "[+]   installing pip system"
        curl -sk https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py || die "could not download pip" || return 1
        python3 /tmp/get-pip.py || return 1

        echo "[+] upgrade pip"
        pip3 install --upgrade pip > ${ZLogFile} 2>&1 || die || return 1      

        echo "[+]   installing some python pips (pylint, flake, ...)"
        pip3 install --upgrade pylint autopep8 flake8 tmuxp gitpython > ${ZLogFile} 2>&1 || die || return 1
        

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

    ZDoneSet "ZInstaller_base_host"
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




ZInstaller_editor_host() {

    ZInstaller_base_host

    if [ ! "$(uname)" == "Darwin" ]; then    
        die "only osx supported for now"
    fi

    #TODO: *1 need to make this multi platform

    # if [  -d "~/Applications/Visual Studio Code.app" ]; then
    #     echo "[+] no need to install visual studio code, already exists"
    # elif [  -d "/Applications/Visual Studio Code.app" ]; then
    #     echo "[+] no need to install visual studio code, already exists"
    # else
    echo "[+] download visual studio code"
    IPFS_get Qmd4d6Keiis5Br1XZckrA1SHWfhgBag3MDwbjxCM7wbuba vscode.zip   > ${ZLogFile} 2>&1 || die || return 1
    pushd /tmp/zdownloads > ${ZLogFile} 2>&1
    echo "[+] install visual studio code"
    rm -rf Visual Studio Code.app
    unzip -o vscode.zip  > ${ZLogFile} 2>&1 || die "could not unzip" || return 1
    mkdir -p '/Applications/Visual Studio Code.app'
    rsync -rav --delete-after  'Visual Studio Code.app/' '/Applications/Visual Studio Code.app/' > ${ZLogFile} 2>&1 || die "could not sync" || return 1
    rm -rf 'Visual Studio Code.app' > ${ZLogFile} 2>&1 || return 1
    popd
    # fi

    #DOES NOT WORK !
    # IPFS_get_dir QmXgtrmZneNvhUYMMDqkrJEJEqMNVkWSH9GZkvRMq8rXXj vscode_extensions  ~/.vscode/extensions || die || return 1

    rm -f /usr/local/bin/code
    ln -s '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' /usr/local/bin/code || die "could not link vscode" || return 1

    echo "[+] Code Editor Installed"

    echo "[+] Installing Code Editor Extensions"
    code --install-extension donjayamanne.python > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension tushortz.python-extended-snippets > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension himanoa.python-autopep8 > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension magicstack.magicpython > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension abronan.capnproto-syntax > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension eriklynd.json-tools > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension MariusAlchimavicius.json-to-ts > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension tuxtina.json2yaml > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension adamvoss.yaml > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension kosz78.nim > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension lukehoban.go > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension shd101wyy.markdown-preview-enhanced > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension josa.markdown-table-formatter > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension telesoho.vscode-markdown-paste-image > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension darkriszty.markdown-table-prettify > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension johnpapa.angular2 > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension rbbit.typescript-hero > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension esbenp.prettier-vscode > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension msjsdiag.debugger-for-chrome > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension donjayamanne.githistory > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension PeterJausovec.vscode-docker > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension waderyan.gitblame > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension christian-kohler.npm-intellisense > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension DavidAnson.vscode-markdownlint > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension felipecaputo.git-project-manager > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension christian-kohler.path-intellisense > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension wayou.vscode-todo-highlight > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension bungcip.better-toml > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension webfreak.debug > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension ms-vscode.node-debug2 > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension rogalmic.bash-debug > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension actboy168.lua-debug > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension keyring.lua > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension gccfeli.vscode-lua > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension trixnz.vscode-lua > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension vitorsalgado.vscode-redis > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension blzjns.vscode-raml > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension donjayamanne.git-extension-pack > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension alefragnani.project-manager > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension Shan.code-settings-sync > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension liximomo.sftp > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension lamartire.git-indicators > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension eamodio.gitlens > ${ZLogFile} 2>&1 || die || return 1
    code --install-extension KnisterPeter.vscode-github > ${ZLogFile} 2>&1 || die || return 1

    echo "[+] set system config params"
    echo kern.maxfiles=65536 | sudo tee -a /etc/sysctl.conf > ${ZLogFile} 2>&1 || die || return 1
    echo kern.maxfilesperproc=65536 | sudo tee -a /etc/sysctl.conf > ${ZLogFile} 2>&1 || die || return 1
    sudo sysctl -w kern.maxfiles=65536 > ${ZLogFile} 2>&1 || die || return 1
    sudo sysctl -w kern.maxfilesperproc=65536 > ${ZLogFile} 2>&1 || die || return 1
    ulimit -n 65536 > ${ZLogFile} 2>&1 || die || return 1

    echo "[+] download sourcetree"
    IPFS_get QmYtc2oowycqNXeedNbu9jLyDba4okTmnK5b1MoMuaNj6C  sourcetree.zip  > ${ZLogFile} 2>&1 || die || return 1   
    pushd /tmp/zdownloads/ > /dev/null 2>&1
    echo "[+] unzip sourcetree"
    unzip -o sourcetree.zip > ${ZLogFile} 2>&1 || die || return 1
    echo "[+] copy sourcetree"
    mkdir -p /Applications/SourceTree.app
    rsync -rav --delete-after SourceTree.app/ /Applications/SourceTree.app/ > ${ZLogFile} 2>&1 || die || return 1         
    popd    

    echo "[*] Get Java JDK"
    IPFS_get_mount_dmg QmPqvfiX1aUj9Nyo74qa47j9kPgEtKMbQLBaxTyT9F1fTV  java_jdk > ${ZLogFile} 2>&1 || die "could not get java dmg from ipfs" || return 1
    echo "[*] Install Java JDK"
    sudo installer -pkg '/Volumes/Java 8 Update 144/Java 8 Update 144.app/Contents/Resources/JavaAppletPlugin.pkg' -target / > ${ZLogFile} 2>&1 || die "could not install java" || return 1
    hdiutil detach '/Volumes/Java 8 Update 144'  > ${ZLogFile} 2>&1 || die || return 1

    echo "[*] Install Trolcommander"
    brew cask install trolcommander  > ${ZLogFile} 2>&1 || die || return 1

    echo "[*] Install Calibre"
    IPFS_get_install_dmg QmRV3g2Sy49MdKKEDE2m5WUY7CzFPRC7VsGX8jtwfofEEb calibre  > ${ZLogFile} 2>&1 || die || return 1
    sudo ln -s /Applications/calibre.app/Contents/MacOS/ebook-convert /usr/local/bin  > ${ZLogFile} 2>&1


}

