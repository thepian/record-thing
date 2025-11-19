#!/bin/bash

# Environment Check Script for RecordThing E2E Tests
# This script verifies that the environment is ready for running E2E tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}RecordThing E2E Environment Check${NC}"
echo "=================================="
echo ""

# Track overall status
OVERALL_STATUS=0

# Helper functions
check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
    OVERALL_STATUS=1
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

check_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check 1: macOS Version
echo "1. Checking macOS version..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOS_VERSION=$(sw_vers -productVersion)
    check_pass "Running on macOS $MACOS_VERSION"
else
    check_fail "Not running on macOS (detected: $OSTYPE)"
fi
echo ""

# Check 2: Xcode Installation
echo "2. Checking Xcode installation..."
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -1)
    check_pass "Xcode found: $XCODE_VERSION"
    
    # Check Xcode path
    DEVELOPER_DIR=$(xcode-select -p)
    check_info "Developer directory: $DEVELOPER_DIR"
else
    check_fail "Xcode not found or not properly installed"
fi
echo ""

# Check 3: iOS Simulator
echo "3. Checking iOS Simulator availability..."
if command -v xcrun &> /dev/null; then
    # Check if simulators are available
    SIMULATOR_COUNT=$(xcrun simctl list devices available | grep -c "iPhone" || true)
    if [ "$SIMULATOR_COUNT" -gt 0 ]; then
        check_pass "Found $SIMULATOR_COUNT iPhone simulators"
        
        # List available iPhone simulators
        echo "   Available iPhone simulators:"
        xcrun simctl list devices available | grep "iPhone" | head -5 | while read line; do
            echo "   - $line"
        done
    else
        check_fail "No iPhone simulators found"
    fi
else
    check_fail "xcrun command not available"
fi
echo ""

# Check 4: Python Installation
echo "4. Checking Python installation..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    check_pass "Python found: $PYTHON_VERSION"
else
    check_fail "Python 3 not found"
fi
echo ""

# Check 5: RecordThing Project
echo "5. Checking RecordThing project..."
PROJECT_PATH="../../RecordThing.xcodeproj"
if [ -d "$PROJECT_PATH" ]; then
    check_pass "RecordThing project found at $PROJECT_PATH"
else
    check_fail "RecordThing project not found at $PROJECT_PATH"
fi
echo ""

# Check 6: Test Files
echo "6. Checking E2E test files..."
TEST_FILES=(
    "run_e2e_tests.py"
    "test_runner.sh"
    "iPhoneNavigationE2ETests.swift"
    "RealSimulatorE2ETests.swift"
)

for file in "${TEST_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_pass "Test file found: $file"
    else
        check_fail "Test file missing: $file"
    fi
done
echo ""

# Check 7: Simulator Specific Check
echo "7. Checking specific simulator for testing..."
TARGET_SIMULATOR="4364D6A3-B29D-45FC-B46B-740D0BB556E5"
if xcrun simctl list devices | grep -q "$TARGET_SIMULATOR"; then
    SIMULATOR_STATUS=$(xcrun simctl list devices | grep "$TARGET_SIMULATOR" | awk '{print $NF}' | tr -d '()')
    if [ "$SIMULATOR_STATUS" = "Booted" ]; then
        check_pass "Target simulator is booted and ready"
    else
        check_warn "Target simulator exists but is not booted (status: $SIMULATOR_STATUS)"
        echo "   You can boot it with: xcrun simctl boot $TARGET_SIMULATOR"
    fi
else
    check_warn "Target simulator $TARGET_SIMULATOR not found"
    echo "   Available simulators:"
    xcrun simctl list devices | grep "iPhone" | head -3 | while read line; do
        echo "   - $line"
    done
fi
echo ""

# Check 8: GitHub Actions Environment (if applicable)
echo "8. Checking GitHub Actions environment..."
if [ -n "$GITHUB_ACTIONS" ]; then
    check_info "Running in GitHub Actions environment"
    
    if [ -n "$RUNNER_OS" ]; then
        check_info "Runner OS: $RUNNER_OS"
    fi
    
    if [ -n "$RUNNER_ARCH" ]; then
        check_info "Runner Architecture: $RUNNER_ARCH"
    fi
    
    # Check if this is a self-hosted runner
    if [ -n "$RUNNER_NAME" ]; then
        check_info "Runner Name: $RUNNER_NAME"
    fi
else
    check_info "Running in local development environment"
fi
echo ""

# Check 9: Disk Space
echo "9. Checking available disk space..."
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
check_info "Available disk space: $AVAILABLE_SPACE"

# Convert to GB for comparison (rough estimate)
SPACE_GB=$(df -g . | awk 'NR==2 {print $4}')
if [ "$SPACE_GB" -gt 10 ]; then
    check_pass "Sufficient disk space available"
else
    check_warn "Low disk space (${SPACE_GB}GB available, recommend 10GB+)"
fi
echo ""

# Check 10: Network Connectivity
echo "10. Checking network connectivity..."
if ping -c 1 github.com &> /dev/null; then
    check_pass "Network connectivity to GitHub is working"
else
    check_warn "Cannot reach GitHub (may affect CI/CD operations)"
fi
echo ""

# Summary
echo "=================================="
echo "Environment Check Summary"
echo "=================================="

if [ $OVERALL_STATUS -eq 0 ]; then
    check_pass "Environment is ready for E2E testing!"
    echo ""
    echo "Next steps:"
    echo "1. Build RecordThing: cd ../.. && xcodebuild -project RecordThing.xcodeproj -scheme 'RecordThing iOS' -destination 'platform=iOS Simulator,name=iPhone 16'"
    echo "2. Run E2E tests: python3 run_e2e_tests.py --report"
    echo "3. Or use shell script: ./test_runner.sh"
else
    check_fail "Environment has issues that need to be resolved"
    echo ""
    echo "Please fix the issues marked with ❌ above before running E2E tests."
fi

echo ""
echo "For more information, see:"
echo "- README.md - Complete testing guide"
echo "- TESTING_GUIDE.md - Manual test scenarios"
echo "- ../.github/workflows/RUNNER_SETUP.md - CI/CD setup guide"

exit $OVERALL_STATUS
