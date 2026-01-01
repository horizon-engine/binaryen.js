# Quick and dirty binaryen.js fork until upstream is up to date

## This includes modifications to both Binaryen and the Binaryen.js wrapper

# Building instructions:

`./build.sh`

# Usage:

The `./build.sh` command will build the modified version of binaryen and binaryen.js
This repo can then be used as a JS library directly with the git link.

# ⚠️ This is a quick and dirty repo, so we don't use github Actions, please run the build command before every commit ⚠️

In order to reduce the size of the repo, the `./build.sh` command will clone, patch, and build binaryen,
then build binaryen.js from the patched binaryen.

### This repo is under the Apache 2.0 License
