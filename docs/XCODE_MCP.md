# XcodeBuildMCP Integration Guide

## Overview

**XcodeBuildMCP** is an open-source Model Context Protocol (MCP) server that provides Xcode-related tools for integration with AI assistants. Created by Cameron Cooke, it allows you to build, test, and manage iOS/macOS projects directly from AI-powered editors like Cursor, VS Code, and Windsurf.

<https://playbooks.com/mcp/cameroncooke-xcodebuild>

**Repository:** [cameroncooke/XcodeBuildMCP](https://github.com/cameroncooke/XcodeBuildMCP)

## What XcodeBuildMCP Enables

### Project Management

- **Build iOS/macOS projects** from Cursor, VS Code, or Windsurf
- **Discover projects and workspaces** automatically
- **List schemes and build settings**
- **Clean projects** and manage build artifacts
- **Extract bundle IDs** and app information

### Simulator Management

- **List available simulators**
- **Boot simulators** programmatically
- **Install and launch apps** on simulators
- **Capture real-time logs** during app execution
- **Stream build logs** with proper formatting

### UI Automation (Experimental)

- **Take screenshots** of simulators
- **Tap, swipe, and type** in simulator apps
- **Automate UI interactions** for testing

### AI-Assisted Development

- **Autonomous build error fixing**
- **Real-time log analysis**
- **Automated testing workflows**
- **Code validation and iteration**

## Prerequisites

### Required Software

- **macOS 14.5 or later**
- **Xcode 16.x or later**
- **Node.js 18.x or later**
- **mise** (polyglot dev tool manager)

### Installation Commands

```bash
# Install mise (tool version manager)
brew install mise

# Optional: Install AXe for UI automation
brew tap cameroncooke/axe
brew install axe
```

## Configuration

### Cursor Setup

Create or edit `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "XcodeBuildMCP": {
      "command": "mise",
      "args": [
        "x",
        "npm:xcodebuildmcp@1.7.0",
        "--",
        "xcodebuildmcp"
      ]
    }
  }
}
```

### VS Code Setup (with Copilot Agent Mode)

Edit `~/Library/Application Support/Code/User/settings.json`:

```json
{
  "mcp": {
    "servers": {
      "XcodeBuildMCP": {
        "command": "mise",
        "args": [
          "x",
          "npm:xcodebuildmcp@1.7.0",
          "--",
          "xcodebuildmcp"
        ]
      }
    }
  }
}
```

### Windsurf Setup

Edit `~/.codeium/windsurf/mcp_config.json`:

```json
{
  "mcpServers": {
    "XcodeBuildMCP": {
      "command": "mise",
      "args": [
        "x",
        "npm:xcodebuildmcp@1.7.0",
        "--",
        "xcodebuildmcp"
      ]
    }
  }
}
```

## Basic Usage Commands

### Project Discovery and Management

```
"Discover Xcode projects in this directory"
"List schemes for RecordThing.xcworkspace"
"Show build settings for the main scheme"
"Clean the RecordThing project"
```

### Building Projects

```
"Build RecordThing for iPhone 15 Pro simulator"
"Build RecordThing for macOS using Debug configuration"
"Build RecordThing for iOS device"
```

### Simulator Control

```
"List available iOS simulators"
"Boot iPhone 15 Pro simulator"
"Install RecordThing app on simulator"
"Launch RecordThing and capture logs"
"Take a screenshot of the simulator"
```

### Advanced Operations

```
"Extract bundle ID from the built app"
"Start log capture for RecordThing app"
"Stop logging and show captured logs"
"Launch RecordThing with full logging enabled"
```

## Advanced Configuration

### Enable Incremental Builds (Experimental)

For faster builds, enable incremental build support:

```json
{
  "mcpServers": {
    "XcodeBuildMCP": {
      "command": "mise",
      "args": [
        "x",
        "npm:xcodebuildmcp@1.7.0",
        "--",
        "xcodebuildmcp"
      ],
      "env": {
        "INCREMENTAL_BUILDS_ENABLED": "true"
      }
    }
  }
}
```

### Selective Tool Registration

To reduce context and only enable specific tools:

```json
{
  "mcpServers": {
    "XcodeBuildMCP": {
      "command": "mise",
      "args": [
        "x",
        "npm:xcodebuildmcp@1.7.0",
        "--",
        "xcodebuildmcp"
      ],
      "env": {
        "XCODEBUILDMCP_GROUP_IOS_SIMULATOR_WORKFLOW": "true"
      }
    }
  }
}
```

### Disable Sentry Error Reporting

If you prefer not to send error logs to Sentry:

```json
{
  "env": {
    "SENTRY_DISABLED": "true"
  }
}
```

## Real-World Workflow Example

### Typical Development Session

1. **Project Discovery**

   ```
   "Find all Xcode projects in this workspace"
   ```

2. **Build the App**

   ```
   "Build RecordThing for iPhone simulator"
   ```

3. **Handle Build Errors**
   - AI automatically reads build errors
   - Suggests and applies fixes
   - Rebuilds automatically

4. **Test on Simulator**

   ```
   "Install and launch the app on iPhone 15 Pro simulator"
   ```

5. **Debug Issues**

   ```
   "Start logging and show any crashes"
   "Take a screenshot of the current state"
   ```

6. **Iterate**
   - AI reads logs, identifies issues
   - Suggests code changes
   - Rebuilds and retests

## RecordThing-Specific Workflows

### Share Extension Testing

```
"Build RecordThing with ShareExtension for iPhone simulator"
"Install both targets on simulator"
"Test sharing from Safari to RecordThing"
"Capture logs during share extension activation"
```

### Cross-Platform Development

```
"Build RecordThing for both iOS and macOS"
"Compare build settings between platforms"
"Test RecordLib across both targets"
```

### CI/CD Integration

```
"Build all schemes in Release configuration"
"Run unit tests for all targets"
"Generate build reports and capture any failures"
```

## Troubleshooting

### Common Issues

1. **mise not found**

   ```bash
   # Ensure mise is in your PATH
   echo $PATH
   which mise
   ```

2. **XcodeBuildMCP not starting**

   ```bash
   # Test manually
   mise x npm:xcodebuildmcp@1.7.0 -- xcodebuildmcp
   ```

3. **Build failures**

   ```
   "Show detailed build logs for the last build"
   "Clean all build artifacts and retry"
   ```

### Diagnostic Tool

XcodeBuildMCP includes a diagnostic tool:

```bash
# Using npx
npx xcodebuildmcp@1.7.0 xcodebuildmcp-diagnostic

# Using mise
mise x npm:xcodebuildmcp@1.7.0 -- xcodebuildmcp-diagnostic
```

### Log Files

Check MCP server logs in your editor:

**Cursor:**

```bash
find ~/Library/Application\ Support/Cursor/logs -name "Cursor MCP.log"
```

## Best Practices

### 1. Clear Commands

- Be specific about schemes and targets
- Specify simulator models explicitly
- Use full project/workspace paths when needed

### 2. Error Handling

- Let AI read and interpret build errors
- Use incremental builds for faster iteration
- Capture logs for debugging sessions

### 3. Workflow Integration

- Combine with GitHub MCP for full CI/CD
- Use selective tool registration for focused workflows
- Enable logging for troubleshooting

### 4. Performance Optimization

- Enable incremental builds for large projects
- Use specific simulator targets
- Clean build artifacts regularly

## Integration with Other Tools

### GitHub MCP Combination

```
"Build RecordThing, and if successful, commit changes and create PR"
"Run tests, capture results, and update GitHub issue with status"
```

### Tailscale Integration

```
"Build and deploy RecordThing to test server via Tailscale"
"Test share extension with remote services"
```

## Version Management

Always specify explicit versions in your MCP configuration to ensure consistency:

```json
{
  "args": [
    "x",
    "npm:xcodebuildmcp@1.7.0",  // Pin to specific version
    "--",
    "xcodebuildmcp"
  ]
}
```

Check for updates regularly at: <https://github.com/cameroncooke/XcodeBuildMCP/releases>

## Security Considerations

- XcodeBuildMCP runs locally and doesn't expose code to external networks
- Build processes use standard Xcode security sandbox
- Simulator interactions are contained within the iOS Simulator environment
- Consider disabling Sentry reporting for sensitive projects

## Resources

- **GitHub Repository:** <https://github.com/cameroncooke/XcodeBuildMCP>
- **Tool Options Documentation:** [TOOL_OPTIONS.md](https://github.com/cameroncooke/XcodeBuildMCP/blob/main/TOOL_OPTIONS.md)
- **MCP Protocol:** <https://modelcontextprotocol.io/>
- **mise Documentation:** <https://mise.jdx.dev/>

## Next Steps

1. **Install Prerequisites:** Install mise and optionally AXe
2. **Configure Your Editor:** Add XcodeBuildMCP to your MCP configuration
3. **Test Basic Commands:** Try project discovery and building
4. **Explore Advanced Features:** Enable incremental builds and UI automation
5. **Integrate with Workflows:** Combine with other MCP servers for complete automation

---

**Applied Workspace Rules:**

- **Cross-platform:** Supporting both iOS and macOS development
- **Logging:** Debug logs available through MCP integration
- **Documentation:** Comprehensive setup and usage instructions provided
