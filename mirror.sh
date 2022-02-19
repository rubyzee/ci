#!/usr/bin/env bash
mkdir $(pwd)/aosp
cd $(pwd)/aosp
curl https://raw.githubusercontent.com/aliciahouse/Scripts/master/aosp-mirror.sh > mirror.sh 
bash mirror.sh
