# Developer Guide

This document provides guidelines and best practices for developers working on the Mero Budget Tracker project.

## Code Style

### Dart Style Guide

Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) and ensure your code passes the lint rules defined in `analysis_options.yaml`.

```dart
// Good
void doSomething() {
  // Function body
}

// Bad
void DoSomething() {
  // Function body
}
```

### File Naming

- Use `snake_case` for file names
- Use `PascalCase` for class names
- Use `camelCase` for variables and functions

Example:
```
budget_list_screen.dart
class BudgetListScreen
var budgetItems
```

## Git Workflow

1. **Branch Naming**
   ```
   feature/feature-name
   bugfix/bug-description
   hotfix/issue-description
   ```

2. **Commit Messages**
   ```
   feat: Add budget calculation feature
   fix: Resolve total calculation error
   docs: Update README with new setup instructions
   style: Format code according to dart standards
   refactor: Restructure budget model
   test: Add unit tests for calculations
   ```

3. **Pull Request Process**
   - Create a descriptive PR title
   - Add detailed description
   - Link related issues
   - Request reviews from team members

## Testing Guidelines

### Unit Tests
```dart
void main() {
  test('Budget calculation should be correct', () {
    final budget = Budget();
    expect(budget.calculate(), equals(0));
  });
}
```

### Widget Tests
```dart
void main() {
  testWidgets('Budget widget shows correct total', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.text('Total: \$0'), findsOneWidget);
  });
}
```

## Documentation

### Code Documentation
```dart
/// Calculates the total budget for a given period
///
/// Parameters:
/// - [startDate] The start date of the period
/// - [endDate] The end date of the period
///
/// Returns the total budget amount as a double
double calculateBudget(DateTime startDate, DateTime endDate) {
  // Implementation
}
```

### API Documentation
- Document all public APIs
- Include examples
- Specify parameter types and return values
- Note any exceptions or errors

## Performance Guidelines

1. **Widget Optimization**
   - Use const constructors where possible
   - Implement proper widget keys
   - Avoid unnecessary rebuilds

2. **State Management**
   - Keep state at appropriate levels
   - Avoid unnecessary state updates
   - Use efficient state management solutions

3. **Asset Management**
   - Optimize images and assets
   - Use appropriate image formats
   - Implement proper caching

## Debugging Tips

1. Use Flutter DevTools
2. Enable performance overlay when needed
3. Use logging strategically
4. Implement proper error handling

## Release Process

1. **Version Update**
   - Update version in pubspec.yaml
   - Update changelog
   - Tag release in git

2. **Pre-release Checklist**
   - Run all tests
   - Check performance metrics
   - Verify documentation
   - Review changelog

3. **Release Steps**
   ```bash
   # Update version
   flutter pub get
   
   # Run tests
   flutter test
   
   # Build release
   flutter build apk --release
   flutter build ios --release
   ```

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design Guidelines](https://material.io/design)
- [Flutter Testing](https://docs.flutter.dev/testing)