#!/bin/bash
set -e

ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
export SSHKEYNAME=id_rsa
echo "Using JS9BRANCH: ${JS9BRANCH}"
sudo -HE bash install.sh
sudo -HE bash -c "source /opt/code/github/jumpscale/bash/zlibs.sh; ZKeysLoad; ZCodeGetJS"
sudo -HE bash -c "source /opt/code/github/jumpscale/bash/zlibs.sh; ZKeysLoad; ZDockerInstallLocal"
sudo -HE bash -c "source /opt/code/github/jumpscale/bash/zlibs.sh; ZKeysLoad; ZInstall_js9_full"
