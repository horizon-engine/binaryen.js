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

force="false"
while getopts "f" opt; do
  case "$opt" in
    f) force="true" ;;
    *) echo "Usage: $0 [-f]"; exit 1 ;;
  esac
done

rm -rf ./binaryen

# Get the latest version of binaryen
tag=$(git ls-remote --tags --sort='v:refname' https://github.com/WebAssembly/binaryen.git | tail -n1 | sed 's/.*\///')
version=$(echo "$tag" | sed 's/[^0-9]//g')
if [ -z "$version" ]; then
    echo "Error: No numbers found in tag '$tag'" >&2
    exit 1
fi
version="${version}.0.0"

current_version=$(sed -n '2p' package.json | sed 's/.*"version": "\(.*\)".*/\1/')
if [ "$version" = "$current_version" ] && [ "$force" = "false" ]; then
    echo "binaryen.js is already up to date, run with -f to force a rebuild"
    exit 0
fi

{
    echo '{'
    echo "  \"version\": \"$version\","
    tail -n +3 package.json
} > package.json.tmp
mv package.json.tmp package.json

git clone --branch "$tag" --depth 1 --recurse-submodules --shallow-submodules https://github.com/WebAssembly/binaryen.git

cd ./binaryen

if ! (emcmake cmake -DBUILD_FOR_BROWSER=ON -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF -DCMAKE_EXE_LINKER_FLAGS="-sSINGLE_FILE" -DENABLE_WERROR=OFF . && emmake make); then
    cd ..
    rm -rf ./binaryen
    exit 1
fi
cd ..

rm -f ./index.js && npm install && npm run bundle && rm -rf ./binaryen && printf_green "Successfully built binaryen.js\n"
