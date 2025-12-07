# 16KB Page Alignment Fix for Android 15+

## Background

Starting November 1, 2025, Google Play requires all apps targeting Android 15+ to support 16KB page sizes. The original PyTorch Android libraries were compiled with 4KB page alignment, which doesn't meet this requirement.

## Problem

The following native libraries in the standard PyTorch Android packages don't support 16KB alignment:
- `libpytorch_jni_lite.so`
- `libfbjni.so`
- `libc++_shared.so`
- `libpytorch_vision_jni.so`

## Solution

This plugin now uses locally bundled `.aar` files with proper 16KB alignment support.

### What's Been Fixed

1. **Updated AAR Files**: The plugin now includes:
   - `android/libs/pytorch_android-release.aar` (16KB aligned)
   - `android/libs/pytorch_android_torchvision-release.aar` (16KB aligned)

2. **Updated Dependencies**: The `android/build.gradle` has been configured to:
   - Use local `.aar` files instead of Maven Central versions
   - Include required Java-side helpers: `fbjni-java-only` and `nativeloader`

### Verification

You can verify the alignment of the native libraries using:

```bash
cd /tmp && mkdir check_aar && cd check_aar
unzip /path/to/pytorch_android-release.aar
readelf -l jni/arm64-v8a/libpytorch_jni_lite.so | grep LOAD
```

Look for `0x4000` (16KB) in the alignment column. Example output:
```
  LOAD           0x0000000000000000 0x0000000000000000 0x0000000000000000
                 0x0000000003ddfbb0 0x0000000003ddfbb0  R E    0x4000
```

The `0x4000` confirms 16KB alignment.

## For Users of This Plugin

### Using in Your Flutter App

In your `pubspec.yaml`, reference this fixed version:

```yaml
dependencies:
  pytorch_lite:
    git:
      url: https://github.com/Zwani/pytorch_lite.git
      ref: main  # or specific commit/tag
```

### Building Your App

No special configuration needed! The plugin handles everything automatically.

### Testing Alignment

To test your APK/AAB for 16KB compliance:

1. Build your app
2. Use Google's alignment check tool or:

```bash
# For APK
unzip your_app.apk
readelf -l lib/arm64-v8a/libpytorch_jni_lite.so | grep LOAD

# For AAB
bundletool build-apks --bundle=your_app.aab --output=output.apks
unzip output.apks
# Then check the .so files
```

## Credits

The 16KB-aligned `.aar` files are based on community contributions addressing [PyTorch Issue #154449](https://github.com/pytorch/pytorch/issues/154449), particularly:
- [@vishal-sehgal](https://github.com/vishal-sehgal/pytorch) - Pre-built 16KB aligned AARs
- [@vivascu](https://github.com/pytorch/pytorch/pull/162605) - PR for 16KB alignment support

## References

- [Google Guide: 16KB Page Sizes](https://developer.android.com/guide/practices/page-sizes)
- [Google Blog: 16KB Page Size Requirement](https://android-developers.googleblog.com/2024/12/get-your-apps-ready-for-16-kb-page-size-devices.html)
- [PyTorch Issue #154449](https://github.com/pytorch/pytorch/issues/154449)
