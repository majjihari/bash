#!/bin/bash
set -e

sudo ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
export SSHKEYNAME=id_rsa

export ZUTILSBRANCH=${ZUTILSBRANCH:-master}
export JS9BRANCH=${JS9BRANCH:-master}

sudo -E bash install.sh
sudo -HE bash -c "source /opt/code/github/jumpscale/bash/zlibs.sh; ZKeysLoad; ZCodeGetJS"
sudo -HE bash -c "source /opt/code/github/jumpscale/bash/zlibs.sh; ZKeysLoad; ZDockerInstallLocal"
sudo -HE bash -c "source /opt/code/github/jumpscale/bash/zlibs.sh; ZKeysLoad; ZInstall_js9_full"
