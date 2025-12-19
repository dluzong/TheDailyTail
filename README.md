# TheDailyTail 🐾

Fall '25 Capstone Project

## About

The Daily Tail is a cross-platform mobile application designed to help pet owners manage their pets’ daily care in one centralized place. The app simplifies tracking health records, meals, medications, and activities, while also fostering a sense of community among local pet owners, shelters, pet fosters and future pet owners. Ultimately, our team set out to create an all-in-one tool that we, as pet owners ourselves, would genuinely use.

## Features

- Sign Up and Log In with your own account with synchronous data
  - Supports Google quick sign up
  - Onboarding screens for new users
- Manage multiple pet profiles
  - Add and modify pet name, breed, birthday, weight, sex, etc.
  - Pet profiles are displayed on user profile for other users to view
- Daily logs
  - Save frequent pet meals, medications
  - Add events to calendar for appointments, events, vaccinations, other
- Dashboard
  - View individual pet information and their recent activity
- Community board
  - View posts and filter results (to friends, organizations, recents, topics)
  - Find new users to follow and/or view their profiles
  - Create/Find new organizations to join

## Demo
![app demo gif](https://github.com/dluzong/TheDailyTail/blob/main/demo.gif)

## Tech Stack / Tools Used

- **Frontend:** Flutter (Dart)
- **Backend & Auth:** Supabase
- **Version Control:** Git & GitHub

## Project Structure

frontend/\
├── android/        # Android-specific files\
├── ios/            # iOS-specific files\
├── lib/            # Application source code\
│   ├── screens/    # UI screens\
│   └── shared/     # Shared resources\
├── ios/            # iOS-specific files\
└── pubspec.yaml    # Flutter dependencies

## Getting Started

This project uses Flutter; make sure you have Flutter and Dart installed.

### Prerequisites

- Git
- Flutter and Dart SDK
- An editor such as VS Code or Android Studio
- For iOS development: Xcode (macOS only)
- For Android development: Android SDK (via Android Studio)

Run `flutter doctor` to verify your environment. Fix any issues the doctor reports before continuing.

### Clone the repository

Open a terminal and run:

```
git clone https://github.com/dluzong/TheDailyTail.git
cd frontend
```

### Environment file

Add a `.env` file in the `frontend/` folder **(.env file will be emailed upon request)**. Our app will not successfully run without it.

### Install dependencies

Install Dart/Flutter packages and CocoaPods (iOS) if needed:

```
flutter pub get
```

### Run the app

- Launch on an Android emulator, iOS simulator, or connected device

```
flutter run
```

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
- If you run into build or dependency errors, run `flutter clean` to clear out cache and rebuild the app.
