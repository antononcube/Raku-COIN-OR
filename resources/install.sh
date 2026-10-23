#!/usr/bin/env sh
# Install CBC/COIN-OR dependencies and this local Raku distribution.
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if ! command -v zef >/dev/null 2>&1; then
    echo 'zef is required. Install a Raku distribution with zef, then rerun this script.' >&2
    exit 1
fi

case "$(uname -s)" in
    Darwin)
        if ! command -v brew >/dev/null 2>&1; then
            echo 'Homebrew is required on macOS: https://brew.sh/' >&2
            exit 1
        fi
        brew install coinutils clp cbc ipopt
        export COIN_OR_CBC_LIBRARY="$(brew --prefix cbc)/lib/libCbcSolver.dylib"
        ;;
    Linux)
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y coinor-cbc coinor-libcbc-dev \
                coinor-clp coinor-libclp-dev coinor-ipopt coinor-libipopt-dev
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --needed --noconfirm coin-or-cbc coin-or-clp coin-or-ipopt
        else
            echo 'Unsupported Linux package manager; install CBC and its development files, then run: zef install .' >&2
            exit 1
        fi
        ;;
    *)
        echo 'Use resources/install-windows.ps1 on Windows.' >&2
        exit 1
        ;;
esac

zef install "$repository_root"
echo 'COIN-OR installed successfully.'
