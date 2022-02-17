#!/usr/bin/env bash
#build script as LLVM Build Script.
git clone https://github.com/rubyzee/llvmTC $(pwd)/llvmTC -b master
cd $(pwd)/llvmTC
bash build-tc.sh
