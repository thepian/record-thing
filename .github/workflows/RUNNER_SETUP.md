# GitHub Actions macOS Runner Setup Guide

## 🎯 Overview

The E2E tests for RecordThing require macOS runners with Xcode and iOS Simulator capabilities. This guide explains your options and how to set them up.

## ⚠️ Current Status

**The E2E workflow is currently DISABLED** for automatic triggers (push/PR) because macOS runners need to be configured first. It can only be triggered manually via `workflow_dispatch`.

## 🔧 Runner Options

### Option 1: GitHub-hosted macOS Runners (Recommended for Testing)

**Pros:**
- ✅ Zero setup required
- ✅ Xcode pre-installed (multiple versions available)
- ✅ iOS Simulators ready to use
- ✅ Maintained by GitHub
- ✅ Clean environment for each run

**Cons:**
- 💰 **Costs GitHub Actions minutes** (macOS minutes are 10x more expensive than Linux)
- ⏱️ Limited to GitHub's available Xcode versions
- 🔒 No access to custom simulator configurations
- 📊 Usage limits based on your GitHub plan

**Cost Estimate:**
- Free plan: 0 macOS minutes included
- Pro plan: 0 macOS minutes included (pay per use)
- Team plan: 0 macOS minutes included (pay per use)
- Enterprise: Varies by plan

**Pricing:** ~$0.08 per minute for macOS runners

### Option 2: Self-hosted macOS Runners (Recommended for Production)

**Pros:**
- ✅ No GitHub Actions minute costs
- ✅ Full control over Xcode versions
- ✅ Custom simulator configurations
- ✅ Faster builds (no cold start)
- ✅ Access to internal resources

**Cons:**
- 🖥️ Requires dedicated macOS machine
- ⚙️ Setup and maintenance overhead
- 🔐 Security considerations
- 💾 Storage and compute costs

## 🚀 Setup Instructions

### Option 1: Enable GitHub-hosted Runners

**Step 1: Update the workflow**

Uncomment the automatic triggers in `.github/workflows/e2e-tests.yml`:

```yaml
on:
  push:
    branches: [ main, develop, feature/* ]
    paths:
      - 'apps/RecordThing/**'
      - '.github/workflows/e2e-tests.yml'
  pull_request:
    branches: [ main, develop ]
    paths:
      - 'apps/RecordThing/**'
      - '.github/workflows/e2e-tests.yml'
  workflow_dispatch:
    # ... existing inputs
```

**Step 2: Set runner type**

Update the `runs-on` configuration:

```yaml
runs-on: macos-latest  # or macos-13, macos-14, macos-15
```

**Step 3: Test the workflow**

1. Go to **Actions** tab in GitHub
2. Select **"E2E Tests - iPhone Navigation"**
3. Click **"Run workflow"**
4. Choose **"github-hosted"** as runner type
5. Monitor usage and costs

### Option 2: Setup Self-hosted macOS Runner

**Step 1: Prepare macOS Machine**

Requirements:
- macOS 12.0+ (macOS 13+ recommended)
- Xcode 14.0+ installed
- iOS Simulator configured
- Minimum 8GB RAM, 50GB free storage
- Stable internet connection

**Step 2: Install GitHub Actions Runner**

```bash
# Create a folder for the runner
mkdir actions-runner && cd actions-runner

# Download the latest runner package
curl -o actions-runner-osx-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz

# Extract the installer
tar xzf ./actions-runner-osx-x64-2.311.0.tar.gz
```

**Step 3: Configure the Runner**

1. Go to your GitHub repository
2. Navigate to **Settings** → **Actions** → **Runners**
3. Click **"New self-hosted runner"**
4. Select **macOS** and follow the configuration commands:

```bash
# Configure the runner (use the token from GitHub)
./config.sh --url https://github.com/YOUR_ORG/record-thing --token YOUR_TOKEN

# Add labels for identification
./config.sh --url https://github.com/YOUR_ORG/record-thing --token YOUR_TOKEN --labels macos,xcode,ios-simulator
```

**Step 4: Install Dependencies**

```bash
# Install Xcode Command Line Tools (if not already installed)
xcode-select --install

# Install Python 3 (for test runner)
brew install python3

# Verify Xcode installation
xcodebuild -version
xcrun simctl list devices
```

**Step 5: Start the Runner**

```bash
# Start the runner (for testing)
./run.sh

# Or install as a service (recommended for production)
sudo ./svc.sh install
sudo ./svc.sh start
```

**Step 6: Update Workflow**

Update `.github/workflows/e2e-tests.yml`:

```yaml
runs-on: self-hosted
# or
runs-on: [self-hosted, macos, xcode]
```

## 🔧 Configuration Options

### Workflow Configuration

**For GitHub-hosted runners:**
```yaml
runs-on: macos-latest
env:
  DEVELOPER_DIR: /Applications/Xcode.app/Contents/Developer
```

**For self-hosted runners:**
```yaml
runs-on: [self-hosted, macos]
env:
  DEVELOPER_DIR: /Applications/Xcode.app/Contents/Developer
```

### Simulator Configuration

**Available simulators:**
```bash
# List available simulators
xcrun simctl list devices

# Create specific simulator for testing
xcrun simctl create "E2E-iPhone-16" "iPhone 16" "iOS-18-2"
```

### Security Considerations

**For self-hosted runners:**
- 🔐 Use dedicated machine (not development machine)
- 🚫 Don't run on machines with sensitive data
- 🔄 Regular security updates
- 📝 Monitor runner logs
- 🔒 Restrict repository access

## 📊 Cost Analysis

### GitHub-hosted Runner Costs

**Estimated monthly costs for different usage patterns:**

| Usage Pattern | Minutes/Month | Cost/Month |
|---------------|---------------|------------|
| Light (10 runs) | ~100 minutes | ~$8 |
| Medium (50 runs) | ~500 minutes | ~$40 |
| Heavy (200 runs) | ~2000 minutes | ~$160 |

**Per-run breakdown:**
- Build time: ~3-5 minutes
- Test execution: ~2-3 minutes
- Setup/teardown: ~2-3 minutes
- **Total per run: ~7-11 minutes**

### Self-hosted Runner Costs

**One-time setup:**
- Mac mini M2: ~$599
- Setup time: ~4-8 hours

**Ongoing costs:**
- Electricity: ~$5-10/month
- Maintenance: ~2-4 hours/month
- **Break-even point: ~2-3 months** (vs GitHub-hosted)

## 🎯 Recommendations

### For Small Teams/Projects
**Use GitHub-hosted runners:**
- Lower upfront cost
- No maintenance overhead
- Good for occasional testing

### For Active Development
**Use self-hosted runners:**
- Better long-term economics
- Faster feedback loops
- Full control over environment

### Hybrid Approach
**Use both:**
- Self-hosted for regular CI/CD
- GitHub-hosted for backup/overflow
- Different runners for different branches

## 🚀 Getting Started

### Immediate Next Steps

1. **Choose your approach** based on budget and requirements
2. **Test with manual workflow** first
3. **Monitor costs and performance**
4. **Enable automatic triggers** when ready

### Quick Test

```bash
# Manual test of current setup
cd apps/RecordThing/Tests/E2E
python3 run_e2e_tests.py --report
```

### Enable Automatic Testing

When ready, update `.github/workflows/e2e-tests.yml`:

```yaml
# Uncomment these lines:
on:
  push:
    branches: [ main, develop, feature/* ]
  pull_request:
    branches: [ main, develop ]
```

## 📞 Support

**Common Issues:**
- **Xcode not found**: Set `DEVELOPER_DIR` environment variable
- **Simulator not available**: Check `xcrun simctl list devices`
- **Permission denied**: Ensure runner has proper permissions
- **Build failures**: Verify Xcode version compatibility

**Resources:**
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Self-hosted Runners Guide](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Xcode on GitHub Actions](https://github.com/actions/runner-images/blob/main/images/macos/macos-13-Readme.md)

---

**Current Status:** E2E tests are ready but require macOS runner configuration to run automatically. Choose your approach and follow the setup guide above! 🚀
