# Google Play Store Submission Checklist

## ✅ Issues Fixed

### 1. **Build Configuration**
- ✅ Fixed duplicate `minSdkVersion` declarations
- ✅ Changed `targetSdk` from 36 to 35 (Android 36 doesn't exist, Android 15 is API 35)
- ✅ Changed `compileSdk` from 36 to 35
- ✅ Removed reference to non-existent `proguard-rules.pro` (since minify is disabled)
- ✅ Created `proguard-rules.pro` file for future use if needed

### 2. **AndroidManifest.xml**
- ✅ Updated application label from "junction" to "Junction"
- ✅ Added `usesCleartextTraffic="false"` for security
- ✅ Fixed duplicate `ACCESS_FINE_LOCATION` permission
- ✅ Updated storage permissions for Android 13+ compatibility:
  - Added `maxSdkVersion` for legacy storage permissions
  - Added `READ_MEDIA_IMAGES` and `READ_MEDIA_VIDEO` for Android 13+
- ✅ Organized permissions with comments

### 3. **Version Information**
- ✅ Version Code: 3 (incremented from 2)
- ✅ Version Name: 1.0.1

---

## ⚠️ Additional Checks Required (Manual)

### 1. **Signing Configuration**
- [ ] Verify `key.properties` file exists and contains:
  - `storeFile` path
  - `keyAlias`
  - `storePassword`
  - `keyPassword`
- [ ] Verify keystore file exists at the specified path
- [ ] **CRITICAL**: Ensure you have the keystore backup saved securely (you'll need it for future updates)

### 2. **Google Maps API Key**
- ⚠️ **Security Warning**: API key is exposed in `AndroidManifest.xml`
- [ ] Verify API key restrictions are set in Google Cloud Console:
  - Restrict by Android app package name: `com.junction`
  - Restrict by SHA-1 certificate fingerprint
  - Consider using separate keys for debug and release builds
- [ ] Add API key restrictions to prevent unauthorized usage

### 3. **Firebase Configuration**
- [ ] Verify `google-services.json` is correct for your app
- [ ] Verify Firebase project is properly configured
- [ ] Check that all Firebase services are enabled in Firebase Console

### 4. **App Bundle vs APK**
- [ ] **Recommended**: Generate an **AAB (Android App Bundle)** instead of APK for Play Store:
  ```bash
  flutter build appbundle --release
  ```
- [ ] APK can be used for internal testing, but AAB is required for production

### 5. **Privacy Policy**
- [ ] Ensure you have a Privacy Policy URL (required by Play Store)
- [ ] Privacy Policy must cover:
  - Data collection (location, camera, contacts, etc.)
  - How data is used
  - Third-party services (Firebase, Google Maps, etc.)
  - Data storage and security

### 6. **Content Rating**
- [ ] Complete content rating questionnaire in Play Console
- [ ] Based on your app features:
  - User-generated content (products, chats)
  - Location sharing
  - Payment processing (Razorpay)
  - Age rating considerations

### 7. **App Store Listing**
- [ ] App name (max 50 characters)
- [ ] Short description (max 80 characters)
- [ ] Full description (max 4000 characters)
- [ ] Screenshots (required):
  - Phone: At least 2, up to 8 screenshots
  - Tablet (if applicable): At least 2 screenshots
  - 7-inch tablet: At least 2 screenshots
  - 10-inch tablet: At least 2 screenshots
- [ ] Feature graphic (1024 x 500 pixels)
- [ ] App icon (512 x 512 pixels, high-res)

### 8. **Permissions Declaration**
- [ ] In Play Console, declare why you need each permission:
  - **CAMERA**: For taking product photos and profile pictures
  - **LOCATION**: For selecting pickup locations for products
  - **STORAGE**: For saving and uploading product images
  - **CONTACTS**: (If used) Declare why you need this
  - **RECORD_AUDIO**: (If used) Declare why you need this

### 9. **Target Audience**
- [ ] Set age-based content rating
- [ ] Define target audience (if applicable)

### 10. **Data Safety Section**
- [ ] Complete Data Safety form in Play Console:
  - What data is collected?
  - How is data used?
  - Is data shared with third parties?
  - Is data encrypted in transit?
  - Can users request data deletion?

### 11. **Testing**
- [ ] Test on multiple Android versions (API 23+)
- [ ] Test on different screen sizes
- [ ] Test all critical features:
  - User registration/login
  - Product listing
  - Chat functionality
  - Location services
  - Image upload
  - Payment flow (if applicable)

### 12. **Build Commands**

**For Release Build (AAB):**
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

**For Release Build (APK - for testing):**
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**For Split APK (smaller size):**
```bash
flutter build apk --split-per-abi --release
```

### 13. **Pre-Launch Checklist**
- [ ] Test the release build thoroughly
- [ ] Verify all API endpoints are working
- [ ] Check backend is production-ready
- [ ] Verify environment variables are set correctly
- [ ] Test push notifications
- [ ] Verify analytics are working
- [ ] Check crash reporting is configured

### 14. **Play Console Setup**
- [ ] Create app in Google Play Console
- [ ] Upload AAB file
- [ ] Complete store listing
- [ ] Set up pricing and distribution
- [ ] Configure countries/regions
- [ ] Set up closed testing (if needed) before public release

### 15. **Common Rejection Reasons**
- ❌ Missing Privacy Policy
- ❌ Incomplete Data Safety declaration
- ❌ Incorrect permission usage
- ❌ App crashes on launch
- ❌ Missing required store listing information
- ❌ Using test/debug API keys in production
- ❌ App violates content policies
- ❌ Missing required permissions declarations

---

## 🔒 Security Recommendations

1. **API Keys**: Consider using environment variables or build configs instead of hardcoding
2. **Keystore**: Store backup securely (you'll need it for all future updates)
3. **Backend**: Ensure all API endpoints use HTTPS
4. **Firebase**: Enable App Check for additional security
5. **Obfuscation**: Consider enabling ProGuard/R8 if you add sensitive logic

---

## 📝 Notes

- **Version Code**: Must be incremented for each upload (currently: 3)
- **Version Name**: Can be any string (currently: 1.0.1)
- **Minimum SDK**: 23 (Android 6.0) - covers ~95% of devices
- **Target SDK**: 35 (Android 15) - required for new submissions

---

## 🚀 Quick Start

1. Verify signing configuration
2. Build release AAB: `flutter build appbundle --release`
3. Upload to Play Console
4. Complete store listing
5. Submit for review

Good luck with your submission! 🎉

