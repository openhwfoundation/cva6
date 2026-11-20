#!/bin/bash

#############################################################################
#
# Copyright 2024 Thales DIS France SAS
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#############################################################################
#
# Original Author: Zbigniew CHAMSKI, Thales Silicon Security
#
# Adapted by Mathieu Gouttenoire, Thales DIS France SAS
#
#############################################################################


# Set the default build directory to build/ if it isn't already set
if [ -z "$BUILD_DIR" ]; then
    export BUILD_DIR="$ROOT_DIR/build"
fi

# Set the default source directory to src/ if it isn't already set
if [ -z "$SRC_DIR" ]; then
    export SRC_DIR="$ROOT_DIR/src"
fi

# Provide a means of throttling parallel 'make' executions.
# Use a conservative setting to avoid overloading the host machine.
if [ -z "$NUM_JOBS" ]; then
    NUM_JOBS=1
fi


# Name of the source directories
BINUTILS_DIR=binutils-gdb
GCC_DIR=gcc
LLVM_DIR=llvm-project
NEWLIB_DIR=newlib

# Address of the Git repositories
BINUTILS_REPO=https://sourceware.org/git/binutils-gdb.git
GCC_REPO=https://github.com/gcc-mirror/gcc.git
LLVM_REPO=https://github.com/llvm/llvm-project.git
NEWLIB_REPO=https://sourceware.org/git/newlib-cygwin.git


BINUTILS_CONFIGURE_OPTS() {
    OPTS=(
        --target=$1
        --prefix=${INSTALL_DIR}
        --disable-werror
        --disable-gdb
        --disable-nls
        --disable-sim
        --disable-libdecnumber
        --disable-readline
    )
    echo "${OPTS[@]}"
}

GCC_CONFIGURE_OPTS() {
    OPTS=(
        --prefix=${INSTALL_DIR}
        --target=riscv-none-elf
        --enable-languages=c
        --disable-libssp
        --disable-libgomp
        --disable-libmudflap
    )
    echo "${OPTS[@]}"
}

LLVM_CONFIGURE_OPTS() {
    OPTS=(
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}
        -DLLVM_ENABLE_PROJECTS='clang;lld'
        -DLLVM_BINUTILS_INCDIR=${SRC_DIR}/${BINUTILS_DIR}/include
        -DLLVM_DISTRIBUTION_COMPONENTS='clang;clang-resource-headers;lld;llvm-ar;llvm-cov;llvm-cxxfilt;llvm-dwp;llvm-nm;llvm-objcopy;llvm-objdump;llvm-ranlib;llvm-readobj;llvm-size;llvm-strings;llvm-strip;llvm-profdata;llvm-symbolizer'
        -DLLVM_TARGETS_TO_BUILD='RISCV'
        -DLLVM_OPTIMIZED_TABLEGEN=ON
        -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON
        -DLLVM_INSTALL_BINUTILS_SYMLINKS=ON
    )
    echo "${OPTS[@]}"
}

NEWLIB_CONFIGURE_OPTS() {
    OPTS=(
        --target=$1
        --prefix=${INSTALL_DIR}
        --enable-multilib
        --enable-newlib-io-long-double
        --enable-newlib-io-long-long
        --enable-newlib-io-c99-formats
        --enable-newlib-register-fini
    )
    echo "${OPTS[@]}"
}

COMPILER_RT_CONFIGURE_OPTS() {
    OPTS=(
        -DCMAKE_INSTALL_PREFIX=$(${INSTALL_DIR}/bin/clang -print-resource-dir)
        -DCMAKE_C_COMPILER=${INSTALL_DIR}/bin/clang
        -DCMAKE_CXX_COMPILER=${INSTALL_DIR}/bin/clang
        -DCMAKE_AR=${INSTALL_DIR}/bin/llvm-ar
        -DCMAKE_NM=${INSTALL_DIR}/bin/llvm-nm
        -DCMAKE_RANLIB=${INSTALL_DIR}/bin/llvm-ranlib
        -DCMAKE_C_COMPILER_TARGET=$1
        -DCMAKE_CXX_COMPILER_TARGET=$1
        -DCMAKE_ASM_COMPILER_TARGET=$1
        -DCMAKE_EXE_LINKER_FLAGS=-nostdlib
        -DLLVM_CONFIG_PATH=${BUILD_DIR}/llvm/bin/llvm-config
        -DCOMPILER_RT_BAREMETAL_BUILD=ON
        -DCOMPILER_RT_BUILD_BUILTINS=ON
        -DCOMPILER_RT_BUILD_LIBFUZZER=OFF
        -DCOMPILER_RT_BUILD_MEMPROF=OFF
        -DCOMPILER_RT_BUILD_PROFILE=OFF
        -DCOMPILER_RT_BUILD_SANITIZERS=OFF
        -DCOMPILER_RT_BUILD_XRAY=OFF
        -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON
        -DCOMPILER_RT_OS_DIR=
    )
    echo "${OPTS[@]}"
}

