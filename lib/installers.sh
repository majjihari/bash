
ZBuild_python() {

    local OPTIND
    local force=0

    while getopts "f" opt; do
        case $opt in
           f )  force=1 ;;
        esac
    done

    ZDockerActive -b "jumpscale/ubuntu_python" && return 0

    ZDockerActive -b "jumpscale/ubuntu" -c "ZDockerBuildUbuntu -f" -i ubuntu_python || return 1

    echo "[+] installing python"
    container 'apt-get update' || return 1
    container 'apt-get install -y curl mc openssh-server git net-tools iproute2 tmux localehelper psmisc telnet' || return 1
    if [[ $1 == "full" ]]; then
        container 'apt-get install -y python3' || return 1
    else
        container 'apt-get install -y python3 python3-cryptography python3-paramiko python3-psutil' || return 1
    fi

    echo "[+] installing pip system"
    container "curl -sk https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py" || return 1
    container 'python3 /tmp/get-pip.py' || return 1

    echo "[+] installing some pip dependencies"
    container 'pip3 install --upgrade pip' || return 1
    container 'pip3 install tmuxp' || return 1
    container 'pip3 install gitpython' || return 1

    ZDockerCommit -b jumpscale/ubuntu_python -s || die "docker commit" || return 1

    echo "[+] python installed in container(OK)"

}


ZInstall_js9() {

    local OPTIND
    local force=0

    while getopts "f" opt; do
        case $opt in
           f )  ZDockerRemoveImage jumpscale/js9 ;;
        esac
    done

    ZDockerActive -b "jumpscale/js9" -i js9 && return 0

    ZDockerActive -b "jumpscale/ubuntu_python" -c "ZBuild_python -f" -i js9 || return 1

    # ZInstall_host_code_jumpscale '9.3.0' || return 1

    ZInstall_host_code_jumpscale || die "could not get code for jumpscale (git)" || return 1

    echo "[+] install js9"
    container "cp /opt/code/github/jumpscale/core9/mascot /root/.mascot.txt"

    container "ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts" || return 1
    container "pip3 install -e /opt/code/github/jumpscale/core9" || return 1

    echo "[+] initializing jumpscale first time."
    #will also install the jumpscale command files
    container 'js9_init' || return 1

    echo "[+] installing jumpscale prefab9"
    container "pip3 install -e /opt/code/github/jumpscale/prefab9" || return 1


    echo "[+] installing jumpscale lib9 without deps"
    container "pip3 install --no-deps -e /opt/code/github/jumpscale/lib9" || return 1

    echo "[+] initializing jumpscale"
    container 'js9_init' || return 1

    # container 'js9 "j.tools.develop.dockerconfig()"'

    ZDockerCommit -b jumpscale/js9 -s || die "docker commit" || return 1

    echo "[+] js9 installed (OK)"

}

ZInstall_js9_full() {

    local OPTIND
    local force=0

    while getopts "f" opt; do
        case $opt in
           f )  ZDockerRemoveImage jumpscale/js9_full ;;
        esac
    done

    ZDockerActive -b "jumpscale/js9_full" -i js9_full && return 0

    #check the docker image is there
    ZDockerActive -b "jumpscale/js9" -c "ZInstall_js9" -i js9_full || return 1
    
    echo "[+] install js9 full"

    echo "[+] installing jumpscale build dependencies"
    container "apt-get install build-essential python3-dev libvirt-dev libssl-dev libffi-dev libssh-dev -y" || return 1
    echo "[+] installing jumpscale core9"
    container "pip3 install Cython>=0.25.2 asyncssh>=1.9.0 numpy>=1.12.1 tarantool>=0.5.4" || return 1

    echo "[+] install lib9 with dependencies (can take long time)"
    container 'cd  /opt/code/github/jumpscale/lib9 && bash install.sh;' || return 1

    echo "[+] installing jumpscale prefab9"
    container 'cd  /opt/code/github/jumpscale/prefab9 && bash install.sh;' || return 1

    echo "[+] initializing jumpscale"
    container 'js9_init' || return 1

    ZDockerCommit -b jumpscale/js9_full -s || die "docker commit" || return 1

}

ZInstall_js9_node() {

    local OPTIND
    local force=0

    while getopts "f" opt; do
        case $opt in
           f )  ZDockerRemoveImage jumpscale/js9_node ;;
        esac
    done

    ZDockerActive -b "jumpscale/js9_node" -i js9_node && return 0

    #check the docker image is there
    ZDockerActive -b "jumpscale/js9_full" -c "ZInstall_js9_full -f" -i js9_node || return 1

    echo "[+] initializing node on js9"
    container 'js9 "j.tools.prefab.local.runtimes.nodejs.install()"' || return 1

    ZDockerCommit -b jumpscale/js9_node || die "docker commit" || return 1

}

ZInstall_docgenerator() {

    local OPTIND
    local force=0

    while getopts "f" opt; do
        case $opt in
           f )  ZDockerRemoveImage jumpscale/js9_docgenerator ;;
        esac
    done

    ZDockerActive -b "jumpscale/js9_docgenerator" -i js9_docgenerator && return 0

    ZDockerActive -b "jumpscale/js9_node" -c "ZInstall_js9_node -f" -i js9_docgenerator || return 1

    echo "[+] initializing jumpscale"
    container 'js9_init' || return 1
    container 'apt update; apt upgrade -y; apt install bzip2 -y'

    echo "[+] install docgenerator (can take long time)"
    container 'js9 "j.tools.prefab.local.runtimes.golang.install()"' || return 1
    container 'js9 "j.tools.prefab.local.runtimes.golang.goraml()"' || return 1
    container 'js9 "j.tools.docgenerator.install()"' || return 1

    ZDockerCommit -b jumpscale/js9_docgenerator || die "docker commit" || return 1

}

ZInstall_js9_celery() {

    local OPTIND
    local force=0

    while getopts "f" opt; do
        case $opt in
           f )  ZDockerRemoveImage jumpscale/js9_celery ;;
        esac
    done

    ZDockerActive -b "jumpscale/js9_celery" -i js9_celery && return 0

    #check the docker image is there
    ZDockerActive -b "jumpscale/js9" -c "ZInstall_js9 -f" -i js9_celery || return 1

    echo "[+] initializing celery on js9"
    container 'js9 "j.tools.prefab.local.apps.celery.install()"' || return 1

    ZDockerCommit -b jumpscale/js9_celery || die "docker commit" || return 1

}

# ZInstall_web_infrastructure() {

#     local OPTIND
#     local force=0

#     while getopts "f" opt; do
#         case $opt in
#            f )  ZDockerRemoveImage jumpscale/js9_docgenerator ;;
#         esac
#     done

#     ZDockerActive -b "jumpscale/js9_webinfra" -i js9_webinfra && return 0

#     ZDockerActive -b "jumpscale/js9_docgenerator" -c "ZInstall_docgenerator -f" -i js9_webinfra || return 1

#     echo "[+] initializing jumpscale"
#     container 'js9_init' || return 1
#     container 'apt update; apt upgrade -y; apt install bzip2 -y'

#     echo "[+] install extra's for web infrastructure"

#     #NOT IMPLEMENTED YET
#     # j.tools.prefab.local.apps.caddy.install()

#     ZDockerCommit -b jumpscale/js9_webinfra || die "docker commit" || return 1




# }

ZInstall_tarantool() {

    local OPTIND
    local force=0

    while getopts "f" opt; do
        case $opt in
           f )  ZDockerRemoveImage jumpscale/js9_tarantool ;;
        esac
    done

    ZDockerActive -b "jumpscale/js9_tarantool" -i js9_tarantool && return 0

    ZDockerActive -b "jumpscale/js9_full" -c "ZInstall_js9_full" -i js9_tarantool || return 1

    echo "[+] initializing jumpscale"
    container 'js9_init' || return 1
    container 'apt update; apt upgrade -y'

    echo "[+] install extra's for tarantool"

    container 'js9 "j.tools.prefab.local.db.tarantool.install()"' || return 1

    ZDockerCommit -b jumpscale/js9_tarantool || die "docker commit" || return 1


}


ZInstall_ays9() {

    local OPTIND
    local force=0
    local branch=${JS9BRANCH:-development}
    local addargs=''

    while getopts ":f:b:a:" opt; do
        case "${opt}" in
           a ) addargs="${OPTARG}";;
           f )  ZDockerRemoveImage jumpscale/ays9 ;;
           b ) branch="${OPTARG}";;
        esac
    done
    ZDockerActive -b "jumpscale/ays9" -i ays9 -a "$addargs" && return 0

    ZDockerActive -b "jumpscale/js9_full" -c "ZInstall_js9_full -f" -i ays9 || return 1

    if ZDoneCheck "ZInstall_js9_ays9" ; then
        echo "[+] install ays9 already done."
       return 0
    fi
    ZDoneUnset "ZInstall_js9"
    local port=${RPORT:-2222}
    local addarg="${RNODE:-localhost}"
    echo "[+] install AYS9"
    echo "[+] loading or updating AYS source code (branch:$branch)"
    ZCodeGetJS -r ays9 -b $branch || return 1
    echo "[+] installing jumpscale ays9"
    ZNodeSet $addarg  || return 1
    ZNodePortSet $port || return 1
    container "cd  /opt/code/github/jumpscale/ays9 && bash install.sh;" || return 1
    container "js9_init" || return 1

    ZDockerCommit -b jumpscale/ays9 -s || die "docker commit" || return 1

}

ZInstall_portal9() {

    local OPTIND
    local branch=${JS9BRANCH:-development}
    local addargs=''
    local fullinstall=0

    while getopts ":a:b:u" opt; do
        case "${opt}" in
           a ) addargs="${OPTARG}";;
           b ) branch="${OPTARG}";;
           u ) fullinstall=1
        esac
    done

    if [ "$fullinstall" == 1 ]; then
        ZDockerActive -b "jumpscale/js9all" -i js9all -a "$addargs" && return 0
        ZDockerActive -b "jumpscale/ays9" -c "ZInstall_ays9 -f" -i js9all || return 1
    else
        ZDockerActive -b "jumpscale/portal9" -i portal9 -a "$addargs" && return 0
        ZDockerActive -b "jumpscale/js9_full" -c "ZInstall_js9_full -f" -i portal9 || return 1
    fi
    
    local port=${RPORT:-2222}
    local addarg="${RNODE:-localhost}"
    echo "[+] install Portal9"
    echo "[+] loading or updating Portal source code (branch:$branch)"
    ZCodeGetJS -r portal9 -b ${branch}  || return 1

    echo "[+] installing jumpscale portal9"
    ZNodeSet $addarg || return 1
    ZNodePortSet $port || return 1
    container "cd  /opt/code/github/jumpscale/portal9 && bash install.sh ${JS9BRANCH};" || return 1
    container "js9_init" || return 1

    if [ "$fullinstall" == 1 ]; then
        ZDockerCommit -b jumpscale/js9all -s || die "docker commit" || return 1
    else
        ZDockerCommit -b jumpscale/portal9 -s || die "docker commit" || return 1
    fi

}

ZInstall_js9_all() {

    local OPTIND
    local force=0
    local branch=${JS9BRANCH:-development}
    local addargs=''

    while getopts ":f:b:a:" opt; do
        case "${opt}" in
            a ) addargs="${OPTARG}";;
            f )  ZDockerRemoveImage jumpscale/js9all ;;
            b ) branch="${OPTARG}";;
        esac
    done
    ZDockerActive -b "jumpscale/js9all" -i js9all -a "$addargs" && return 0

    ZInstall_portal9  -u -a $addargs -b $branch

}
ZInstallCrmUsage() {
   cat <<EOF
Usage: ZInstallCrm [-p caddyport] [-D dbname] [-u url] [-o organization_id] [-s client_secret] [-i iname] [-e email] [-d]
   -p caddyport: tcp port which caddy will listen to. (default: 80)
   -i iname: name of container which will have the crm installed (default: crm)
   -D dbname: postgres database name to create (default:crm)
   -o organization: client id of organization
   -s secretid: client secret of organization
   -u url: url
   -e email: email used by let's encrypt to generate certificate
   -d: install demo data
   -m: sendgrid_api_key: sendfrid api key
   -z: support_email: Support email
   -h: help

will install crm application in js9 container

EOF
}

ZInstall_crm() {

    #install & configure caddy (make IYO integration optional, option to this method)  (prefab)
    #caddy is proxy to crm (prefab)
    #use postgresql as backend (root/rooter is ok) (prefab)
    #start all in tmux (prefab)

    local OPTIND
    local caddyport=80
    local dbname=crm
    local iname=crm
    local demo=False
    local client_id=""
    local client_secret=""
    local url="localhost"
    local email="off"
    local sendgrid_api_key=""
    local support_email=""
    while getopts "p:D:o:s:u:i:e:dh" opt; do
        case $opt in
           p )  caddyport=$OPTARG ;;
           D )  dbname=$OPTARG ;;
           o )  client_id=$OPTARG ;;
           s )  client_secret=$OPTARG ;;
           u )  url=$OPTARG ;;
           i )  iname=$OPTARG ;;
           e )  email=$OPTARG ;;
           d )  demo=True ;;
           m )  sendgrid_api_key=$OPTARG ;;
           z )  support_email=$OPTARG ;;
           h )  ZInstallCrmUsage ; return 0 ;;
           \? )  ZInstallCrmUsage ; return 1 ;;
        esac
    done

    install_args="caddy_port=$caddyport, db_name=\"$dbname\", demo=$demo,\
    start=True, client_id=\"$client_id\", client_secret=\"$client_secret\", domain=\"$url\", tls=\"$email\"";
    start_args="db_name=\"$dbname\",sendgrid_api_key=\"$sendgrid_api_key\",support_email=\"$support_email\",domain=\"$domain\"";
    start_cmd="python3 -c 'from js9 import j;j.tools.prefab.local.apps.crm.start($start_args)'"
    install_cmd="python3 -c 'from js9 import j;j.tools.prefab.local.apps.crm.install($install_args)'"

    ports="-p $caddyport:$caddyport -p 25:25"
    # if caddy port is 443 we must expose port 80 also to be able to generate ssl
    if [[ ${caddyport} == 443 ]];then
        ports="$ports -p 80:80"
    fi
    ZDockerActive -b "jumpscale/crm" -i $iname -a "${ports}" && container "$start_cmd" && return 0

    ZDockerActive -b "jumpscale/js9_docgenerator" -a "${ports}" -c "ZInstall_docgenerator" -i $iname || return 1

    echo "[+] Installing CRM"
    container "$install_cmd" || return 1

    ZDockerCommit -b jumpscale/crm || die "docker commit" || return 1

}

ZInstall_issuemanager() {

    ZDockerActive -b "jumpscale/issuemanager" -i issuemanager && container 'python3 -c "from js9 import j;j.tools.prefab.local.apps.issuemanager.start()"' && return 0

    ZDockerActive -b "jumpscale/portal9" -c "ZInstall_portal9 -f" -i issuemanager || return 1

    echo "[+] Installing IssueManager"
    container 'python3 -c "from js9 import j;j.tools.prefab.local.apps.issuemanager.install()"' || return 1
    container 'python3 -c "from js9 import j;j.tools.prefab.local.apps.issuemanager.start()"' || return 1

    ZDockerCommit -b jumpscale/issuemanager || die "docker commit" || return 1

}

ZInstall_zerotier() {
    ZDockerRunUbuntu ||  return 1
    container "apt-get install gpgv2 -y" || return 1
    container "curl -s 'https://pgp.mit.edu/pks/lookup?op=get&search=0x1657198823E52A61' | gpg --import" || return 1
    container "curl -s https://install.zerotier.com/ | bash || true" || return 1
}

# ZInstall_openvpn() {
#     echo "[+] install openvpn docker"
#     mkdir -p /etc/ovpn
#     docker run --name=openvpn-as -p 8081:80 -v /etc/ovpn:/config -e INTERFACE=eth0 --net=host --privileged linuxserver/openvpn-as
# # -e PGID=<gid> -e PUID=<uid> \
# # -e TZ=<timezone> \
# # -e INTERFACE=<interface> \
# # --net=host --privileged \
# # linuxserver/openvpn-as
# }


# This will install issue manager and sync data from gogs
ZInstall_issuemanager_full(){

    ZDockerActive -b "jumpscale/issuemanager_full" -i issuemanager_full && container 'python3 -c "from js9 import j;j.tools.prefab.local.apps.issuemanager.start()"' && return 0

    ZDockerActive -b "jumpscale/issuemanager" -c "ZInstall_issuemanager -f" -i issuemanager_full || return 1

    container 'python3 -c "from js9 import j;j.tools.prefab.local.apps.issuemanager.start()"' || return 1

    local type="gogs"
    local reponame="cockpit_issue_manager"
    local account="gig"
    local giturl="ssh://git@docs.greenitglobe.com:10022/gig/cockpit_issue_manager.git"

    echo "[+] Cloning cockpit issuemanager repository"
    if [ -n $GOGS_SSHKEY ]; then
        ZCodeGet -t $type -r $reponame -a $account -u $giturl -k $GOGS_SSHKEY || return 1
    else
        ZCodeGet -t $type -r $reponame -a $account -u $giturl || return 1
    fi

    sleep 20

    echo "[+] Syncing data from gogs"
    ssh -tA root@localhost -p 2222 "cd /opt/code/gogs/gig/cockpit_issue_manager; python3 syncData.py ${GOGSDB_PASS}" || die "Faield to sync data from gogs" || return 1

    ZDockerCommit -b jumpscale/issuemanager_full || die "docker commit" || return 1

    ZDoneSet "ZInstall_js9_issuemanager_full"
}
