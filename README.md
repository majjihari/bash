# Bash
Bash utilities

# To Install
## 1. Go to your terminal
   * MacOS: Applications → Utilities → Terminal
   * Linux:
       * Unity: open the dash, type `terminal`
       * old style menus: Applications → Accessories → Terminal.
       * Otherwise: Control + Alt + T or Alt + F2, `gnome-terminal`
       * Ubuntu variants: you might need to substitute `gnome-terminal` for `xfce4-terminal`, konsole or `terminator`

 ## 2. Install bash utilities:
   - ### Install from master
     copy/paste into your terminal: `curl https://raw.githubusercontent.com/Jumpscale/bash/master/install.sh?$RANDOM > /tmp/install.sh;bash /tmp/install.sh`

   - ### Install from branch
    ```
    export JS9BRANCH=branchName
    curl https://raw.githubusercontent.com/Jumpscale/bash/master/install.sh?$RANDOM > /tmp/install.sh;bash /tmp/install.sh
    ```

    where `ZUTILSBRANCH` is branch of these utilies you want to install

    what happens:
    - xcode-tools will be installed & then brew (https://brew.sh/) (osx only)
    - ssh-key will be looked for & created if it doesn't exist yet
    - the basic init script will be added to ~/bash_profile

 - If everything installed correctly result should show `[+] Install OK`

 - If install failed with `(13: Permission denied)` you need to install as root. Type `sudo -s` then try install again with the curl command from above.


## 3. Make sure your the bash tools are available
    do this by starting new terminal or executing `source ~/.bash_profile`

    After this you should be able to type Z and press [TAB] to see a list of commands. (NOTE: the Z is uppercase)

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
    *Sometimes the bash profile doesn't load (especially on [Ubuntu](https://askubuntu.com/questions/121413/understanding-bashrc-and-bash-profile)). If that happens type this in a the terminal under root:
    ```
    . ~/.bash_profile
    ```

## 4. Use the bash utlities!

### install jumpscale

```bash
##optional change the branch for js9
#export JS9BRANCH=9.3.0
ZInstall_host_js9
```

### To install full jumpscale on host machine

```bash
##optional change the branch for js9
#export JS9BRANCH=master
ZInstall_host_js9_full
```
This will install the following:
- Jumpscale core9
- Jumpscale libs9
- Jumpscale prefab9


 ### To install full jumpscale in a docker container

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
This might take a while! Don't panic! Wait.
- To get an AYS docker (core + lib + prefab + ays with all their dependencies)
```bash
ZInstall_ays9 [-a "-p 5000:5000" # to expose port 5000 from container]
```
- To get a portal as well (core + lib + prefab + ays + portal with all their dependencies)
```bash
ZInstall_portal9 [-a "-p 8200:8200" # to expose port 8200 from container]
```

Then start with
```bash
ZDockerActive -b jumpscale/<imagename> -i <name of your docker>
```

 - ### To install all editor tools for local machine

    ```bash
    ZInstaller_editor_host
    ```

 - ### To get docker on ubuntu

    ```bash
    ZDockerInstallLocal
    ```

- ### SSH Tools

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

 - ### Lede Tools

    ```bash
    #configure a remote lede box, first make sure the ZNodeSet ... is done
    #will install mc, curl, git, ...
    LEDE_Install
    ```
