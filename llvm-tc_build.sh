#!/usr/bin/env bash
#build script as LLVM Build Script.
git clone https://github.com/alicedump/llvmTC $(pwd)/llvmTC -b x86
cd $(pwd)/llvmTC
bash build-tc.sh
