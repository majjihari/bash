

LEDE_Install() {(
    #CHECK that tmux is installed, if not properly show
    echo '' > $ZLogFile
    ZNodeEnvSet
    ZEXEC opkg update
    ZEXEC opkg install rsync htop sfdisk mc git curl ping 
)}
