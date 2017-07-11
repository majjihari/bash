
### get the docker on which we can do the installers

```bash
ZDockerBuildJS9
```

this will underneith call
- ZInstaller_code_jumpscale
- ...

### get all required code repo's for jumpscale

```bash
#get all jumpscale core repoitories
ZInstaller_code_jumpscale

#if it fails because there is code in your repo's which needs to be committed do:
ZCodePushJS -m "some message for your changes made in code..."
```
