dpkg --add-architecture i386
rm -rf /usr/share/dotnet /etc/mysql /etc/php /etc/apt/sources.list.d
docker rmi `docker images -q`
apt-get remove account-plugin-facebook account-plugin-flickr account-plugin-jabber account-plugin-salut account-plugin-twitter account-plugin-windows-live account-plugin-yahoo aisleriot brltty duplicity empathy empathy-common example-content gnome-accessibility-themes gnome-contacts gnome-mahjongg gnome-mines gnome-orca gnome-screensaver gnome-sudoku gnome-video-effects gnomine landscape-common libreoffice-avmedia-backend-gstreamer libreoffice-base-core libreoffice-calc libreoffice-common libreoffice-core libreoffice-draw libreoffice-gnome libreoffice-gtk libreoffice-impress libreoffice-math libreoffice-ogltrans libreoffice-pdfimport libreoffice-style-galaxy libreoffice-style-human libreoffice-writer libsane libsane-common mcp-account-manager-uoa python3-uno rhythmbox rhythmbox-plugins rhythmbox-plugin-zeitgeist sane-utils shotwell shotwell-common telepathy-gabble telepathy-haze telepathy-idle telepathy-indicator telepathy-logger telepathy-mission-control-5 telepathy-salut totem totem-common totem-plugins printer-driver-brlaser printer-driver-foo2zjs printer-driver-foo2zjs-common printer-driver-m2300w printer-driver-ptouch printer-driver-splix
git config --global user.name "Egii"
git config --global user.email "regidesoftian@gmail.com"
apt-get -y purge azure-cli ghc* zulu* hhvm llvm* firefox google* dotnet* powershell openjdk* mysql* php*
apt-get clean
apt-get -qq update
apt-get -qq install bc build-essential zip curl libstdc++6 git wget python gcc clang libssl-dev repo rsync flex curl  bison aria2

git config --global color.ui auto

# Telegram
tg() {
    curl -sX POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage \
        -d chat_id="$TG_CHAT_ID" \
        -d parse_mode=html \
        -d disable_web_page_preview=true \
        -d text="$1"
}

tgs() {
    curl -fsSL -X POST -F document=@"$1" https://api.telegram.org/bot"${TG_TOKEN}"/sendDocument \
        -F "chat_id=$TG_CHAT_ID" \
        -F "parse_mode=Markdown" \
        -F "caption=$2"
}


mkdir -p $(pwd)/reep
PATH="$(pwd)/reep:${PATH}"
MAINPATH="$(pwd)"
START=$(date +"%s")
curl https://storage.googleapis.com/git-repo-downloads/repo > $(pwd)/reep/repo
chmod a+rx $(pwd)/reep/repo

mkdir recovery && cd recovery
tg "<b>Recovery-Builder: Starting Sync Manifest</b>"
repo init https://github.com/PitchBlackRecoveryProject/manifest_pb -b android-11.0 --depth=1 --partial-clone --clone-filter=blob:limit=10M --groups=all,-notdefault,-device,-darwin,-x86,-mips
repo sync -j$(nproc --all)
tg "<b>Recovery-Builder: Starting Clone Device Tree</b>"
git clone --depth=4 https://Egii:$GH_TOKEN@github.com/Himemoria/omni_device_merlin -b 11 device/xiaomi/merlin

export ALLOW_MISSING_DEPENDENCIES=true
ALLOW_MISSING_DEPENDENCIES=true
. build/envsetup.sh
lunch omni_merlin-eng
tg "<b>Recovery-Builder: Starting Build</b>"
mka pbrp -j$(nproc --all) | tee out/error.txt

if [ -f out/target/product/merlin/recovery.img ];then
    tg "✅ <b>Build Success</b>%0A- <code>$((DIFF / 60)) minute(s) $((DIFF % 60)) second(s) </code>"
    tgs "recovery.img"
    ZIP_NAME=$(echo PBRP*.zip)
    tgs "${ZIP_NAME}"
elif [ -f out/error.txt ];then
    cd out
    LOG=$(echo error.txt)
    tgs "${lOG}" "*Build failed*"
fi

cd "$MAINPATH"
rm -rf *
END=$(date +"%s")
DIFF=$(($END - $START))
