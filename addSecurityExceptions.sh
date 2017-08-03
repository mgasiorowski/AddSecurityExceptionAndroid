#!/bin/bash

if ! type apktool > /dev/null; then
  echo "Please install apktool"
  echo "[Mac OS] Using Homebrew: 'brew install apktool'"
  echo "[Other] https://ibotpeaches.github.io/Apktool/install/"
  exit -1
fi

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    echo "Usage: ./addSecurityExceptions.sh <apk_filename>"
    exit -1
fi

if [ ! -z "$2" ]
  then
    debugKeystore=$2
  else
    if [ ! -f ~/.android/debug.keystore ]; then
      keytool -genkey -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000
    fi
    debugKeystore=~/.android/debug.keystore
fi

fullfile=$1
filename=$(basename "$fullfile")
extension="${filename##*.}"
filename="${filename%.*}"
fileSuffix="_ssl.apk"
newFileName=$filename$fileSuffix
workingDirectory=`pwd`

if [[ ! -z "${WORKSPACE}" ]]; then
  tmpDir=${WORKSPACE}/.tmp/$filename
else
  tmpDir=.tmp/$filename
fi

apktool d -f -o $tmpDir $fullfile

if [ ! -d "$tmpDir/res/xml" ]; then
  mkdir $tmpDir/res/xml
fi

cp $workingDirectory/network_security_config.xml $tmpDir/res/xml/.
if ! grep -q "networkSecurityConfig" $tmpDir/AndroidManifest.xml; then
  sed -E "s/(<application.*)(>)/\1 android\:networkSecurityConfig=\"@xml\/network_security_config\" \2 /" $tmpDir/AndroidManifest.xml > $tmpDir/AndroidManifest.xml.new
  mv $tmpDir/AndroidManifest.xml.new $tmpDir/AndroidManifest.xml
fi

apktool empty-framework-dir --force $tmpDir
echo "Building new APK $newFileName"
apktool b -o ./$newFileName $tmpDir
jarsigner -verbose -keystore $debugKeystore -storepass android -keypass android ./$newFileName androiddebugkey
