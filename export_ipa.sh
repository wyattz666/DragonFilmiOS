#!/bin/bash
set -e

SCHEME_NAME="DragonFilm"
PROJECT_NAME="DragonFilm.xcodeproj"
BUILD_DIR="./build"
IPA_NAME="DragonFilm.ipa"

if command -v xcodegen &> /dev/null; then
    echo "[INFO] Đang đồng bộ file dự án qua XcodeGen..."
    xcodegen generate > /dev/null 2>&1 || true
fi

echo "[BUILD] Đang build dự án cho iOS Device..."
xcodebuild -project "$PROJECT_NAME" \
           -scheme "$SCHEME_NAME" \
           -sdk iphoneos \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR" \
           CODE_SIGNING_ALLOWED=NO \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGN_IDENTITY="" \
           clean build

echo "[PACKAGE] Đang đóng gói IPA..."
rm -rf ./Payload "$IPA_NAME"
mkdir -p Payload
cp -R "$BUILD_DIR/Build/Products/Release-iphoneos/${SCHEME_NAME}.app" Payload/
zip -r -q "$IPA_NAME" Payload
rm -rf Payload

echo "[SUCCESS] Đã tạo thành công file: $(pwd)/$IPA_NAME"
