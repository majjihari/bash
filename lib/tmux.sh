TMUX_Start_Usage() {
   cat <<EOF
Start a command in tmux session.
Usage: ZEXEC [-l]
   -n: name of the window in the tmux (default = main)
   -c: command to start e.g. ssh -L 9000:imgur.com:80 user@example.com
   -s: session name (default = main)
   -k: keep means if the window exists, do not remove it, just send command to it
   -h: help

the previous running command will be killed (this is done by killing the window)

EOF
}
TMUX_Start() {(
    #CHECK that tmux is installed, if not properly show
    echo '' > $ZLogFile
    local session="main"
    local name="main"
    local command=""
    local keep=0
    local OPTIND
    while getopts "n:c:s:hk" opt; do
        case $opt in
           n )  name=$OPTARG ;;
           c )  command=$OPTARG ;;
           s )  session=$OPTARG ;;
           k )  keep = 1 ;;
           h )  TMUX_Start_Usage ; return 0 ;;
        esac

        shift
    done
    if  [ "$command" != "" ] ; then
        die "IMPLEMENT"
    else
        die "could not start tmux session, check syntax: $@"
    fi

)}

TMUX_Stop_Usage() {
   cat <<EOF
Stop a window in a session
Usage: ZEXEC [-l]
   -n: name of the window in the tmux (default = main)
   -s: session name (default = main)
   -h: help

EOF
}
TMUX_Stop() {(
    #CHECK that tmux is installed, if not properly show
    echo '' > $ZLogFile
    local name="main"
    local session="main"
    local OPTIND
    while getopts "n:s:h" opt; do
        case $opt in
           n )  name=$OPTARG ;;
           s )  session=$OPTARG ;;
           h )  TMUX_Stop_Usage ; return 0 ;;
        esac
        shift
    done
    if  [ "$command" != "" ] ; then
        die "IMPLEMENT"
    else
        die "could not kill tmux session, check syntax: $@"
    fi

)}
