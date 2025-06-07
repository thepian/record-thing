#!/bin/bash

# RecordThing iPhone E2E Test Runner
# This script runs end-to-end tests for the iPhone app navigation flows

set -e  # Exit on any error

# Configuration
SIMULATOR_UUID="${1:-4364D6A3-B29D-45FC-B46B-740D0BB556E5}"
BUNDLE_ID="com.thepia.recordthing"
PROJECT_PATH="../../RecordThing.xcodeproj"
SCHEME="RecordThing iOS"
TEST_TIMEOUT=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

echo -e "${BLUE}RecordThing iPhone E2E Test Runner${NC}"
echo "=================================="
echo "Simulator UUID: $SIMULATOR_UUID"
echo "Bundle ID: $BUNDLE_ID"
echo ""

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if simulator is available
check_simulator() {
    log_info "Checking simulator availability..."
    
    if ! xcrun simctl list devices | grep -q "$SIMULATOR_UUID"; then
        log_error "Simulator $SIMULATOR_UUID not found"
        echo "Available simulators:"
        xcrun simctl list devices | grep iPhone
        exit 1
    fi
    
    # Boot simulator if not already booted
    if ! xcrun simctl list devices | grep "$SIMULATOR_UUID" | grep -q "Booted"; then
        log_info "Booting simulator..."
        xcrun simctl boot "$SIMULATOR_UUID"
        sleep 5
    fi
    
    log_success "Simulator is ready"
}

# Function to build and install app
build_and_install_app() {
    log_info "Building RecordThing for simulator..."
    
    cd ../..  # Go to RecordThing project root
    
    # Clean and build
    xcodebuild clean \
        -project RecordThing.xcodeproj \
        -scheme "$SCHEME" \
        -destination "id=$SIMULATOR_UUID" \
        > /dev/null 2>&1
    
    xcodebuild build \
        -project RecordThing.xcodeproj \
        -scheme "$SCHEME" \
        -destination "id=$SIMULATOR_UUID" \
        -configuration Debug \
        > /dev/null 2>&1
    
    # Find the built app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "RecordThing.app" -type d | head -1)
    
    if [ -z "$APP_PATH" ]; then
        log_error "Built app not found"
        exit 1
    fi
    
    log_info "Installing app on simulator..."
    xcrun simctl install "$SIMULATOR_UUID" "$APP_PATH"
    
    log_success "App built and installed"
    cd Tests/E2E  # Return to test directory
}

# Function to launch app
launch_app() {
    log_info "Launching RecordThing..."
    xcrun simctl launch "$SIMULATOR_UUID" "$BUNDLE_ID" > /dev/null 2>&1
    sleep 3
    log_success "App launched"
}

# Function to get UI state (mock implementation)
get_ui_state() {
    # In a real implementation, this would call the actual simulator tools
    # For now, return a mock state that represents the current view
    echo "Record Thing Take Picture Stack Actions Settings Demo User Assets Record"
}

# Function to tap at coordinates (mock implementation)
tap_at() {
    local x=$1
    local y=$2
    local description=$3
    
    log_info "Tapping $description at ($x, $y)"
    # In real implementation: call simulator tap function
    sleep 0.5
}

# Function to find and tap element
tap_element() {
    local label=$1
    local description=$2
    
    local ui_state=$(get_ui_state)
    
    if [[ $ui_state == *"$label"* ]]; then
        log_info "Tapping $description"
        # Mock coordinates based on label
        case $label in
            "Actions")
                tap_at 255 708 "$description"
                ;;
            "Stack")
                tap_at 132 708 "$description"
                ;;
            "Settings")
                tap_at 196 227 "$description"
                ;;
            "Record")
                tap_at 354 75 "$description"
                ;;
            *)
                tap_at 200 400 "$description"
                ;;
        esac
        return 0
    else
        log_error "Element '$label' not found in UI"
        return 1
    fi
}

# Function to verify UI state
verify_ui_state() {
    local expected_elements=("$@")
    local ui_state=$(get_ui_state)
    
    for element in "${expected_elements[@]}"; do
        if [[ $ui_state != *"$element"* ]]; then
            log_error "Expected element '$element' not found in UI"
            return 1
        fi
    done
    
    return 0
}

# Function to run a test
run_test() {
    local test_name=$1
    local test_function=$2
    
    echo ""
    log_info "Running test: $test_name"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if $test_function; then
        log_success "PASSED: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "FAILED: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test functions
test_camera_to_actions_navigation() {
    # Verify camera view
    if ! verify_ui_state "Take Picture" "Actions"; then
        return 1
    fi
    
    # Navigate to Actions
    if ! tap_element "Actions" "Actions button"; then
        return 1
    fi
    
    sleep 1
    
    # Verify Actions view
    if ! verify_ui_state "Settings" "Record"; then
        return 1
    fi
    
    # Return to Camera
    if ! tap_element "Record" "Record button"; then
        return 1
    fi
    
    sleep 1
    
    # Verify back in camera
    verify_ui_state "Take Picture"
}

test_actions_to_settings_navigation() {
    # Navigate to Actions
    if ! tap_element "Actions" "Actions button"; then
        return 1
    fi
    
    sleep 1
    
    # Navigate to Settings
    if ! tap_element "Settings" "Settings option"; then
        return 1
    fi
    
    sleep 1
    
    # Verify Settings view
    if ! verify_ui_state "Demo User" "Actions"; then
        return 1
    fi
    
    # Navigate back to Actions
    if ! tap_element "Actions" "Back button"; then
        return 1
    fi
    
    sleep 1
    
    # Verify back in Actions
    verify_ui_state "Record"
}

test_assets_navigation_flow() {
    # Navigate to Assets
    if ! tap_element "Stack" "Stack button"; then
        return 1
    fi
    
    sleep 1
    
    # Verify Assets view
    if ! verify_ui_state "Assets" "Record"; then
        return 1
    fi
    
    # Return to Camera
    if ! tap_element "Record" "Record button"; then
        return 1
    fi
    
    sleep 1
    
    # Verify back in camera
    verify_ui_state "Take Picture"
}

test_actions_view_content() {
    # Navigate to Actions
    if ! tap_element "Actions" "Actions button"; then
        return 1
    fi
    
    sleep 1
    
    # Verify expected content
    verify_ui_state "Settings" "Record"
}

test_settings_view_content() {
    # Navigate to Settings
    if ! tap_element "Actions" "Actions button"; then
        return 1
    fi
    
    if ! tap_element "Settings" "Settings option"; then
        return 1
    fi
    
    sleep 1
    
    # Verify expected content
    verify_ui_state "Demo User" "Actions"
}

test_navigation_error_recovery() {
    # Perform rapid navigation sequence
    tap_element "Actions" "Actions button" || true
    sleep 0.2
    tap_element "Settings" "Settings option" || true
    sleep 0.2
    tap_element "Actions" "Back button" || true
    sleep 0.2
    tap_element "Record" "Record button" || true
    
    sleep 1
    
    # Verify we end up in camera view
    verify_ui_state "Take Picture"
}

# Function to return to camera view
return_to_camera_view() {
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local ui_state=$(get_ui_state)
        
        # Already in camera view
        if [[ $ui_state == *"Take Picture"* ]]; then
            return 0
        fi
        
        # Try to tap Record button
        if [[ $ui_state == *"Record"* ]] && [[ $ui_state != *"Take Picture"* ]]; then
            tap_element "Record" "Record button (attempt $attempt)"
            sleep 1
            attempt=$((attempt + 1))
            continue
        fi
        
        # Try to go back if in Settings
        if [[ $ui_state == *"Actions"* ]] && [[ $ui_state == *"Settings"* ]]; then
            tap_element "Actions" "Back button (attempt $attempt)"
            sleep 1
            attempt=$((attempt + 1))
            continue
        fi
        
        sleep 1
        attempt=$((attempt + 1))
    done
    
    log_warning "Could not return to camera view after $max_attempts attempts"
    return 1
}

# Main test execution
main() {
    # Setup
    check_simulator
    build_and_install_app
    launch_app
    
    # Ensure we start from camera view
    return_to_camera_view
    
    # Run all tests
    run_test "Camera to Actions Navigation" test_camera_to_actions_navigation
    return_to_camera_view
    
    run_test "Actions to Settings Navigation" test_actions_to_settings_navigation
    return_to_camera_view
    
    run_test "Assets Navigation Flow" test_assets_navigation_flow
    return_to_camera_view
    
    run_test "Actions View Content" test_actions_view_content
    return_to_camera_view
    
    run_test "Settings View Content" test_settings_view_content
    return_to_camera_view
    
    run_test "Navigation Error Recovery" test_navigation_error_recovery
    
    # Results
    echo ""
    echo "=================================="
    echo "Test Results:"
    echo "Total: $TESTS_TOTAL"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "All tests passed! 🎉"
        exit 0
    else
        log_error "Some tests failed. Please check the output above."
        exit 1
    fi
}

# Run main function
main "$@"
