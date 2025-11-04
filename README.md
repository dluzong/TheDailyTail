# TheDailyTail 🐾

Fall '25 Capstone Project

## About

The Daily Tail is a cross-platform Flutter application to help pet owners manage their pets' day-to-day care. Users can track health metrics, log daily activities, view medical history, and connect with the local pet community.

## Features

- Manage multiple pet profiles (name, breed, age, weight, sex)
- Daily logs for meals, walks, medications, and other activities
- Dashboard with quick pet overview and recent activity
- Community board (feed, groups, friends)
- Onboarding and setup flows

## Getting Started

This guide covers macOS, Windows and Linux. The project uses Flutter; make sure you have Flutter and Dart installed.

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
cd TheDailyTail/frontend
```

### Environment file

Create a `.env` file in the `frontend/` folder if your app depends on environment variables. The repository does not include secrets—add keys as required by your team.

Example `.env` (do NOT commit this file):

```env
# Example:
API_BASE_URL=https://api.example.com
SENTRY_DSN=
```

### Install dependencies

Install Dart/Flutter packages and (iOS) CocoaPods if needed:

```bash
flutter pub get
# On macOS (iOS projects):
cd ios && pod install --repo-update && cd ..
```

### Run the app

- Launch on an Android emulator, iOS simulator, or connected device:

```bash
flutter devices    # list available devices
flutter run -d <device-id>
```

- To run on a specific platform:

```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# macOS desktop (if enabled)
flutter run -d macos
```

## Troubleshooting

- If CocoaPods warns about platform or base configurations: open `ios/Podfile` and ensure `platform :ios, '13.0'` is set, then run `pod install` in `ios/`.
- If you see merge conflicts in `ios/Podfile.lock`, resolve the conflict, then run `pod install` and commit the resolved file.

## Project structure

```
frontend/
├── lib/
│   ├── screens/          # UI screens (dashboard, community, onboarding)
│   ├── shared/           # shared widgets and layout (AppLayout)
│   ├── models/           # data models
│   └── main.dart         # app entrypoint
├── assets/               # images, lottie animations
├── ios/                  # iOS Xcode project files
├── android/              # Android Gradle project files
├── pubspec.yaml          # Flutter dependencies and assets
└── test/                 # unit & widget tests
```

## Development notes

- The app uses Google Fonts; install packages and run `flutter pub get` after any dependency changes.
- To disable iOS swipe-back or intercept back navigation in widgets, use the scoped route callbacks (e.g. `ModalRoute.of(context)?.addScopedWillPopCallback`).

## Testing

Run unit & widget tests with:

```bash
flutter test
```

## Linting & Static Analysis

Run the analyzer to surface static errors:

```bash
flutter analyze
```

## Contributing

We welcome contributions. Please:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit changes with clear messages
4. Open a Pull Request targeting the `main` branch

Add tests for new behavior where applicable.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Contact

- Maintainer: dluzong
- Repository: https://github.com/dluzong/TheDailyTail

---

If you want, I can also:

- Add a short development checklist to the README
- Generate a CONTRIBUTING.md with PR guidelines and commit message conventions
- Add platform-specific notes for Windows (Windows SDK) or Linux (snap/packaging) — tell me which you prefer.



