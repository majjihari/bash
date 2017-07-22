# bash
bash utilities

# to install

```
curl https://raw.githubusercontent.com/Jumpscale/bash/master/install.sh?$RANDOM > /tmp/install.sh;bash /tmp/install.sh
```

# to use

```
. /opt/code/github/jumpscale/bash/zlibs.sh || . ~/code/github/jumpscale/bash/zlibs.sh
```

this will source all methods, codecompletion will now work.

# ssh tools

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

# docker tools

```bash
~/code/jumpscale/bash/zlibs.sh
ZDockerBuildJS9 # -f to build full js9 not the minimal
ZDockerRunJS9
```

will install js9 & build docker with ubuntu 17.04 and required tools.

# lede tools

```bash
#configure a remote lede box, first make sure the ZNodeSet ... is done
#will install mc, curl, git, ...
LEDE_Install


```
