

LEDE_Install() {(
    #CHECK that tmux is installed, if not properly show
    echo '' > $ZLogFile
    ZNodeEnvSet || return 1
    ZEXEC opkg update || return 1
    ZEXEC opkg install rsync htop sfdisk mc git curl ping  || return 1
)}
