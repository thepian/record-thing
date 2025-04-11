#!/bin/bash

# Reset permissions for development and testing
# Usage: ./reset_permissions.sh [platform]

PLATFORM=${1:-"all"}

echo "Resetting permissions for platform: $PLATFORM"

case $PLATFORM in
    "ios-simulator")
        echo "Resetting iOS Simulator permissions..."
        xcrun simctl privacy booted reset camera
        ;;
    "ios-device")
        echo "Resetting iOS device permissions..."
        # Note: This requires the device to be connected and unlocked
        idevicepair pair
        idevicepair unpair
        ;;
    "macos")
        echo "Resetting macOS permissions..."
        tccutil reset Camera
        ;;
    "all")
        echo "Resetting all platform permissions..."
        # iOS Simulator
        xcrun simctl privacy booted reset camera
        # macOS
        tccutil reset Camera
        ;;
    *)
        echo "Invalid platform. Use: ios-simulator, ios-device, macos, or all"
        exit 1
        ;;
esac

echo "Permission reset complete!" 