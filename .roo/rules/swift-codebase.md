---
description: 
globs: 
alwaysApply: true
---

# Rules for Swift code

- When using UIKit or AppKit specific funtionality, create a cross-platform function or class that implements using AppKit or UIKit based on the OS.
- General purpose iOS and macOS functionality(Services, Views, Models and ViewModels) is stored in libs/RecordLib.
- The concrete functionality with App Specific configurations should not be placed in libs/RecordLib.
- Always add debug logs(os logger) & comments in the code for easier debug & readability.
- Every time you choose to apply a rule(s), explicitly state the rule(s) in the output. You can abbreviate the rule description to a single word or phrase.
- For components that react to events or external @State variables, a toolbar should be added to the preview that allows triggering changes and events.