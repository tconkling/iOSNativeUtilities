#!/bin/sh
set -e

if [ ! -d "$FLEX_HOME" ]; then
    echo "\$FLEX_HOME is not set"
    exit 1
fi

# Get the project root directory
ROOT="`( cd \`dirname \"$0\"\`/.. && pwd )`"

ETC="$ROOT/etc"
DIST="$ROOT/dist"
AS_SRC="$ROOT/NativeUtilsAS/src"
XCODE_SRC="$ROOT/NativeUtilsXcode"

mkdir -p "$DIST"

pushd "$DIST" > /dev/null # quiet pushd output

mkdir -p ios
mkdir -p default

# compile NativeUtilsAS.swc
"$FLEX_HOME"/bin/acompc \
    +flexlib="$FLEX_HOME/frameworks" \
    -compiler.source-path="$AS_SRC" \
    -compiler.debug=false \
    -compiler.accessible=false \
    -include-sources="$AS_SRC" \
    -swf-version 13 \
    -output=NativeUtilsAS.swc

# compile libNativeUtils.a
xcodebuild -project "$XCODE_SRC/NativeUtils.xcodeproj" \
    -scheme NativeUtils \
    -configuration Release \
    clean build \
    SYMROOT="$DIST"

cp Release-iphoneos/libNativeUtils.a ios/

unzip -oqq NativeUtilsAS.swc
rm -f catalog.xml
cp "$ETC/library.swf" ios/library.swf
cp "$ETC/library.swf" default/library.swf

# compiling ane
"$FLEX_HOME/bin/adt" \
    -package \
    -target ane \
    NativeUtils.ane "$ETC/extension.xml" \
    -swc NativeUtilsAS.swc \
    -platform iPhone-ARM -C ios library.swf libNativeUtils.a -platformoptions "$ETC/ios-platformoptions.xml" \
    -platform default library.swf

popd > /dev/null
