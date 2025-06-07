# ShareExtension Tests

This directory contains comprehensive tests for the RecordThing ShareExtension, covering unit tests, integration tests, and performance tests.

## Test Structure

### Unit Tests

#### `ShareExtensionTests.swift`
- Tests for `SharedContent` model initialization and properties
- Tests for `ContentType` enum and its display properties  
- Tests for `SharedContentViewModel` state management
- Validates display title and subtitle generation

#### `YouTubeServiceTests.swift`
- Tests YouTube URL recognition across different formats
- Tests video ID extraction from various YouTube URL patterns
- Tests thumbnail URL generation for different quality levels
- Tests edge cases and validation scenarios

#### `ShareExtensionViewTests.swift`
- Tests SwiftUI view initialization and rendering
- Tests `SharedContentPreview` with different content types
- Tests loading and placeholder states
- Tests custom UI components like `RoundedCorner`

### Integration Tests

#### `ShareExtensionIntegrationTests.swift`
- End-to-end workflow tests for YouTube video sharing
- Web page sharing workflow validation
- Text content sharing scenarios
- Error handling and recovery workflows
- Multi-format URL processing tests

### Performance Tests

#### `ShareExtensionPerformanceTests.swift`
- URL processing performance benchmarks
- SharedContent creation and manipulation speed tests
- ViewModel update performance validation
- Memory usage tests with large datasets
- Concurrent access performance tests

### Test Utilities

#### `TestConfiguration.swift`
- Sample test data and factory methods
- Mock object creation utilities
- Validation helper functions
- Performance testing utilities

## Running Tests

### In Xcode

1. Open `RecordThing.xcodeproj` in Xcode
2. Select the `ShareExtension` scheme
3. Press `⌘U` to run all tests
4. Or use `⌘⌥U` to run tests with code coverage

### From Command Line

```bash
# Run all ShareExtension tests
cd apps/RecordThing
xcodebuild test \
  -project RecordThing.xcodeproj \
  -scheme ShareExtension \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0'

# Run with code coverage
xcodebuild test \
  -project RecordThing.xcodeproj \
  -scheme ShareExtension \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
  -enableCodeCoverage YES
```

### GitHub Actions

Tests are automatically run on:
- Push to `main`, `develop`, or `feature/*` branches
- Pull requests to `main` or `develop`
- Changes to ShareExtension code

See `.github/workflows/ios-tests.yml` for the complete CI configuration.

## Test Coverage Goals

- **Unit Tests**: 90%+ coverage for core logic
- **Integration Tests**: Cover all major user workflows
- **Performance Tests**: Validate acceptable performance thresholds
- **UI Tests**: Ensure proper SwiftUI component behavior

## Test Data

### YouTube URLs Tested
- Standard watch URLs: `https://www.youtube.com/watch?v=VIDEO_ID`
- Short URLs: `https://youtu.be/VIDEO_ID`
- Embed URLs: `https://www.youtube.com/embed/VIDEO_ID`
- Mobile URLs: `https://m.youtube.com/watch?v=VIDEO_ID`
- URLs with parameters: `?t=30s`, `&list=PLAYLIST_ID`

### Content Types Tested
- YouTube videos with various metadata
- Web pages from different domains
- Plain text content with and without URLs
- Unknown/unsupported content types

## Performance Benchmarks

### Expected Performance Thresholds

| Operation | Threshold | Test |
|-----------|-----------|------|
| YouTube URL Recognition | < 1s for 8000 ops | `testYouTubeURLRecognitionPerformance` |
| Video ID Extraction | < 1s for 8000 ops | `testVideoIDExtractionPerformance` |
| Thumbnail URL Generation | < 1s for 25000 ops | `testThumbnailURLGenerationPerformance` |
| SharedContent Creation | < 0.1s for 1000 ops | `testSharedContentCreationPerformance` |
| ViewModel Updates | < 0.01s for 100 ops | `testViewModelUpdatePerformance` |

## Adding New Tests

### For New Features

1. Add unit tests in the appropriate test file
2. Add integration tests if the feature involves multiple components
3. Add performance tests if the feature could impact performance
4. Update test data in `TestConfiguration.swift` if needed

### Test Naming Convention

- Use descriptive test names: `testYouTubeURLRecognitionWithParameters`
- Group related tests with common prefixes
- Use `@Test` attribute for Swift Testing framework

### Mock Data

Use `TestConfiguration` factory methods for consistent test data:

```swift
// Good
let content = TestConfiguration.createYouTubeContent(videoId: "test123")

// Avoid creating test data inline
let content = SharedContent(url: URL(string: "...")!, ...)
```

## Debugging Tests

### Common Issues

1. **Simulator not available**: Ensure iOS Simulator is installed and available
2. **Network timeouts**: Performance tests may fail on slow machines
3. **Threading issues**: ViewModel tests must run on MainActor

### Debug Tips

- Use `print()` statements for debugging test failures
- Check Xcode console for detailed error messages
- Use breakpoints in test methods for step-by-step debugging
- Verify test data matches expected formats

## Continuous Integration

The test suite is integrated with GitHub Actions and runs:

- **On every push**: Full test suite with coverage reporting
- **On pull requests**: Fast test subset for quick feedback
- **Nightly**: Extended performance and stress tests

### Coverage Reporting

- Code coverage reports are uploaded to Codecov
- Coverage badges are available in the main README
- Minimum coverage threshold is enforced in CI

## Contributing

When contributing to ShareExtension:

1. Write tests for new functionality
2. Ensure all existing tests pass
3. Maintain or improve code coverage
4. Update test documentation as needed
5. Follow the established test patterns and naming conventions

## Test File Organization

```
ShareExtension/Tests/
├── TESTING_README.md           # This file
├── TestConfiguration.swift     # Test utilities and mock data
├── ShareExtensionTests.swift   # Core model and ViewModel tests
├── YouTubeServiceTests.swift   # YouTube service functionality tests
├── ShareExtensionViewTests.swift # SwiftUI component tests
├── ShareExtensionIntegrationTests.swift # End-to-end workflow tests
└── ShareExtensionPerformanceTests.swift # Performance benchmarks
```

## Integration with Xcode Project

To integrate these tests into the Xcode project:

1. **Add test target** to RecordThing.xcodeproj
2. **Configure test bundle** with proper dependencies
3. **Set up test schemes** for different test types
4. **Configure CI/CD** to run tests automatically

See the main project documentation for detailed integration steps.
