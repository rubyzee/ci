#!/bin/bash

# Just a basic script U can improvise lateron asper ur need xD 

# Function to show an informational message
msg() {
    echo -e "\e[1;32m$*\e[0m"
}

err() {
    echo -e "\e[1;41m$*\e[0m"
}

DATE=$(date +"%F-%S")
START=$(date +"%s")

# Inlined function to post a message
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"
tg_post_msg() {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"

}

tg_post_build() {
	curl --progress-bar -F document=@"$1" "$BOT_MSG_URL" \
	-F chat_id="$TG_CHAT_ID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$3"
}

# Send a notificaton to TG
tg_post_msg "<b>Recovery Compilation Started...</b>%0A<b>DATE : </b><code>$DATE</code>%0A"
apt-get -y update && apt-get -y upgrade
apt-get install openssh-server -y
apt-get update --fix-missing
mkdir ~/ofox && cd ~/ofox

repo init --depth=1 -u https://github.com/PitchBlackRecoveryProject/manifest_pb -b android-11.0
repo sync
git clone --depth=1 https://Egii:$GH_TOKEN@github.com/Himemoria/omni_device_merlin -b 11 device/xiaomi/merlin

export ALLOW_MISSING_DEPENDENCIES=true
. build/envsetup.sh
echo " source build/envsetup.sh done"
lunch omni_merlin-eng || abort " lunch failed with exit status $?"
echo " lunch omni_merlin-eng done"
mka pbrp || abort " mka failed with exit status $?"
echo " mka recoveryimage done"

# Upload zips & recovery.img (U can improvise lateron adding telegram support etc etc)
tg_post_msg "<b>===+++ Uploading Recovery +++===</b>"
echo " ===+++ Uploading Recovery +++==="

# Push Recovery to channel
    cd out/target/product/merlin
    ZIP=$(echo PBRP*.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html"
    curl -F file=@PBRP*.zip https://file.io
