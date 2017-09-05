

# js9() {(
#     if ! ZDoneCheck "ZInstall_js9_local" ; then
#         # echo 'js9' >> $ZLogFile
#         # echo "x$@"
#         if [ "x$@" = "x" ] ; then
#             js9" -i || die "could not zexec js9" || return 1
#         else
#             ZEXEC -c "js9 '$@'" -i || die "could not zexec js9" || return 1
#         fi    
#         return 0
#     fi
#     if ! ZDoneCheck "ZInstall_js9" ; then
#         ZInstall_js9
#     fi
#     echo 'js9' >> $ZLogFile
#     echo "x$@"
#     if [ "x$@" = "x" ] ; then
#         ZEXEC -c "js9" -i || die "could not zexec js9" || return 1
#     else
#         ZEXEC -c "js9 '$@'" -i || die "could not zexec js9" || return 1
#     fi
# )}
