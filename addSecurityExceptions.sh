#!/bin/bash
args=`getopt f:k::d::s:: $*`

if [[ $1 == "" ]];
then
  echo "No file apk supplied"
  echo "Usage: ./addSecurityExceptions.sh <apk_filename>"
  exit 2
fi
set -- $args

# extract options and their arguments into variables.
for i
do
  echo $i
  case "$i" in
      -f) FILE=$2 ; shift ;;
      -k) KEYSTORE=$3 ; shift ;;
      -d) TMPDIR=$4 ; shift ;;
      -s) SUFFIX="$5" ; shift ;;
      --) shift ; break ;;
  esac
done

if ! type apktool > /dev/null; then
  echo "Please install apktool"
  echo "[Mac OS] Using Homebrew: 'brew install apktool'"
  echo "[Other] https://ibotpeaches.github.io/Apktool/install/"
  exit -1
fi

if [ -z "$KEYSTORE" ]; then
  KEYSTORE="~/.android/debug.keystore"
fi

if [ -z "$TMPDIR" ]; then
  TMPDIR="/tmp/"
fi

if [ -z "$SUFFIX" ]
  then
    SUFFIX="_new.apk"
  else
    SUFFIX="_$SUFFIX.apk"
fi

fullfile=$FILE
filename=$(basename "$fullfile")
extension="${filename##*.}"
filename="${filename%.*}"
tmpDir=$TMPDIR/$filename
filenameSuffix=$SUFFIX

echo "FILE: $FILE"
echo "TMPDIR: $TMPDIR"
echo "KEYSTORE: $KEYSTORE"
echo "SUFFIX: $filenameSuffix"

if [ $KEYSTORE = ~/.android/debug.keystore ]
  then
    if [ ! -f ~/.android/debug.keystore ]; then
      keytool -genkey -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000
    fi
fi

if [ ! -d "$tmpDir/res/xml" ]; then
  mkdir $tmpDir/res/xml
fi

newFileName=$filename$filenameSuffix

apktool d -f -o $tmpDir $fullfile

cp ./network_security_config.xml $tmpDir/res/xml/.
if ! grep -q "networkSecurityConfig" $tmpDir/AndroidManifest.xml; then
  sed -E "s/(<application.*)(>)/\1 android\:networkSecurityConfig=\"@xml\/network_security_config\" \2 /" $tmpDir/AndroidManifest.xml > $tmpDir/AndroidManifest.xml.new
  mv $tmpDir/AndroidManifest.xml.new $tmpDir/AndroidManifest.xml
fi


apktool empty-framework-dir --force $tmpDir
echo "Building new APK $newFileName"
apktool b -o ./$newFileName $tmpDir
jarsigner -verbose -keystore $debugKeystore -storepass android -keypass android ./$newFileName androiddebugkey

