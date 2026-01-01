#!/bin/sh

RED=""
GREEN=""
RESET=""
supports_color() {
    if [ -z "$(command -v tput)" ]; then
        return 1
    fi
    tty >/dev/null 2>&1 || return 1
    [ -n "$TERM" ] || return 1
    [ "$TERM" != "dumb" ] || return 1
    command -v tput >/dev/null 2>&1 || return 1
    ncolors=$(tput colors 2>/dev/null)
    [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]
}
if supports_color; then
    RED=$(printf '\033[31m')
    GREEN=$(printf '\033[32m')
    RESET=$(printf '\033[0m')
fi

printf_red() {
    fmt="$1"
    shift
    printf '%s' "$RED"
    printf "$fmt" "$@"
    printf '%s\n' "$RESET"
}

printf_green() {
    fmt="$1"
    shift
    printf '%s' "$GREEN"
    printf "$fmt" "$@"
    printf '%s\n' "$RESET"
}

if ! command -v git >/dev/null 2>&1; then
    printf_red "git is not installed"
    exit 1
fi
if ! command -v emcmake >/dev/null 2>&1; then
    printf_red "emcmake is not installed"
    exit 1
fi
if ! command -v cmake >/dev/null 2>&1; then
    printf_red "cmake is not installed"
    exit 1
fi
if ! command -v emmake >/dev/null 2>&1; then
    printf_red "emmake is not installed"
    exit 1
fi
if ! command -v make >/dev/null 2>&1; then
    printf_red "make is not installed"
    exit 1
fi

rm -rf ./binaryen
git clone https://github.com/WebAssembly/binaryen.git
cd ./binaryen
# binaryen version 125
git checkout 6ec7b5f9c615d3b224c67ae221d6812c8f8e1a96
git submodule update --init --recursive
cd ..

# replace the binaryen.js-post.js file in the binaryen repo with the local patched version
rm ./binaryen/src/js/binaryen.js-post.js
cp ./patches/binaryen.js-post.js ./binaryen/src/js/binaryen.js-post.js

cd ./binaryen

if ! (emcmake cmake -DBUILD_FOR_BROWSER=ON -DBUILD_TESTS=OFF . && emmake make); then
    cd ..
    rm -rf ./binaryen
    exit 1
fi
cd ..

rm -f ./index.js

npm install
npm run bundle

rm -f ./bin/wasm-as
rm -f ./bin/wasm-ctor-eval
rm -f ./bin/wasm-dis
rm -f ./bin/wasm-merge
rm -f ./bin/wasm-metadce
rm -f ./bin/wasm-opt
rm -f ./bin/wasm-reduce
rm -f ./bin/wasm-shell
rm -f ./bin/wasm2js

mv ./binaryen/bin/wasm-as.wasm ./bin/wasm-as
mv ./binaryen/bin/wasm-ctor-eval.wasm ./bin/wasm-ctor-eval
mv ./binaryen/bin/wasm-dis.wasm ./bin/wasm-dis
mv ./binaryen/bin/wasm-merge.wasm ./bin/wasm-merge
mv ./binaryen/bin/wasm-metadce.wasm ./bin/wasm-metadce
mv ./binaryen/bin/wasm-opt.wasm ./bin/wasm-opt
mv ./binaryen/bin/wasm-reduce.wasm ./bin/wasm-reduce
mv ./binaryen/bin/wasm-shell.wasm ./bin/wasm-shell
mv ./binaryen/bin/wasm2js.wasm ./bin/wasm2js

rm -rf ./binaryen

printf_green "Successfully built patched binaryen.js\n"
