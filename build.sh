dpkg --add-architecture i386
rm -rf /usr/share/dotnet /etc/mysql /etc/php /etc/apt/sources.list.d
docker rmi `docker images -q`
apt-get remove account-plugin-facebook account-plugin-flickr account-plugin-jabber account-plugin-salut account-plugin-twitter account-plugin-windows-live account-plugin-yahoo aisleriot brltty duplicity empathy empathy-common example-content gnome-accessibility-themes gnome-contacts gnome-mahjongg gnome-mines gnome-orca gnome-screensaver gnome-sudoku gnome-video-effects gnomine landscape-common libreoffice-avmedia-backend-gstreamer libreoffice-base-core libreoffice-calc libreoffice-common libreoffice-core libreoffice-draw libreoffice-gnome libreoffice-gtk libreoffice-impress libreoffice-math libreoffice-ogltrans libreoffice-pdfimport libreoffice-style-galaxy libreoffice-style-human libreoffice-writer libsane libsane-common mcp-account-manager-uoa python3-uno rhythmbox rhythmbox-plugins rhythmbox-plugin-zeitgeist sane-utils shotwell shotwell-common telepathy-gabble telepathy-haze telepathy-idle telepathy-indicator telepathy-logger telepathy-mission-control-5 telepathy-salut totem totem-common totem-plugins printer-driver-brlaser printer-driver-foo2zjs printer-driver-foo2zjs-common printer-driver-m2300w printer-driver-ptouch printer-driver-splix
git config --global user.name "Filolia"
git config --global user.email "filolia@proton.me"         
apt-get -y purge azure-cli ghc* zulu* hhvm llvm* firefox google* dotnet* powershell openjdk* mysql* php* 
apt-get clean 
apt-get -qq update
apt-get -qq install bc build-essential zip curl libstdc++6 git wget python gcc clang libssl-dev repo rsync flex curl  bison aria2

git config --global color.ui auto

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
  -d "disable_web_page_preview=true" \
  -d "parse_mode=html" \
  -d text="$1"

}

mkdir -p $(pwd)/reep
PATH="$(pwd)/reep:${PATH}"
MAINPATH="$(pwd)"
START=$(date +"%s")
curl https://storage.googleapis.com/git-repo-downloads/repo > $(pwd)/reep/repo
chmod a+rx $(pwd)/reep/repo

mkdir recovery && cd recovery
tg_post_msg "<b>TWRP-Builder: Starting Sync Manifest</b>"
repo init https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp -b twrp-11 --depth=1 --partial-clone --clone-filter=blob:limit=10M --groups=all,-notdefault,-device,-darwin,-x86,-mips
repo sync -j$(nproc --all)
tg_post_msg "<b>TWRP-Builder: Starting Clone Device Tree</b>"
git clone --depth=4 https://github.com/filolia/omni_device_xiaomi_merlin -b android-11.0 device/xiaomi/merlin

export ALLOW_MISSING_DEPENDENCIES=true
ALLOW_MISSING_DEPENDENCIES=true

. build/envsetup.sh

lunch twrp_merlin-eng

repo sync -j$(nproc --all)
tg_post_msg "<b>TWRP-Builder: Starting Build</b>"
mka recoveryimage -j$(nproc --all) | tee out/error.txt

cd ..

cd recovery/out/target/product/merlin
ZipName="[$(date +"%Y%m%d")]TWRP-merlin.zip"
zip -r9 $ZipName recovery.img
cd "$MAINPATH"

if [ -f recovery/out/target/product/merlin/recovery.img ];then
    tg_post_msg "✅ <b>Build Success</b>%0A- <code>$((DIFF / 60)) minute(s) $((DIFF % 60)) second(s) </code>"
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="✅ Compile took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
elif [ -f recovery/out/error.log ];then
    cd "$MAINPATH/recovery/out"
    LOG=$(echo error.log)
    curl -F document=@$LOG "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="❌ Compilation Failed."
fi

cd "$MAINPATH"
rm -rf *
END=$(date +"%s")
DIFF=$(($END - $START))