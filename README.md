# Bash
Bash utilities

# Install

Go to terminal (in applications/utils)

```
curl https://raw.githubusercontent.com/Jumpscale/bash/master/install.sh?$RANDOM > /tmp/install.sh;bash /tmp/install.sh
```

result should show
```
[+] Install OK
```

now do ```Command T``` which will open a new tab

all commands are starting with Z, try Z [TAB] should show you

```
kristofs-MBP:~ kristofdespiegeleer$ Z
ZBranchExists                 ZDockerCommit                 ZDockerSSHAuthorize           ZInstall_host_editor          ZNodeSet                      ZSSH_RFORWARD_Usage
ZCodeConfig                   ZDockerCommitUsage            ZDoneCheck                    ZInstall_host_js9             ZNodeUbuntuPrepare            Z_apt_install
ZCodeGet                      ZDockerConfig                 ZDoneReset                    ZInstall_host_js9_full        ZResticBackup                 Z_brew_install
ZCodeGetJS                    ZDockerEnableSSH              ZDoneSet                      ZInstall_issuemanager         ZResticBuild                  Z_exists_dir
ZCodeGetJSUsage               ZDockerImageExist             ZDoneUnset                    ZInstall_js9                  ZResticCheck                  Z_exists_file
ZCodeGetUsage                 ZDockerInstallLocal           ZEXEC                         ZInstall_js9_full             ZResticEnv                    Z_mkdir
ZCodePluginInstall            ZDockerInstallSSH             ZEXECUsage                    ZInstall_js9_node             ZResticEnvReset               Z_mkdir_pushd
ZCodePush                     ZDockerRemove                 ZInstall_DMG                  ZInstall_portal9              ZResticEnvSet                 Z_popd
ZCodePushJS                   ZDockerRemoveImage            ZInstall_ays9                 ZInstall_python               ZResticInit                   Z_pushd
ZCodePushJSUsage              ZDockerRemoveImagesAll        ZInstall_docgenerator         ZInstall_zerotier             ZResticMount                  Z_transcode_mp4
ZCodePushUsage                ZDockerRun                    ZInstall_host_base            ZKeysLoad                     ZResticSnapshots
ZDockerActive                 ZDockerRunSomethingUsage      ZInstall_host_code_jumpscale  ZNodeEnv                      ZSSH
ZDockerActiveUsage            ZDockerRunUbuntu              ZInstall_host_docgenerator    ZNodeEnvDefaults              ZSSHTEST
ZDockerBuildUbuntu            ZDockerRunUsage               ZInstall_host_docker          ZNodePortSet                  ZSSH_RFORWARD
```



# Install from branch

```
export ZUTILSBRANCH=<BRANCH>
export ZBRANCH=<BRANCH>
curl https://raw.githubusercontent.com/Jumpscale/bash/${ZUTILSBRANCH}/install.sh?$RANDOM > /tmp/install.sh;bash /tmp/install.sh
```

what happens
- xcode-tools will be installed & then brew (https://brew.sh/) (osx only)
- python & jumpscale will be installed all in basic version
- ipfs will be installed to make sure all files can be retrieved locally from peer2peer network
- ssh-key will be looked for & created if it doesn't exist yet
- ZBRANCH is the target branch for js9 components, default to master

the basic init script will be added to ~/bash_profile

- when you start a new terminal the tools will be available

After starting new terminal or executing
```bash
source /opt/code/github/jumpscale/bash/zlibs.sh
```
all the avialable installers can be used.

# To install full jumpscale on host machine
```bash
ZInstall_host_js9_full
```
This will install the following:
- Jumpscale core9
- Jumpscale libs9
- Jumpscale prefab9


# To install full jumpscale on a docker

- For OSX make sure docker has been installed !!!
    - https://docs.docker.com/docker-for-mac/install/
- To make sure your sshkeys are loaded/generated
    ```bash
    ZKeysLoad
    ```
 - To get basic jumpscale (core + lib + prefab with all their dependencies)
    ```bash
    ZInstall_js9_full
    ```
 - To get an AYS docker (core + lib + prefab + ays with all their dependencies)
    ```bash
    ZInstall_ays9
    ```
 - To get a portal as well (core + lib + prefab + ays + portal with all their dependencies)
    ```bash
    ZInstall_portal9
    ```
Then start with
```bash
ZDockerActive -b jumpscale/<imagename> -i <name of your docker>
```

# To install all editor tools for local machine

```bash
ZInstaller_editor_host
```

# To get docker on ubuntu

```bash
ZDockerInstallLocal
```

# SSH Tools

```bash
#set node we will work on
ZNodeSet 192.168.10.1

#if different port
ZNodePortSet 2222

#to see which env has been set
ZNodeEnv

#to sync local install bash tools to the remote node
RSync_bash

#to remote execute something
ZEXEC ls /

#to remote execute multiple commands, do not forget the `` IMPORTANT
ZEXEC 'mkdir -p /tmp/1;mkdir -p /tmp/2'

#to remote execute something and make sure bash tools are there & loaded
ZEXEC -b ls /

```

# Docker Tools

```bash
~/code/jumpscale/bash/zlibs.sh
ZDockerBuildJS9 # -f to build full js9 not the minimal
ZDockerRunJS9
```

will install js9 & build docker with ubuntu 17.04 and required tools.

# To manually source the zlibs use

```
#LINUX
. /opt/code/github/jumpscale/bash/zlibs.sh

#OSX
. ~/code/github/jumpscale/bash/zlibs.sh
```

This will source all methods, codecompletion will now work.


# Lede Tools

```bash
#configure a remote lede box, first make sure the ZNodeSet ... is done
#will install mc, curl, git, ...
LEDE_Install


```
