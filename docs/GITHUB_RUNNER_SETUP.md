# GitHub Actions Self-Hosted Runner Setup

This guide will help you set up a self-hosted GitHub Actions runner for iOS/macOS development on your Mac.

## Why Use a Self-Hosted Runner?

- **Faster builds**: No queue time, dedicated resources
- **Custom environment**: Pre-installed tools and dependencies
- **Cost effective**: No GitHub Actions minutes usage for private repos
- **Better debugging**: Direct access to build artifacts and logs
- **Consistent environment**: Same machine for all builds

## Prerequisites

### Hardware Requirements
- **Mac with Apple Silicon (M1/M2/M3) or Intel processor**
- **Minimum 8GB RAM** (16GB+ recommended for iOS development)
- **50GB+ free disk space** (for Xcode, simulators, and build artifacts)
- **Stable internet connection**

### Software Requirements
- **macOS 12.0 or later**
- **Xcode 15.0 or later** (installed from App Store)
- **Command Line Tools** (installed automatically by setup script)
- **Admin privileges** on the Mac

## Quick Setup

### 1. Clone the Repository

```bash
git clone https://github.com/thepian/record-thing.git
cd record-thing
```

### 2. Run the Setup Script

```bash
chmod +x scripts/setup-github-runner.sh
./scripts/setup-github-runner.sh
```

The script will:
- ✅ Check prerequisites (Xcode, Homebrew)
- ✅ Install required tools (SwiftLint, jq)
- ✅ Download and configure GitHub Actions runner
- ✅ Set up auto-start service
- ✅ Create management scripts

### 3. Provide GitHub Token

When prompted, provide a **GitHub Personal Access Token** with `repo` scope:

1. Go to [GitHub Settings > Tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Select `repo` scope
4. Copy the token and paste it when prompted

## Manual Setup (Alternative)

If you prefer to set up manually or the script fails:

### 1. Install Prerequisites

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install swiftlint jq
```

### 2. Download Runner

```bash
# Create runner directory
mkdir -p ~/actions-runner
cd ~/actions-runner

# Download runner (adjust version as needed)
RUNNER_VERSION="2.311.0"
RUNNER_ARCH="osx-arm64"  # Use "osx-x64" for Intel Macs

curl -o actions-runner.tar.gz -L \
  "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"

# Extract runner
tar xzf actions-runner.tar.gz
```

### 3. Configure Runner

```bash
# Get registration token from GitHub API
GITHUB_TOKEN="your_token_here"
REGISTRATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/thepian/record-thing/actions/runners/registration-token" | jq -r .token)

# Configure runner
./config.sh \
  --url "https://github.com/thepian/record-thing" \
  --token "$REGISTRATION_TOKEN" \
  --name "$(hostname)-runner" \
  --work "_work" \
  --labels "macos,xcode,ios,swift" \
  --unattended
```

## Managing the Runner

Use the management script for easy runner control:

```bash
# Make management script executable
chmod +x scripts/manage-runner.sh

# Check runner status
./scripts/manage-runner.sh status

# Start runner
./scripts/manage-runner.sh start

# Stop runner
./scripts/manage-runner.sh stop

# Restart runner
./scripts/manage-runner.sh restart

# View logs
./scripts/manage-runner.sh logs

# Follow logs in real-time
./scripts/manage-runner.sh follow
```

## Verifying Setup

### 1. Check Runner Status

```bash
./scripts/manage-runner.sh status
```

Expected output:
```
✅ Runner service is running
✅ Runner process is active
```

### 2. Check GitHub Repository

1. Go to your repository on GitHub
2. Navigate to **Settings > Actions > Runners**
3. You should see your runner listed as "Online"

### 3. Test with a Workflow

Push a commit to trigger the workflows:
- `ios-tests.yml` - Uses GitHub-hosted runners
- `self-hosted-tests.yml` - Uses your self-hosted runner

## Troubleshooting

### Runner Not Appearing in GitHub

1. **Check registration token**: Ensure your GitHub token has `repo` scope
2. **Verify network**: Runner needs internet access to GitHub
3. **Check logs**: `./scripts/manage-runner.sh logs`

### Build Failures

1. **Xcode version**: Ensure Xcode 15.0+ is installed
2. **Simulators**: Check available simulators with `xcrun simctl list devices`
3. **Disk space**: Ensure sufficient free space (50GB+)
4. **Permissions**: Runner needs access to Xcode and simulators

### Performance Issues

1. **Memory**: Close unnecessary applications during builds
2. **CPU**: Avoid running intensive tasks during builds
3. **Disk**: Use SSD for better performance
4. **Network**: Stable internet for downloading dependencies

## Security Considerations

### Runner Security

- **Dedicated machine**: Use a dedicated Mac for the runner if possible
- **Network isolation**: Consider network restrictions for the runner
- **Regular updates**: Keep macOS and Xcode updated
- **Token rotation**: Regularly rotate GitHub tokens

### Repository Security

- **Branch protection**: Enable branch protection rules
- **Required reviews**: Require code reviews for sensitive changes
- **Secrets management**: Use GitHub Secrets for sensitive data
- **Audit logs**: Monitor runner activity in GitHub

## Maintenance

### Regular Tasks

1. **Update runner**: `./scripts/manage-runner.sh update`
2. **Update Xcode**: Install updates from App Store
3. **Clean builds**: Regularly clean DerivedData and caches
4. **Monitor logs**: Check for errors or warnings
5. **Disk cleanup**: Remove old build artifacts

### Automated Maintenance

The runner includes automatic:
- **Restart on reboot**: Service starts automatically
- **Log rotation**: Prevents log files from growing too large
- **Crash recovery**: Service restarts if it crashes

## Advanced Configuration

### Custom Labels

Add custom labels when configuring the runner:

```bash
./config.sh --labels "macos,xcode,ios,swift,custom-label"
```

### Environment Variables

Set environment variables in the launchd plist:

```xml
<key>EnvironmentVariables</key>
<dict>
    <key>CUSTOM_VAR</key>
    <string>value</string>
</dict>
```

### Multiple Runners

Run multiple runners on the same machine:

```bash
# Create additional runner directories
mkdir -p ~/actions-runner-2
mkdir -p ~/actions-runner-3

# Configure each with unique names
./config.sh --name "$(hostname)-runner-2"
```

## Support

If you encounter issues:

1. **Check logs**: `./scripts/manage-runner.sh logs`
2. **Review documentation**: GitHub Actions runner documentation
3. **GitHub Issues**: Create an issue in the repository
4. **Community**: Ask in GitHub Discussions

## Useful Commands

```bash
# Check Xcode version
xcodebuild -version

# List available simulators
xcrun simctl list devices

# Check runner process
ps aux | grep Runner

# Monitor system resources
top -pid $(pgrep Runner.Listener)

# Clean Xcode caches
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```
