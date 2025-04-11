# Quality Assurance Guide

## Permission Testing

### Resetting Camera Permissions

During development and testing, you may need to reset camera permissions to test different permission scenarios. Here are the available methods:

#### Using the Reset Script

We provide a convenience script to reset permissions:

```bash
# Reset permissions for all platforms
./scripts/reset_permissions.sh all

# Reset permissions for specific platform
./scripts/reset_permissions.sh ios-simulator
./scripts/reset_permissions.sh ios-device
./scripts/reset_permissions.sh macos
```

#### Manual Reset Methods

##### iOS Simulator
1. Reset specific permissions:
   ```bash
   xcrun simctl privacy booted reset camera
   ```
2. Reset all permissions:
   ```bash
   xcrun simctl privacy booted reset all
   ```
3. Reset entire simulator:
   ```bash
   xcrun simctl erase all
   ```

##### iOS Device
1. Settings > General > Reset > Reset Location & Privacy
2. Settings > Privacy & Security > Camera > Reset Camera Access
3. Settings > [Your App] > Reset Permissions

##### macOS
1. System Settings > Privacy & Security > Camera > Reset Camera Access
2. Terminal command:
   ```bash
   tccutil reset Camera
   ```
3. Reset all permissions:
   ```bash
   tccutil reset All
   ```

### Testing Scenarios

When testing camera permissions, ensure you test the following scenarios:

1. **First-time Permission Request**
   - App should properly request camera access
   - Clear explanation of why camera access is needed
   - Proper handling of user denial

2. **Permission Changes**
   - App should detect and handle permission changes
   - Proper UI feedback when permissions are revoked
   - Graceful degradation of features when permissions are denied

3. **Permission Restoration**
   - App should properly restore functionality when permissions are re-granted
   - No data loss or corruption during permission changes
   - Proper state restoration after permission changes

### Debugging Tips

1. **Logging**
   - Check the console for permission-related logs
   - Look for `AVCaptureDevice.authorizationStatus` changes
   - Monitor `CaptureService` permission state changes

2. **Common Issues**
   - Permission state not updating after changes
   - Camera preview not resuming after permission grant
   - App crashing on permission denial
   - Permission UI not showing on first launch

3. **Testing Checklist**
   - [ ] Test on both iOS and macOS
   - [ ] Test on both simulator and physical devices
   - [ ] Test permission changes during active camera use
   - [ ] Test app behavior after system permission changes
   - [ ] Test app behavior after app reinstall 