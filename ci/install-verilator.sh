#!/bin/bash

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd $ROOT/tmp

if [ -z "$NUM_JOBS" ]; then
    NUM_JOBS=1
fi

VERILATOR_REPO="https://github.com/verilator/verilator.git"
VERILATOR_BRANCH="master"
# Use the release tag instead of a full SHA1 hash.
VERILATOR_HASH="v5.050"

VERILATOR_BUILD_DIR=$PWD/verilator-$VERILATOR_HASH/verilator
VERILATOR_INSTALL_DIR="$(dirname $VERILATOR_BUILD_DIR)"

if [ ! -e "$VERILATOR_INSTALL_DIR/bin/verilator" ]; then
    echo "Building Verilator in $VERILATOR_BUILD_DIR..."
    echo "Verilator will be installed in $VERILATOR_INSTALL_DIR"
    echo "VERILATOR_REPO=$VERILATOR_REPO"
    echo "VERILATOR_BRANCH=$VERILATOR_BRANCH"
    echo "VERILATOR_HASH=$VERILATOR_HASH"
    mkdir -p $VERILATOR_BUILD_DIR
    cd $VERILATOR_BUILD_DIR
    sudo apt install libfl-dev help2man
    [ -d .git ] || git clone $VERILATOR_REPO -b $VERILATOR_BRANCH .
    git checkout $VERILATOR_HASH
    # Generate the config script and configure Verilator.
    autoconf && ./configure --prefix="$VERILATOR_INSTALL_DIR" && make -j${NUM_JOBS}
    # FORNOW: Accept failure in 'make test' (segfault issue on Debian10)
    make test || true
    echo "Installing Verilator in $VERILATOR_INSTALL_DIR..."
    make install
else
    echo "Using Verilator from cached directory $VERILATOR_INSTALL_DIR."
fi

cd $ROOT
