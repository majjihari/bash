RSync_bash() {(
    #CHECK that tmux is installed, if not properly show
    echo '' > $ZLogFile
    ZNodeEnvSet
    ZEXEC mkdir -p /root/code/jumpscale/bash
    ZEXEC rm -rf /root/code/jumpscale/bash
    # rsync -rav -e "ssh -p $RPORT" $ZUTILSDIR/bash/ root@$RNODE:/root/code/jumpscale/bash/
)}
