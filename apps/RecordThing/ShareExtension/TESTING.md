# ShareExtension Testing Guide

## Overview

This minimal implementation logs all shared content to help understand what data is being received from different apps, with special focus on YouTube video sharing.

## How to Test

### 1. Build and Install

1. Build the RecordThing app with the ShareExtension target
2. Install on device or simulator
3. Make sure the extension appears in the share sheet

### 2. Test YouTube Sharing

1. Open the YouTube app
2. Find any video
3. Tap the Share button
4. Look for "Save to RecordThing" in the share sheet
5. Tap it
6. Add an optional comment
7. Tap "Post"

### 3. Test Web Page Sharing

1. Open Safari
2. Navigate to any web page
3. Tap the Share button
4. Select "Save to RecordThing"
5. Add optional comment and tap "Post"

### 4. Test Text Sharing

1. In any app with text (Notes, Messages, etc.)
2. Select text that contains a URL
3. Tap Share
4. Select "Save to RecordThing"

## Viewing Logs

### Using Xcode Console

1. Open Xcode
2. Go to Window → Devices and Simulators
3. Select your device
4. Click "Open Console"
5. Filter by "recordthing" or "ShareViewController"

### Using Console.app

1. Open Console.app on Mac
2. Connect your device
3. Filter by subsystem: `com.thepia.recordthing.shareextension`

## Expected Log Output

### YouTube Video Share
```
📱 Received URL: https://www.youtube.com/watch?v=dQw4w9WgXcQ
🎥 YOUTUBE VIDEO DETECTED!
   Host: www.youtube.com
   Path: /watch
   Query: v=dQw4w9WgXcQ
   Video ID: dQw4w9WgXcQ
```

### Regular Web Page
```
📱 Received URL: https://www.apple.com
🌐 Regular web URL detected
   Host: www.apple.com
```

### Text with URL
```
📝 Received text: Check out this video https://youtu.be/dQw4w9WgXcQ
   Found URL in text: https://youtu.be/dQw4w9WgXcQ
🎥 YOUTUBE VIDEO DETECTED!
   Video ID: dQw4w9WgXcQ
```

## Troubleshooting

### Extension Not Appearing
- Check that the app is properly installed
- Verify Info.plist configuration
- Make sure you're sharing supported content types

### No Logs Appearing
- Check Console.app filters
- Verify the subsystem name matches
- Try sharing different content types

### Extension Crashes
- Check for missing imports
- Verify target dependencies
- Look for runtime errors in Console

## Next Steps

Once logging confirms the extension is receiving YouTube URLs correctly:

1. Implement database saving
2. Add proper UI feedback
3. Handle different YouTube URL formats
4. Add error handling
5. Implement strategist selection

## Log Categories

The implementation logs different types of information:

- **📱 URL Detection**: When URLs are received
- **🎥 YouTube Detection**: When YouTube videos are identified  
- **🌐 Web Content**: Regular web pages
- **📝 Text Content**: Text with embedded URLs
- **🎯 Processing**: Content processing steps
- **✅ Completion**: When operations finish
- **❌ Errors**: When something goes wrong

This minimal implementation provides a solid foundation for understanding what content is being shared and ensures YouTube video detection is working correctly.
