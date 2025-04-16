# RecordLib

A Swift library for managing evidence and assets in RecordThing.

## Running Tests

### Prerequisites

- Xcode 15.0 or later
- Swift 5.9 or later
- macOS 14.0 or later

### Running Tests in Xcode

1. Open the RecordThing workspace in Xcode
2. Select the `RecordLibTests` target in the scheme selector
3. Press `⌘U` or select `Product > Test` from the menu
4. Alternatively, click the diamond icon next to a test function to run that specific test

### Running Tests from Command Line

```bash
# Run all tests
xcodebuild test -scheme RecordLib -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test file
xcodebuild test -scheme RecordLib -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:RecordLibTests/Assets/AssetsViewModelTests

# Run specific test function
xcodebuild test -scheme RecordLib -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:RecordLibTests/Assets/AssetsViewModelTests/testLoadDatesWithNoData
```

### Test Structure

Tests are organized in the following structure:

```
Tests/
└── RecordLibTests/
    └── Assets/
        └── AssetsViewModelTests.swift
```

### Test Categories

- **Assets Tests**: Tests for asset management and date grouping functionality
  - `AssetsViewModelTests.swift`: Tests for the AssetsViewModel class

### Debugging Tests

1. Set breakpoints in the test file
2. Run tests in debug mode using `⌘Y`
3. Use the debug console to inspect variables and step through code

### Common Issues

1. **Database Connection Issues**
   - Ensure the test database is properly initialized
   - Check that the database path is accessible
   - Verify database schema matches test expectations

2. **Test Timing Issues**
   - Use XCTestExpectation for async operations
   - Set appropriate timeouts for async tests
   - Ensure proper cleanup in tearDown

3. **Build Issues**
   - Clean build folder (⇧⌘K)
   - Reset package caches (File > Packages > Reset Package Caches)
   - Check for missing dependencies

### Adding New Tests

1. Create a new test file in the appropriate directory
2. Follow the naming convention: `[Component]Tests.swift`
3. Use XCTest framework for test implementation
4. Include proper setup and teardown methods
5. Add test cases following the Given-When-Then pattern
6. Document test cases with clear descriptions

### Test Coverage

To generate test coverage reports:

```bash
xcodebuild test -scheme RecordLib -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -enableCodeCoverage YES
```

View coverage reports in Xcode:
1. Open the Report Navigator (⌘9)
2. Select the latest test run
3. Click on the Coverage tab 