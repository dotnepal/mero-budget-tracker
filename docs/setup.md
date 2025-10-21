# Setup Guide

This document provides instructions for setting up the Mero Budget Tracker development environment.

## Prerequisites

1. Flutter SDK (^3.7.0)
2. Dart SDK
3. VS Code or Android Studio/IntelliJ IDEA
4. Git

## Development Environment Setup

1. **Install Flutter**
   ```bash
   # Follow the official Flutter installation guide for your OS:
   # https://docs.flutter.dev/get-started/install
   
   # Verify installation
   flutter doctor
   ```

2. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd mero_budget_tracker
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the Application**
   ```bash
   flutter run
   ```

## IDE Setup

### VS Code
1. Install the Flutter and Dart extensions
2. Open the command palette (Cmd/Ctrl + Shift + P)
3. Run "Flutter: New Project"
4. Select a debugging device

### Android Studio/IntelliJ
1. Install the Flutter and Dart plugins
2. Open the project
3. Configure a device or emulator
4. Click the Run button or press Ctrl+R

## Development Tools

- **Hot Reload**: Save changes to trigger hot reload (⌘\ or Ctrl+\)
- **Hot Restart**: Full app restart (⌘Shift\ or Ctrl+Shift+\)
- **Flutter DevTools**: Access via VS Code command palette or Android Studio

## Running Tests

```bash
flutter test
```

## Building for Release

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Troubleshooting

If you encounter issues:

1. Run `flutter doctor` to diagnose common problems
2. Ensure all dependencies are up to date with `flutter pub upgrade`
3. Clean the build with `flutter clean` and rebuild
4. Check the [Flutter GitHub issues](https://github.com/flutter/flutter/issues) for known problems