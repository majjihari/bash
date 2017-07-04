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
    echo '' > $ZLogFile
    if ! which tmux 2>&1 > /dev/null; then
        die "tmux not found"
    fi

    local session="main"
    local name="main"
    local command=""
    local keep=0
    local OPTIND
    local extra=""

    while getopts "n:c:s:hk" opt; do
        case $opt in
           n )  name=$OPTARG ;;
           c )  command=$OPTARG ;;
           s )  session=$OPTARG ;;
           k )  keep=1 ;;
           h )  TMUX_Start_Usage ; return 0 ;;
        esac
    done

    if  [ "$command" != "" ]; then
        # if session doesn't exists, nothing exists, just spawn it
        if ! tmux has-session -t $session 2>&1 > /dev/null; then
            tmux new-session -s $session -n $name $command
            return 0
        fi

        # Now, we know the session already exists, let's check if window
        # already exists
        if [ $keep -eq 0 ]; then
            extra="-k"
        fi

        # FIXME: need to select right session

        if tmux list-window 2>&1 | grep -q " $name "; then
            tmux new-window $extra -n $name $command
        fi

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
    echo '' > $ZLogFile
    if ! which tmux 2>&1 > /dev/null; then
        die "tmux not found"
    fi

    local name="main"
    local session="main"
    local OPTIND

    while getopts "n:s:h" opt; do
        case $opt in
           n )  name=$OPTARG ;;
           s )  session=$OPTARG ;;
           h )  TMUX_Stop_Usage ; return 0 ;;
        esac
    done

    # FIXME: need session handling
    tmux kill-window -t $name

)}
