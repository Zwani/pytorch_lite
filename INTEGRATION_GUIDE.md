# Integration Guide for mysmartcity App

## Overview

Your `pytorch_lite` plugin is now ready with 16KB page alignment support for Android 15+. Follow these steps to integrate it into your mysmartcity app.

## Step 1: Commit Changes to Your Repository

First, commit all the changes to your pytorch_lite repository:

```bash
cd ~/git_files/public/pytorch_lite

# Check what's been changed
git status

# Add all changes
git add .

# Commit with a descriptive message
git commit -m "Add 16KB page alignment support for Android 15+

- Updated .aar files with 16KB aligned native libraries
- Configured build.gradle to use local .aar files
- Added verification script
- Updated documentation"

# Push to your repository
git push origin main
```

## Step 2: Update Your mysmartcity App

Navigate to your app and update the pubspec.yaml:

```bash
cd ~/git_files/mysmartcity_mobile
```

Your `pubspec.yaml` should already have:

```yaml
dependencies:
  pytorch_lite:
    git:
      url: https://github.com/Zwani/pytorch_lite.git
      ref: main  # or specify a commit hash for stability
```

If you want to use a specific commit (recommended for production):

```yaml
dependencies:
  pytorch_lite:
    git:
      url: https://github.com/Zwani/pytorch_lite.git
      ref: <commit-hash>  # Get this from: git rev-parse HEAD
```

## Step 3: Update Dependencies

```bash
cd ~/git_files/mysmartcity_mobile

# Clean previous builds
flutter clean

# Get updated dependencies
flutter pub get
```

## Step 4: Verify Android Configuration

Check your app's `android/app/build.gradle` to ensure you're targeting the right SDK:

```gradle
android {
    compileSdkVersion 34  // or higher
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34  // or 35 for Android 15
    }
}
```

## Step 5: Build and Test

Build your app to verify everything works:

```bash
# Build for debug
flutter build apk --debug

# Or build for release
flutter build apk --release

# Or build app bundle for Google Play
flutter build appbundle --release
```

## Step 6: Verify 16KB Alignment in Your APK

After building, verify the alignment in your final APK:

```bash
# Extract your APK
cd ~/git_files/mysmartcity_mobile/build/app/outputs/flutter-apk
unzip -q app-release.apk -d extracted_apk

# Check alignment of the native libraries
readelf -l extracted_apk/lib/arm64-v8a/libpytorch_jni_lite.so | grep LOAD

# You should see 0x4000 in the output, confirming 16KB alignment
```

## Step 7: Test on Device

Test your app on an actual device or emulator:

```bash
# Install and run
flutter run --release

# Or just install the APK
flutter install
```

## Troubleshooting

### Issue: "library libpytorch_jni.so not found"

**Solution:** This happens if the old Maven dependencies are still cached. Fix:

```bash
cd ~/git_files/mysmartcity_mobile

# Clean everything
flutter clean
cd android
./gradlew clean
cd ..

# Rebuild
flutter pub get
flutter build apk
```

### Issue: Gradle build fails with dependency conflicts

**Solution:** Ensure your app's `android/build.gradle` doesn't have conflicting PyTorch dependencies:

```gradle
// Remove these if present in your app's build.gradle:
// implementation 'org.pytorch:pytorch_android:2.1.0'
// implementation 'org.pytorch:pytorch_android_torchvision:2.1.0'

// The plugin handles these automatically now
```

### Issue: "zip END header not found" error

**Solution:** The .aar files might be corrupted. Re-download them:

```bash
cd ~/git_files/public/pytorch_lite/android/libs

# Backup existing files
mv pytorch_android-release.aar pytorch_android-release.aar.backup
mv pytorch_android_torchvision-release.aar pytorch_android_torchvision-release.aar.backup

# Download fresh copies from vishal-sehgal's repo
wget https://github.com/vishal-sehgal/pytorch/raw/main/aars/pytorch_android-release.aar
wget https://github.com/vishal-sehgal/pytorch/raw/main/aars/pytorch_android_torchvision-release.aar

# Verify
bash ~/git_files/public/pytorch_lite/verify_16kb_alignment.sh
```

## Verification Checklist

Before submitting to Google Play, verify:

- [ ] Your app builds successfully
- [ ] The app runs on test devices without crashes
- [ ] Native libraries have 16KB alignment (verified with readelf)
- [ ] App targets Android SDK 34 or higher
- [ ] No warnings about page size alignment in build logs

## Google Play Submission

When ready to submit:

1. Build the app bundle:
   ```bash
   flutter build appbundle --release
   ```

2. The bundle will be at:
   ```
   ~/git_files/mysmartcity_mobile/build/app/outputs/bundle/release/app-release.aab
   ```

3. Upload to Google Play Console

4. Google Play will automatically verify 16KB alignment during the review process

## Need Help?

If you encounter issues:

1. Check the verification script output:
   ```bash
   cd ~/git_files/public/pytorch_lite
   bash verify_16kb_alignment.sh
   ```

2. Review the documentation:
   - [16KB_ALIGNMENT_FIX.md](16KB_ALIGNMENT_FIX.md)
   - [Google's 16KB Guide](https://developer.android.com/guide/practices/page-sizes)

3. Check the PyTorch community discussion:
   - [Issue #154449](https://github.com/pytorch/pytorch/issues/154449)
