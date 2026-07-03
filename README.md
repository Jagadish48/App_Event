# NetworkEvents Flutter App

This repository contains the complete, production-ready Flutter wrapper for `https://app.networkevents.net/`.

## Prerequisites
1. **Flutter SDK**: Ensure you have Flutter installed (version 3.0.0 or higher). [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Android Studio**: For Android deployment and building the APK/AAB.
3. **Xcode**: For iOS deployment and building the IPA (requires a Mac).
4. **Firebase Account**: Required for Push Notifications.

## Initial Setup Instructions

Since this code was generated in a pre-existing folder, follow these steps to build the full Flutter project architecture on your machine:

1. Open a terminal where Flutter is installed.
2. Run the following command to generate the rest of the Flutter project structure (this creates the standard iOS/Android/Web folders that aren't included here):
   ```bash
   flutter create --org net.networkevents --project-name network_events .
   ```
   *(Note: Run this inside the `FlutterApp` folder, and it will safely integrate the custom `lib`, `pubspec.yaml`, and modified native files.)*
3. Fetch the dependencies:
   ```bash
   flutter pub get
   ```

## Configuring Assets & Icons

### App Icon
1. Replace the default placeholder image with your app logo. Save it as `assets/images/app_icon.png`.
2. Uncomment the `image_path` under `flutter_icons` in your `pubspec.yaml`.
3. Run the icon generator:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

### Splash Screen
1. Save your splash screen logo as `assets/images/splash_logo.png`.
2. Uncomment the `image` under `flutter_native_splash` in your `pubspec.yaml`.
3. Run the splash screen generator:
   ```bash
   flutter pub run flutter_native_splash:create
   ```

## Firebase Push Notifications (Optional but Recommended)
To enable push notifications, you need to link this app to Firebase:
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create a new project and add an Android and iOS app with the bundle ID: `net.networkevents.app`.
3. Download `google-services.json` and place it in `android/app/`.
4. Download `GoogleService-Info.plist` and place it in `ios/Runner/`.

## Build and Deployment

### Android
To build a signed APK for testing:
```bash
flutter build apk --release
```
To build an Android App Bundle (AAB) for the Google Play Store:
```bash
flutter build appbundle --release
```

### iOS
To build an IPA for the Apple App Store (requires a Mac):
```bash
flutter build ipa --release
```
Then, open the generated `.xcarchive` in Xcode to distribute it to App Store Connect.

## Core Features Implemented
- **InAppWebView**: Secure, high-performance webview rendering your website.
- **Pull-to-Refresh**: Native swipe-down to refresh functionality.
- **Offline Handling**: Beautiful fallback screen when no internet is detected.
- **Hardware Permissions**: Dynamic requests for Camera, Microphone, and Location.
- **Deep Linking**: Opens `app.networkevents.net` links directly inside the app.
- **File Downloads/Uploads**: Fully supported and configured.
- **Persistent Sessions**: Cookies and DOM storage enabled.
