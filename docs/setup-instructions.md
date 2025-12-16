# Setup Instructions

## Prerequisites

Before setting up the Mero Budget Tracker application, ensure you have the following installed on your development machine:

### Required Software

1. **Flutter SDK** (3.7.0 or higher)
   - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Verify installation: `flutter --version`

2. **Dart SDK** (comes with Flutter)
   - Verify installation: `dart --version`

3. **Git**
   - Download from [git-scm.com](https://git-scm.com/)
   - Verify installation: `git --version`

4. **IDE/Editor** (Choose one):
   - **VS Code** (Recommended)
     - Install Flutter and Dart extensions
   - **Android Studio**
     - Install Flutter and Dart plugins
   - **IntelliJ IDEA**
     - Install Flutter and Dart plugins

### Platform-Specific Requirements

#### For iOS Development (macOS only)
- Xcode (latest version)
- CocoaPods: `sudo gem install cocoapods`
- iOS Simulator or physical iOS device

#### for Android Development
- Android Studio
- Android SDK
- Android Emulator or physical Android device
- Accept Android licenses: `flutter doctor --android-licenses`

#### For Web Development
- Chrome browser (for debugging)
- No additional requirements

## Installation Steps

### 1. Clone the Repository

```bash
# Clone the repository
git clone https://github.com/dotnepal/mero-budget-tracker.git

# Navigate to project directory
cd mero_budget_tracker
```

### 2. Install Dependencies

```bash
# Get Flutter dependencies
flutter pub get

# Verify Flutter setup
flutter doctor
```

If `flutter doctor` shows any issues, follow the provided instructions to resolve them.

### 3. Configure Development Environment

#### VS Code Setup

1. Open the project in VS Code:
   ```bash
   code .
   ```

2. Install recommended extensions:
   - Flutter
   - Dart
   - Flutter Widget Snippets
   - Error Lens (optional, for better error visibility)

3. Configure VS Code settings (`.vscode/settings.json`):
   ```json
   {
     "editor.formatOnSave": true,
     "dart.lineLength": 80,
     "editor.rulers": [80],
     "files.trimTrailingWhitespace": true,
     "files.insertFinalNewline": true
   }
   ```

#### Android Studio Setup

1. Open Android Studio
2. Select "Open an existing project"
3. Navigate to the project directory
4. Wait for indexing to complete
5. Configure Flutter SDK path in Settings > Languages & Frameworks > Flutter

### 4. Running the Application

#### Run on Web (Recommended for initial testing)

```bash
# Run on Chrome
flutter run -d chrome

# Run with specific port
flutter run -d chrome --web-port=8080
```

#### Run on iOS Simulator

```bash
# List available simulators
flutter devices

# Open iOS Simulator
open -a Simulator

# Run on iOS
flutter run -d iphone
```

#### Run on Android Emulator

```bash
# List available emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator_id>

# Run on Android
flutter run -d android
```

#### Run on Physical Device

1. Enable Developer Mode on your device
2. Connect device via USB
3. Trust the computer on your device
4. Run:
   ```bash
   flutter run
   ```

### 5. Development Workflow

#### Hot Reload and Hot Restart

While the app is running:
- Press `r` for hot reload (maintains state)
- Press `R` for hot restart (resets state)
- Press `q` to quit

#### Running with Verbose Output

```bash
# For debugging issues
flutter run -v

# For release mode testing
flutter run --release
```

## Project Structure

```
mero_budget_tracker/
├── lib/
│   ├── main.dart                 # Application entry point
│   ├── app/                      # App-level configurations
│   │   ├── routes/               # Route definitions
│   │   └── theme/                # Theme configurations
│   ├── core/                     # Core functionality
│   │   ├── router/               # Navigation router
│   │   ├── theme/                # Theme definitions
│   │   ├── utils/                # Utility functions
│   │   └── widgets/              # Shared widgets
│   ├── features/                 # Feature modules
│   │   ├── home/                 # Home feature
│   │   ├── statistics/           # Statistics feature
│   │   └── transaction/          # Transaction management
│   └── shared/                   # Shared resources
├── test/                         # Test files
├── docs/                         # Documentation
├── android/                      # Android platform files
├── ios/                          # iOS platform files
├── web/                          # Web platform files
├── pubspec.yaml                  # Package dependencies
└── analysis_options.yaml         # Linter configuration
```

## Available Features

### Current Implemented Features

1. **Transaction Management**
   - Add income/expense transactions
   - Edit existing transactions
   - Delete transactions
   - View transaction history

2. **Summary Views**
   - Monthly income/expense summary
   - Transaction statistics
   - Visual charts (bar and pie charts)

3. **User Interface**
   - Material Design 3 theming
   - Responsive layouts
   - Loading states
   - Error handling

## Common Commands

### Development Commands

```bash
# Run the app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .

# Clean build artifacts
flutter clean

# Upgrade dependencies
flutter pub upgrade

# Get outdated packages
flutter pub outdated
```

### Build Commands

```bash
# Build for Web
flutter build web

# Build for iOS
flutter build ios

# Build for Android APK
flutter build apk

# Build for Android App Bundle
flutter build appbundle
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Flutter SDK Not Found

**Error**: `flutter: command not found`

**Solution**:
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Make permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

#### 2. Dependencies Issues

**Error**: `pub get failed`

**Solution**:
```bash
# Clear cache and reinstall
flutter clean
flutter pub cache clean
flutter pub get
```

#### 3. iOS Build Issues

**Error**: `Error running pod install`

**Solution**:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

#### 4. Android Build Issues

**Error**: `Gradle build failed`

**Solution**:
```bash
# Clean gradle cache
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

#### 5. Web Renderer Issues

**Error**: `Web rendering problems`

**Solution**:
```bash
# Try different renderers
flutter run -d chrome --web-renderer html
# or
flutter run -d chrome --web-renderer canvaskit
```

### Debug Tools

#### Flutter Inspector

1. Run the app in debug mode
2. Open Flutter Inspector in your IDE
3. Inspect widget tree and properties
4. Enable "Select Widget Mode" to inspect UI elements

#### DevTools

```bash
# Launch DevTools
flutter pub global activate devtools
flutter pub global run devtools

# The DevTools URL will be displayed
# Open in browser and connect to your running app
```

#### Logging

Add debug prints in code:
```dart
debugPrint('Debug message: $variable');
```

View logs:
```bash
flutter logs
```

## Environment Configuration

### Setting Up Environment Variables (Future Implementation)

Create `.env` file in the project root:
```env
API_BASE_URL=https://api.example.com
API_KEY=your_api_key_here
```

**Note**: Never commit `.env` file to version control

### Configuration for Different Environments

```bash
# Development
flutter run --dart-define=ENV=development

# Staging
flutter run --dart-define=ENV=staging

# Production
flutter run --dart-define=ENV=production
```

## Code Quality

### Running Code Analysis

```bash
# Run analyzer
flutter analyze

# Fix issues automatically (where possible)
dart fix --apply
```

### Pre-commit Checks

Before committing code, run:
```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests
flutter test
```

## Additional Resources

### Documentation
- [Project README](../README.md)
- [Architecture Documentation](architecture.md)
- [Coding Guidelines](coding-guidelines.md)
- [Database Comparison](database-comparison.md)

### External Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [BLoC Library Documentation](https://bloclibrary.dev/)
- [Material Design 3](https://m3.material.io/)

### Getting Help
- Check existing [documentation](../docs/)
- Review [GitHub Issues](https://github.com/dotnepal/mero-budget-tracker/issues)
- Flutter Community on [Discord](https://discord.gg/flutter)
- Stack Overflow with tag `flutter`

## Next Steps

After successful setup:

1. **Familiarize yourself with the codebase**
   - Review the architecture documentation
   - Understand the BLoC pattern implementation
   - Explore existing features

2. **Start developing**
   - Pick an issue from GitHub
   - Create a feature branch
   - Implement changes following coding guidelines
   - Submit a pull request

3. **Testing**
   - Write tests for new features
   - Ensure existing tests pass
   - Test on multiple platforms

## Conclusion

You should now have a fully functional development environment for the Mero Budget Tracker application. If you encounter any issues not covered in this guide, please check the troubleshooting section or reach out to the development team.

Happy coding! 🚀