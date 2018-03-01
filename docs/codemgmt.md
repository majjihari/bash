# code management

## principles

- goal is that user has all his repo's in ~/code/$accountname/$reponame independant of type of git
- the user can manually at any point in time change the branch of the repo's (e.g. use tool like sourcetree)
- when updating code it will never try to change the branch, it will pull when repo exists & ignore the specified branch name

## RELEVANT COMMANDS

### ZGetCode

checkout any code

```bash
$ ZGetCode -h
Usage: ZGetCode [-r reponame] [-g giturl] [-a account] [-b branch]
   -a account: will default to 'varia', but can be account name
   -r reponame: name or repo which is being downloaded
   -u giturl: e.g. git@github.com:mathieuancelin/duplicates.git
   -b branchname: defaults to development
   -h: help

checks out any git repo repo to ~/code/$account/$reponame
branchname can optionally be specified.

if specified but repo exists then a pull will be done & branch will be ignored !!!
```

### ZGetCodeJS

checkout specific jumpscale repo's

```bash
$ ZGetCodeJS -h
Usage: ZGetCode [-r reponame] [-g giturl] [-a account] [-b branch]
   -r reponame: name or repo which is being downloaded
   -b branchname: defaults to development
   -h: help

checks out jumpscale repo to ~/code/jumpscale/
branchname can optionally be specified.

if specified but repo exists then a pull will be done & branch will be ignored !!!

if reponame not specified then will checkout
- bash
- lib9
- core9
- ays9
- prefab
```

### ZCodePushJS

very handy shortcut to commit/add/pull & push repos (this case for jumoscale)

```
ZCodePushJS -h
Usage: ZCodePushJS [-r reponame] [-a account] [-m message]
    -r reponame: name or repo
    -m message for commit: required !
    -h: help

    will add/remove files, commit, pull & push
```

### ZCodePush

This case commit/add/pull & push for generic repo;s

```
ZCodePush -h
Usage: ZCodePush [-r reponame] [-a account] [-m message]
  -a account: will default to 'varia', but can be account name
  -r reponame: name or repo
  -m message for commit: required !
  -h: help

  will add/remove files, commit, pull & push
```
