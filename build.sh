#!/usr/bin/env bash
#
# Copyright (C) 2021 a kucingabu property
#

# Main
MainPath="$(pwd)"
MainClangPath="${MainPath}/clang"
MainClangZipPath="${MainPath}/clang-zip"
ClangPath="${MainClangZipPath}"
GCCaPath="${MainPath}/GCC64"
GCCbPath="${MainPath}/GCC32"
MainZipGCCaPath="${MainPath}/GCC64-zip"
MainZipGCCbPath="${MainPath}/GCC32-zip"

ClangPath=${MainClangZipPath}
[[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
mkdir $ClangPath
rm -rf $ClangPath/*
wget -q  https://github.com/ZyCromerZ/Clang/releases/download/15.0.0-20220307-release/Clang-15.0.0-20220307.tar.gz -O "Clang-15.0.0-20220307.tar.gz"
tar -xf Clang-15.0.0-20220307.tar.gz -C $ClangPath

mkdir $GCCaPath
mkdir $GCCbPath
wget -q https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/tags/android-12.0.0_r27.tar.gz -O "gcc64.tar.gz"
tar -xf gcc64.tar.gz -C $GCCaPath
wget -q https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/+archive/refs/tags/android-12.0.0_r27.tar.gz -O "gcc32.tar.gz"
tar -xf gcc32.tar.gz -C $GCCbPath

#Main2
export TZ="Asia/Jakarta"
KERNEL_ROOTDIR=$(pwd) # IMPORTANT ! Fill with your kernel source root directory.
DEVICE_CODENAME=sweet
DEVICE_DEFCONFIG=sweet_defconfig
export KERNEL_NAME=$(cat "arch/arm64/configs/$DEVICE_DEFCONFIG" | grep "CONFIG_LOCALVERSION=" | sed 's/CONFIG_LOCALVERSION="-*//g' | sed 's/"*//g' )
export KBUILD_BUILD_USER=KuroSeinen
export KBUILD_BUILD_HOST=XZI-TEAM
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz
CLANG_VER="$("$ClangPath"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
LLD_VER="$("$ClangPath"/bin/ld.lld --version | head -n 1)"
export KBUILD_COMPILER_STRING="$CLANG_VER with $LLD_VER"
DATE=$(date +"%F-%S")
DATE2=$(date +"%m%d")
START=$(date +"%s")
PATH=${ClangPath}/bin:${GCCaPath}/bin:${GCCbPath}/bin:${PATH}
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img

# Post Main Information
tg_post_msg "<b>KernelCompiler</b>%0AKernel Name : <code>${KERNEL_NAME}</code>%0AKernel Version : <code>${KERVER}</code>%0ABuild Date : <code>${DATE}</code>%0ABuilder Name : <code>${KBUILD_BUILD_USER}</code>%0ABuilder Host : <code>${KBUILD_BUILD_HOST}</code>%0ADevice Defconfig: <code>${DEVICE_DEFCONFIG}</code>%0AClang Version : <code>${KBUILD_COMPILER_STRING}</code>%0AClang Rootdir : <code>${ClangPath}</code>%0AKernel Rootdir : <code>${KERNEL_ROOTDIR}</code>"

# Compile
compile(){
tg_post_msg "<b>KernelCompiler:</b><code>Compilation has started</code>"
cd ${KERNEL_ROOTDIR}
export HASH_HEAD=$(git rev-parse --short HEAD)
export COMMIT_HEAD=$(git log --oneline -1)
make -j$(nproc) O=out ARCH=arm64 $DEVICE_DEFCONFIG
make -j$(nproc) ARCH=arm64 O=out \
    LD_LIBRARY_PATH="${ClangPath}/lib64:${LD_LIBRARY_PATH}" \
    CC=${ClangPath}/bin/clang \
    NM=${ClangPath}/bin/llvm-nm \
    CXX=${ClangPath}/bin/clang++ \
    AR=${ClangPath}/bin/llvm-ar \
    LD=${ClangPath}/bin/ld.lld \
    STRIP=${ClangPath}/bin/llvm-strip \
    OBJCOPY=${ClangPath}/bin/llvm-objcopy \
    OBJDUMP=${ClangPath}/bin/llvm-objdump \
    OBJSIZE=${ClangPath}/bin/llvm-size \
    READELF=${ClangPath}/bin/llvm-readelf \
    CROSS_COMPILE=aarch64-linux-android- \
    CROSS_COMPILE_ARM32=arm-linux-androideabi- \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    HOSTAR=${ClangPath}/bin/llvm-ar \
    HOSTLD=${ClangPath}/bin/ld.lld \
    HOSTCC=${ClangPath}/bin/clang \
    HOSTCXX=${ClangPath}/bin/clang++ \
    2>&1 | tee error.log

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi
  git clone --depth=1 https://github.com/KuroSeinenbutV2/AnyKernel3 AnyKernel
	    cp $IMAGE AnyKernel
        cp $DTBO AnyKernel
}
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="✅Compile took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). | For <b>$DEVICE_CODENAME</b> | <b>${KBUILD_COMPILER_STRING}</b>"
}
# Fin Error
function finerr() {
    LOG=$(echo error.log)
    curl -F document=@$LOG "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="❌ Compilation Failed. | For <b>${DEVICE_CODENAME}</b> | <b>${KBUILD_COMPILER_STRING}</b>"
    exit 1
}

# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 [$VARIANT][$DATE2]$KERNEL_NAME[$DEVICE_CODENAME]${DATE}.zip *
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
