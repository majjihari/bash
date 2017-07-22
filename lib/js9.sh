

js9() {(
    if ! doneCheck "ZInstaller_js9" ; then
        ZInstaller_js9
    fi
    echo 'js9' > $ZLogFile
    echo "x$@"
    if [ "x$@" = "x" ] ; then
        ZEXEC -c "js9" -i || die "could not zexec js9" || return 1
    else
        ZEXEC -c "js9 '$@'" -i || die "could not zexec js9" || return 1
    fi
)}
