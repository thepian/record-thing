# ThepiaApp iPhone E2E Tests

This directory contains End-to-End (E2E) tests for the ThepiaApp iPhone app navigation flows. These tests ensure that the core user journeys work correctly on iPhone devices.

## 🎯 Test Coverage

### Core Navigation Flows
- **Camera → Actions → Camera**: Tests the primary Actions button navigation
- **Actions → Settings → Actions**: Tests Settings access from Actions view
- **Camera → Assets → Camera**: Tests Stack button navigation to Assets view
- **Navigation Error Recovery**: Tests app resilience to rapid navigation

### Content Validation
- **Actions View Content**: Verifies all expected CTAs and sections are present
- **Settings View Content**: Verifies all settings sections and options are displayed
- **UI State Consistency**: Ensures proper navigation breadcrumbs and buttons

### Performance & Reliability
- **Navigation Performance**: Measures navigation timing
- **Stress Testing**: Rapid navigation sequences to test stability
- **Error Recovery**: Graceful handling of navigation edge cases

## 🏗️ Test Architecture

### Test Files

1. **`iPhoneNavigationE2ETests.swift`** - XCTest-based E2E tests (framework structure)
2. **`RealSimulatorE2ETests.swift`** - Real simulator integration tests
3. **`run_e2e_tests.py`** - Python test runner with simulator control
4. **`README.md`** - This documentation file

### Test Structure

```
E2E Tests
├── Setup & Teardown
│   ├── Ensure app is running
│   ├── Navigate to default state
│   └── Cleanup after tests
├── Navigation Tests
│   ├── Camera ↔ Actions
│   ├── Actions ↔ Settings  
│   └── Camera ↔ Assets
├── Content Validation
│   ├── Actions view content
│   └── Settings view content
└── Performance & Reliability
    ├── Navigation timing
    ├── Stress testing
    └── Error recovery
```

## 🚀 Running Tests

### Prerequisites

1. **iOS Simulator** with iPhone 16 (or compatible device)
2. **ThepiaApp app** built and installed on simulator
3. **Python 3.7+** for test runner
4. **Xcode Command Line Tools**

### Local Testing

#### Option 1: Python Test Runner (Recommended)

```bash
# Navigate to E2E test directory
cd apps/ThepiaApp/Tests/E2E

# Make test runner executable
chmod +x run_e2e_tests.py

# Run all tests
python3 run_e2e_tests.py

# Run with specific simulator
python3 run_e2e_tests.py --simulator-uuid "YOUR_SIMULATOR_UUID"

# Generate detailed report
python3 run_e2e_tests.py --report
```

#### Option 2: XCTest (Framework)

```bash
# Run XCTest-based tests
cd apps/ThepiaApp
xcodebuild test \
  -project ThepiaApp.xcodeproj \
  -scheme "ThepiaApp iOS" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -testPlan E2ETests
```

### CI/CD Testing

Tests run automatically on:
- **Push** to `main`, `develop`, or `feature/*` branches
- **Pull Requests** to `main` or `develop`
- **Manual trigger** via GitHub Actions

#### Manual GitHub Actions Run

1. Go to **Actions** tab in GitHub
2. Select **"E2E Tests - iPhone Navigation"** workflow
3. Click **"Run workflow"**
4. Choose simulator device (optional)
5. Click **"Run workflow"**

## 📋 Test Scenarios

### 1. Camera to Actions Navigation
```
Given: App is in camera view
When: User taps Actions button
Then: Actions view is displayed with expected content
When: User taps Record button
Then: App returns to camera view
```

### 2. Actions to Settings Navigation
```
Given: User is in Actions view
When: User taps Settings option
Then: Settings view is displayed
When: User taps back button
Then: App returns to Actions view
```

### 3. Assets Navigation Flow
```
Given: App is in camera view
When: User taps Stack button
Then: Assets view is displayed
When: User taps Record button
Then: App returns to camera view
```

### 4. Content Validation
```
Given: User navigates to Actions view
Then: All expected CTAs are present:
  - Settings with description
  - Update Account with priority indicator
  - Record Evidence with urgent indicator
  - Account Profile option
  - Record button in toolbar
```

### 5. Error Recovery
```
Given: User performs rapid navigation sequence
When: Multiple quick taps on navigation elements
Then: App maintains stable state
And: User can return to camera view
```

## 🔧 Configuration

### Simulator Settings

- **Device**: iPhone 16 (default)
- **iOS Version**: 18.2+
- **Orientation**: Portrait
- **Bundle ID**: `com.thepia.app`

### Test Parameters

```python
# Default configuration
SIMULATOR_UUID = "4364D6A3-B29D-45FC-B46B-740D0BB556E5"
BUNDLE_ID = "com.thepia.app"
TEST_TIMEOUT = 30.0
```

### Customization

You can customize test behavior by modifying:

1. **Simulator UUID** - Use different simulator device
2. **Test Timeout** - Adjust for slower/faster devices
3. **Element Coordinates** - Update for different screen sizes
4. **Test Scenarios** - Add new navigation flows

## 🐛 Troubleshooting

### Common Issues

#### App Not Running
```
Error: App is not running in simulator
Solution: Ensure ThepiaApp is built and launched in simulator
```

#### Element Not Found
```
Error: UI element not found: "Actions"
Solution: Check if app is in expected state, verify element labels
```

#### Navigation Timeout
```
Error: Navigation action timed out
Solution: Increase timeout or check for UI blocking elements
```

#### Simulator Issues
```
Error: Simulator tools unavailable
Solution: Restart simulator, check Xcode installation
```

### Debug Mode

Enable verbose logging:

```bash
# Run with debug output
python3 run_e2e_tests.py --verbose

# Check simulator state
xcrun simctl list devices
xcrun simctl list apps SIMULATOR_UUID
```

### Manual Verification

If tests fail, manually verify:

1. **App Launch**: Can you launch ThepiaApp in simulator?
2. **Navigation**: Can you manually navigate Actions → Settings → Actions?
3. **UI Elements**: Are all buttons and labels visible?
4. **Performance**: Is navigation responsive?

## 📊 Test Reports

### Report Format

```
E2E Test Report for ThepiaApp iPhone App
==========================================

Total Tests: 6
Passed: 6
Failed: 0
Success Rate: 100.0%

Test Details:
  ✅ PASSED: Camera to Actions Navigation
  ✅ PASSED: Actions to Settings Navigation
  ✅ PASSED: Assets Navigation Flow
  ✅ PASSED: Actions View Content
  ✅ PASSED: Settings View Content
  ✅ PASSED: Navigation Error Recovery
```

### CI/CD Integration

- **GitHub Actions**: Automatic test execution and reporting
- **Artifacts**: Screenshots and logs uploaded on failure
- **Status Checks**: PR blocking on test failures
- **Notifications**: Slack/email alerts for test results

## 🔄 Maintenance

### Updating Tests

When UI changes are made:

1. **Update Element Coordinates** - If button positions change
2. **Update Content Validation** - If new sections are added
3. **Update Navigation Flows** - If new screens are introduced
4. **Update Test Scenarios** - If user journeys change

### Adding New Tests

To add new test scenarios:

1. **Define Test Case** - What user journey to test
2. **Implement Test Method** - Add to test runner
3. **Update Documentation** - Add to this README
4. **Verify CI/CD** - Ensure new tests run in GitHub Actions

## 📚 References

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [iOS Simulator Guide](https://developer.apple.com/documentation/xcode/running-your-app-in-the-simulator)
- [GitHub Actions for iOS](https://docs.github.com/en/actions/guides/building-and-testing-swift)
- [ThepiaApp App Documentation](../../README.md)
