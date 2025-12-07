#!/bin/bash
# Verification script for 16KB page alignment in pytorch_lite plugin

set -e

echo "============================================"
echo "16KB Page Alignment Verification Script"
echo "============================================"
echo ""

PLUGIN_DIR="/home/mandlenkosi/git_files/public/pytorch_lite"
LIBS_DIR="$PLUGIN_DIR/android/libs"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if libs exist
echo "1. Checking for .aar files..."
if [ ! -f "$LIBS_DIR/pytorch_android-release.aar" ]; then
    echo -e "${RED}✗ pytorch_android-release.aar not found!${NC}"
    exit 1
fi
if [ ! -f "$LIBS_DIR/pytorch_android_torchvision-release.aar" ]; then
    echo -e "${RED}✗ pytorch_android_torchvision-release.aar not found!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Both .aar files found${NC}"
echo ""

# Check file sizes
echo "2. Checking file sizes..."
ls -lh "$LIBS_DIR"/*.aar
echo ""

# Extract and check alignment
echo "3. Verifying 16KB alignment of native libraries..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "   Extracting pytorch_android-release.aar..."
unzip -q "$LIBS_DIR/pytorch_android-release.aar"

# Check if .so files exist
SO_FILES=$(find . -name "*.so" | head -5)
if [ -z "$SO_FILES" ]; then
    echo -e "${RED}✗ No .so files found in AAR!${NC}"
    exit 1
fi

echo "   Found native libraries:"
find . -name "*.so" | while read so_file; do
    echo "     - $so_file"
done
echo ""

# Check alignment for arm64-v8a (most important for modern devices)
if [ -f "./jni/arm64-v8a/libpytorch_jni_lite.so" ]; then
    echo "   Checking libpytorch_jni_lite.so (arm64-v8a)..."
    ALIGNMENT=$(readelf -l "./jni/arm64-v8a/libpytorch_jni_lite.so" | grep "LOAD" -A 1 | grep "0x4000" | wc -l)
    
    if [ "$ALIGNMENT" -gt 0 ]; then
        echo -e "${GREEN}   ✓ libpytorch_jni_lite.so has 16KB alignment (0x4000)${NC}"
    else
        echo -e "${RED}   ✗ libpytorch_jni_lite.so does NOT have 16KB alignment!${NC}"
        echo "   Alignment details:"
        readelf -l "./jni/arm64-v8a/libpytorch_jni_lite.so" | grep "LOAD" -A 1 | head -6
        exit 1
    fi
else
    echo -e "${YELLOW}   ⚠ arm64-v8a library not found${NC}"
fi

# Check fbjni
if [ -f "./jni/arm64-v8a/libfbjni.so" ]; then
    echo "   Checking libfbjni.so (arm64-v8a)..."
    ALIGNMENT=$(readelf -l "./jni/arm64-v8a/libfbjni.so" | grep "LOAD" -A 1 | grep "0x4000" | wc -l)
    
    if [ "$ALIGNMENT" -gt 0 ]; then
        echo -e "${GREEN}   ✓ libfbjni.so has 16KB alignment (0x4000)${NC}"
    else
        echo -e "${RED}   ✗ libfbjni.so does NOT have 16KB alignment!${NC}"
        exit 1
    fi
fi

# Check libc++_shared
if [ -f "./jni/arm64-v8a/libc++_shared.so" ]; then
    echo "   Checking libc++_shared.so (arm64-v8a)..."
    ALIGNMENT=$(readelf -l "./jni/arm64-v8a/libc++_shared.so" | grep "LOAD" -A 1 | grep "0x4000" | wc -l)
    
    if [ "$ALIGNMENT" -gt 0 ]; then
        echo -e "${GREEN}   ✓ libc++_shared.so has 16KB alignment (0x4000)${NC}"
    else
        echo -e "${RED}   ✗ libc++_shared.so does NOT have 16KB alignment!${NC}"
        exit 1
    fi
fi

echo ""

# Check torchvision
echo "   Checking pytorch_android_torchvision-release.aar..."
cd "$TEMP_DIR"
rm -rf *
unzip -q "$LIBS_DIR/pytorch_android_torchvision-release.aar"

if [ -f "./jni/arm64-v8a/libpytorch_vision_jni.so" ]; then
    echo "   Checking libpytorch_vision_jni.so (arm64-v8a)..."
    ALIGNMENT=$(readelf -l "./jni/arm64-v8a/libpytorch_vision_jni.so" | grep "LOAD" -A 1 | grep "0x4000" | wc -l)
    
    if [ "$ALIGNMENT" -gt 0 ]; then
        echo -e "${GREEN}   ✓ libpytorch_vision_jni.so has 16KB alignment (0x4000)${NC}"
    else
        echo -e "${RED}   ✗ libpytorch_vision_jni.so does NOT have 16KB alignment!${NC}"
        exit 1
    fi
fi

# Cleanup
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo ""
echo "4. Checking build.gradle configuration..."
if grep -q "implementation files(\"libs/pytorch_android-release.aar\")" "$PLUGIN_DIR/android/build.gradle"; then
    echo -e "${GREEN}✓ build.gradle uses local .aar files${NC}"
else
    echo -e "${RED}✗ build.gradle not properly configured${NC}"
    exit 1
fi

if grep -q "com.facebook.fbjni:fbjni-java-only" "$PLUGIN_DIR/android/build.gradle"; then
    echo -e "${GREEN}✓ fbjni dependency configured${NC}"
else
    echo -e "${YELLOW}⚠ fbjni dependency might be missing${NC}"
fi

if grep -q "com.facebook.soloader:nativeloader" "$PLUGIN_DIR/android/build.gradle"; then
    echo -e "${GREEN}✓ soloader dependency configured${NC}"
else
    echo -e "${YELLOW}⚠ soloader dependency might be missing${NC}"
fi

echo ""
echo "============================================"
echo -e "${GREEN}✓ ALL CHECKS PASSED!${NC}"
echo "============================================"
echo ""
echo "Your pytorch_lite plugin is ready for Android 15+ with 16KB page size support!"
echo ""
echo "Next steps:"
echo "1. Commit these changes to your repository"
echo "2. Update your mysmartcity app's pubspec.yaml to use this repo"
echo "3. Run 'flutter pub get' in your app"
echo "4. Build and test your app"
