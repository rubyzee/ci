#!/usr/bin/env bash
#build script as LLVM Build Script.
git clone https://github.com/alicedump/llvmTC $(pwd)/llvmTC -b main
cd $(pwd)/llvmTC
bash build-tc.sh
