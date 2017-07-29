CodeCleanup() {
    #find all node_libs and remove
    echo "1"
}


ZInstaller_codetools_host() {

    IPFS_get_install_dmg QmRV3g2Sy49MdKKEDE2m5WUY7CzFPRC7VsGX8jtwfofEEb calibre || return 1
    sudo ln -s /Applications/calibre.app/Contents/MacOS/ebook-convert /usr/local/bin

    IPFS_get_install_dmg QmbCWrGrRL8aaZYMxSym4H9mhFbuUbFhfKT3uZnxPGvhoe cakebrew  || return 1

    ZInstaller_code_editor_host || return 1
}


ZInstaller_code_editor_host() {

    if [  -d "~/Applications/Visual Studio Code.app" ]; then
        echo "no need to install visual studio code, already exists"
    elif [  -d "/Applications/Visual Studio Code.app" ]; then
        echo "no need to install visual studio code, already exists"
    else
        echo "install visual studio code"
        IPFS_get Qmd4d6Keiis5Br1XZckrA1SHWfhgBag3MDwbjxCM7wbuba vscode.zip  || return 1
        pushd /tmp/zdownloads
        unzip -o vscode.zip || die "could not unzip" || return 1
        cp -rf 'Visual Studio Code.app' ~/Applications
        rm -rf 'Visual Studio Code.app'
        popd
    fi

    #DOES NOT WORK !
    # IPFS_get_dir QmXgtrmZneNvhUYMMDqkrJEJEqMNVkWSH9GZkvRMq8rXXj vscode_extensions  ~/.vscode/extensions || die || return 1

    rm -f /usr/local/bin/code
    ln -s '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' /usr/local/bin/code || die "could not link vscode" || return 1

    echo "Code Editor Installed"

    code --install-extension donjayamanne.python
    code --install-extension tushortz.python-extended-snippets
    code --install-extension himanoa.python-autopep8
    code --install-extension magicstack.magicpython
    code --install-extension abronan.capnproto-syntax
    code --install-extension eriklynd.json-tools
    code --install-extension MariusAlchimavicius.json-to-ts
    code --install-extension tuxtina.json2yaml
    code --install-extension adamvoss.yaml
    code --install-extension kosz78.nim
    code --install-extension lukehoban.go
    code --install-extension shd101wyy.markdown-preview-enhanced
    code --install-extension josa.markdown-table-formatter
    code --install-extension telesoho.vscode-markdown-paste-image
    code --install-extension darkriszty.markdown-table-prettify
    code --install-extension johnpapa.angular2
    code --install-extension rbbit.typescript-hero
    code --install-extension esbenp.prettier-vscode
    code --install-extension msjsdiag.debugger-for-chrome
    code --install-extension donjayamanne.githistory
    code --install-extension PeterJausovec.vscode-docker
    code --install-extension waderyan.gitblame
    code --install-extension christian-kohler.npm-intellisense
    code --install-extension DavidAnson.vscode-markdownlint
    code --install-extension felipecaputo.git-project-manager
    code --install-extension christian-kohler.path-intellisense
    code --install-extension wayou.vscode-todo-highlight
    code --install-extension bungcip.better-toml
    code --install-extension webfreak.debug
    code --install-extension ms-vscode.node-debug2
    code --install-extension rogalmic.bash-debug
    code --install-extension actboy168.lua-debug
    code --install-extension keyring.lua
    code --install-extension gccfeli.vscode-lua
    code --install-extension trixnz.vscode-lua
    code --install-extension vitorsalgado.vscode-redis
    code --install-extension blzjns.vscode-raml
    code --install-extension donjayamanne.git-extension-pack
    code --install-extension alefragnani.project-manager
    code --install-extension Shan.code-settings-sync
    code --install-extension liximomo.sftp
    code --install-extension lamartire.git-indicators
    code --install-extension eamodio.gitlens
    code --install-extension KnisterPeter.vscode-github

    echo kern.maxfiles=65536 | sudo tee -a /etc/sysctl.conf
    echo kern.maxfilesperproc=65536 | sudo tee -a /etc/sysctl.conf
    sudo sysctl -w kern.maxfiles=65536
    sudo sysctl -w kern.maxfilesperproc=65536
    ulimit -n 65536
    
}

ZInstaller_filemanager_host() {
    echo "[*] Install Java JDK"
    IPFS_get_mount_dmg QmPqvfiX1aUj9Nyo74qa47j9kPgEtKMbQLBaxTyT9F1fTV  java_jdk || die "could not get java dmg from ipfs" || return 1
    sudo installer -pkg '/Volumes/Java 8 Update 144/Java 8 Update 144.app/Contents/Resources/JavaAppletPlugin.pkg' -target /
    hdiutil detach '/Volumes/Java 8 Update 144' || die || return 1

    brew cask install trolcommander

}
