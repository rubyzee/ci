#!/usr/bin/env bash
#
# Copyright (C) 2021 a xyzprjkt property
# Copyright (C) 2021 a Panchajanya1999 <rsk52959@gmail.com>
# Copyright (C) 2022 a Himemorii <himemori@mail.com>
#

msg() {
	echo
	echo -e "\e[1;32m$*\e[0m"
	echo
}

# Main Dir Info
KERNEL_ROOTDIR=$(pwd)
CLANG_ROOTDIR=$(pwd)/clang-llvm
GCC64_DIR=$(pwd)/GCC64
GCC32_DIR=$(pwd)/GCC32

msg "|| Started Compilation ||"
git clone --depth=1 https://gitlab.com/dakkshesh07/neutron-clang $CLANG_ROOTDIR
git clone --depth=1 https://github.com/cyberknight777/gcc-arm64 -b master $GCC64_DIR
git clone --depth=1 https://github.com/cyberknight777/gcc-arm -b master $GCC32_DIR

# Main Declaration
MODEL=Redmi 10
DEVICE_CODENAME=selene
DEVICE_DEFCONFIG=selene_defconfig
AK3_BRANCH=selene
KERNEL_NAME=Yukina-Stamine
export KBUILD_BUILD_USER=Himemori
export KBUILD_BUILD_HOST=XZI-TEAM
CLANG_VER="$("$CLANG_ROOTDIR"/bin/clang --version | head -n 1)"
GCC_VER="$("$GCC64_DIR"/bin/aarch64-elf-gcc --version | head -n 1)"
LLD_VER="$("$CLANG_ROOTDIR"/bin/ld.lld --version | head -n 1)"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
DATE2=$(date +"%m%d")
START=$(date +"%s")
DTB=$(pwd)/out/arch/arm64/boot/dts/mediatek/mt6768.dtb
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
DISTRO=$(source /etc/os-release && echo "${NAME}")
export KBUILD_COMPILER_STRING="$CLANG_VER with $GCC_VER"
PATH="${PATH}:${CLANG_ROOTDIR}/bin:${GCC64_DIR}/bin:${GCC32_DIR}/bin"

if [[ "$*" =~ "FullLTO" ]];then
sed -i "s/CONFIG_THINLTO=y/CONFIG_THINLTO=n/" arch/arm64/configs/$DEVICE_DEFCONFIG
git add arch/arm64/configs/$DEVICE_DEFCONFIG && git commit -sm 'defconfig: Disable THINLTO'
fi

#Check Kernel Version
KERVER=$(make kernelversion)

# Set a commit head
COMMIT_HEAD=$(git log --oneline -1)
HEADCOMMITID="$(git log --pretty=format:'%h' -n1)"
HEADCOMMITMSG="$(git log --pretty=format:'%s' -n1)"
CI_BRANCH=$(git rev-parse --abbrev-ref HEAD)
TERM=xterm
PROCS=$(nproc --all)
export CI_BRANCH TERM

## Check for CI
if [ "$CI" ]
then
	if [ "$CIRCLECI" ]
	then
		export KBUILD_BUILD_VERSION=$CIRCLE_BUILD_NUM
		export CI_BRANCH=$CIRCLE_BRANCH
	fi
	if [ "$DRONE" ]
	then
		export KBUILD_BUILD_VERSION=$DRONE_BUILD_NUMBER
		export CI_BRANCH=$DRONE_BRANCH
		export BASEDIR=$DRONE_REPO_NAME # overriding
		export SERVER_URL="${DRONE_SYSTEM_PROTO}://${DRONE_SYSTEM_HOSTNAME}/${AUTHOR}/${BASEDIR}/${KBUILD_BUILD_VERSION}"
	else
		echo "Not presetting Build Version"
	fi
fi

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"

}

# Post Main Information
tg_post_msg "<b>New Kernel Under Compilation</b>%0ADate : <code>$(TZ=Asia/Jakarta date)</code>%0A<code> --- Detail Info About it --- </code>%0A<b>- Docker OS: </b><code>$DISTRO</code>%0A- Kernel Name : <code>${KERNEL_NAME}</code>%0A- Kernel Version : <code>${KERVER}</code>%0A- Builder Name : <code>${KBUILD_BUILD_USER}</code>%0A- Builder Host : <code>${KBUILD_BUILD_HOST}</code>%0A- Pipeline Host : <code>$DRONE_SYSTEM_HOSTNAME</code>%0A- Host Core Count : <code>$PROCS</code>%0A- Compiler Used : <code>${KBUILD_COMPILER_STRING}</code>%0A- Branch : <code>$CI_BRANCH</code>%0A- Top Commit : <code>$COMMIT_HEAD</code>%0A<a href='$SERVER_URL'>Link</a>"

  MAKE+=(
    LD_LIBRARY_PATH="${CLANG_ROOTDIR}/lib64:${LD_LIBRARY_PATH}" \
    CC=${CLANG_ROOTDIR}/bin/clang \
    NM=${CLANG_ROOTDIR}/bin/llvm-nm \
    CXX=${CLANG_ROOTDIR}/bin/clang++ \
    AR=${CLANG_ROOTDIR}/bin/llvm-ar \
    LD=${CLANG_ROOTDIR}/bin/ld.lld \
    STRIP=${CLANG_ROOTDIR}/bin/llvm-strip \
    OBJCOPY=${CLANG_ROOTDIR}/bin/llvm-objcopy \
    OBJDUMP=${CLANG_ROOTDIR}/bin/llvm-objdump \
    OBJSIZE=${CLANG_ROOTDIR}/bin/llvm-size \
    READELF=${CLANG_ROOTDIR}/bin/llvm-readelf \
    CROSS_COMPILE_ARM32=arm-eabi- \
    CROSS_COMPILE=aarch64-elf- \
    CLANG_TRIPLE=aarch64-elf- \
    HOSTAR=${CLANG_ROOTDIR}/bin/llvm-ar \
    HOSTLD=${CLANG_ROOTDIR}/bin/ld.lld \
    HOSTCC=${CLANG_ROOTDIR}/bin/clang \
    HOSTCXX=${CLANG_ROOTDIR}/bin/clang++
)

# Compile
compile(){
msg "|| Started Compilation ||"
# cd ${KERNEL_ROOTDIR}
make -j$(nproc) O=out ARCH=arm64 ${DEVICE_DEFCONFIG}
make -j$(nproc) ARCH=arm64 O=out \
         "${MAKE[@]}" 2>&1 | tee error.log

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi

  git clone --depth=1 https://github.com/himemorii/AnyKernel3 -b ${AK3_BRANCH} AnyKernel
    cp $IMAGE AnyKernel
    cp $DTBO AnyKernel
    mv $DTB AnyKernel/dtb
}

# Push kernel to channel
function push() {
    msg "|| Started Uploading ||"
    cd AnyKernel
    ZIP_NAME=[$DATE2][$KERVER]$KERNEL_NAME[$DEVICE_CODENAME][R-OSS]-$HEADCOMMITID.zip
    ZIP=$(echo *.zip)
    MD5CHECK=$(md5sum "${ZIP}" | cut -d' ' -f1)
    SHA1CHECK=$(sha1sum "${ZIP}" | cut -d' ' -f1)
    tg_post_msg "✅ <b>Build Success</b>%0A- <code>$((DIFF / 60)) minute(s) $((DIFF % 60)) second(s) </code>%0A<b>MD5 Checksum</b>%0A- <code>${MD5CHECK}</code>%0A<b>SHA1 Checksum</b>%0A- <code>${SHA1CHECK}</code>%0A<b>Under Commit Id Message</b>%0A- <code>${COMMIT_HEAD}</code>%0A<b>Compilers</b>%0A- <code>$KBUILD_COMPILER_STRING</code>%0A<b>Zip Name</b>%0A- <code>${ZIP_NAME}</code>%0A%0A-- Happy Using --"
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="✅ Compile took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
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
    msg "|| Started Zipping ||"
    cd AnyKernel || exit 1
    zip -r9 [$DATE2][$KERVER]$KERNEL_NAME[$DEVICE_CODENAME][R-OSS]-$HEADCOMMITID.zip *
    cd ..
}
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
