# TheDailyTail 🐾

Fall '25 Capstone Project

## About

The Daily Tail is a cross-platform Flutter application to help pet owners manage their pets' day-to-day care. Users can track health metrics, log daily activities, view medical history, and connect with the local pet community.

## Features

- Manage multiple pet profiles (name, breed, age, weight, sex)
- Daily logs for meals, medications, vaccinations
- Dashboard with quick pet overview and recent activity
- Community board

## Getting Started

This project uses Flutter; make sure you have Flutter and Dart installed.

### Prerequisites

- Git
- Flutter (3.x or newer) and Dart SDK
- An editor such as VS Code or Android Studio
- For iOS development: Xcode (macOS only)
- For Android development: Android SDK (via Android Studio)

Run `flutter doctor` to verify your environment. Fix any issues the doctor reports before continuing.

### Clone the repository

Open a terminal and run:

```bash
git clone https://github.com/dluzong/TheDailyTail.git
cd frontend
```

### Environment file

Add a `.env` file in the `frontend/` folder **(.env file will be emailed upon request)**. Our app will not successfully run without it.

### Install dependencies

Install Dart/Flutter packages and CocoaPods (iOS) if needed:

```bash
flutter pub get
```

### Run the app

- Launch on an Android emulator, iOS simulator, or connected device:

<!-- 
```bash
flutter devices    # list available devices
flutter run -d <device-id>
``` -->

<!-- - To run on a specific platform:

```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# macOS desktop (if enabled)
flutter run -d macos
``` -->

## Troubleshooting

- If CocoaPods warns about platform or base configurations: open `ios/Podfile` and ensure `platform :ios, '13.0'` is set, then run `pod install` in `ios/`.
- If you see merge conflicts in `ios/Podfile.lock`, resolve the conflict, then run `pod install` and commit the resolved file.



