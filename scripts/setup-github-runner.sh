#!/bin/bash

# GitHub Actions Self-Hosted Runner Setup Script for macOS
# This script sets up a self-hosted GitHub Actions runner for iOS/macOS development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RUNNER_NAME="${RUNNER_NAME:-$(hostname)-runner}"
RUNNER_WORK_DIR="${RUNNER_WORK_DIR:-$HOME/actions-runner}"
RUNNER_VERSION="${RUNNER_VERSION:-2.311.0}"
REPO_URL="${REPO_URL:-https://github.com/thepian/record-thing}"

echo -e "${BLUE}🚀 GitHub Actions Self-Hosted Runner Setup${NC}"
echo -e "${BLUE}============================================${NC}"

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only"
    exit 1
fi

print_status "Running on macOS"

# Check for required tools
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi
print_status "Xcode is installed"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    print_warning "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
print_status "Homebrew is available"

# Install required tools
echo -e "${BLUE}Installing required tools...${NC}"

# Install SwiftLint if not present
if ! command -v swiftlint &> /dev/null; then
    print_warning "Installing SwiftLint..."
    brew install swiftlint
fi
print_status "SwiftLint is installed"

# Install jq for JSON processing
if ! command -v jq &> /dev/null; then
    print_warning "Installing jq..."
    brew install jq
fi
print_status "jq is installed"

# Create runner directory
echo -e "${BLUE}Setting up runner directory...${NC}"
mkdir -p "$RUNNER_WORK_DIR"
cd "$RUNNER_WORK_DIR"

# Download GitHub Actions runner
echo -e "${BLUE}Downloading GitHub Actions runner...${NC}"
RUNNER_ARCH="osx-x64"
if [[ $(uname -m) == "arm64" ]]; then
    RUNNER_ARCH="osx-arm64"
fi

RUNNER_PACKAGE="actions-runner-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
DOWNLOAD_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_PACKAGE}"

if [[ ! -f "$RUNNER_PACKAGE" ]]; then
    print_status "Downloading runner package..."
    curl -o "$RUNNER_PACKAGE" -L "$DOWNLOAD_URL"
else
    print_status "Runner package already exists"
fi

# Extract runner
if [[ ! -f "run.sh" ]]; then
    print_status "Extracting runner..."
    tar xzf "$RUNNER_PACKAGE"
else
    print_status "Runner already extracted"
fi

# Get registration token
echo -e "${BLUE}Getting registration token...${NC}"
echo -e "${YELLOW}You need to provide a GitHub Personal Access Token with 'repo' scope.${NC}"
echo -e "${YELLOW}You can create one at: https://github.com/settings/tokens${NC}"
echo ""

if [[ -z "$GITHUB_TOKEN" ]]; then
    read -p "Enter your GitHub Personal Access Token: " -s GITHUB_TOKEN
    echo ""
fi

# Get registration token from GitHub API
REGISTRATION_TOKEN=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "$REPO_URL/actions/runners/registration-token" | jq -r .token)

if [[ "$REGISTRATION_TOKEN" == "null" || -z "$REGISTRATION_TOKEN" ]]; then
    print_error "Failed to get registration token. Check your GitHub token and repository access."
    exit 1
fi

print_status "Registration token obtained"

# Configure runner
echo -e "${BLUE}Configuring runner...${NC}"
./config.sh \
    --url "$REPO_URL" \
    --token "$REGISTRATION_TOKEN" \
    --name "$RUNNER_NAME" \
    --work "_work" \
    --labels "macos,xcode,ios,swift" \
    --unattended

print_status "Runner configured successfully"

# Create launchd plist for auto-start
echo -e "${BLUE}Setting up auto-start service...${NC}"

PLIST_FILE="$HOME/Library/LaunchAgents/com.github.actions.runner.plist"
cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.github.actions.runner</string>
    <key>ProgramArguments</key>
    <array>
        <string>$RUNNER_WORK_DIR/run.sh</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$RUNNER_WORK_DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/github-runner.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/github-runner-error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Xcode.app/Contents/Developer/usr/bin</string>
    </dict>
</dict>
</plist>
EOF

# Load the service
launchctl load "$PLIST_FILE"
print_status "Auto-start service configured"

# Create management scripts
echo -e "${BLUE}Creating management scripts...${NC}"

# Start script
cat > "$RUNNER_WORK_DIR/start-runner.sh" << 'EOF'
#!/bin/bash
launchctl load ~/Library/LaunchAgents/com.github.actions.runner.plist
echo "✅ GitHub Actions runner started"
EOF

# Stop script
cat > "$RUNNER_WORK_DIR/stop-runner.sh" << 'EOF'
#!/bin/bash
launchctl unload ~/Library/LaunchAgents/com.github.actions.runner.plist
echo "🛑 GitHub Actions runner stopped"
EOF

# Status script
cat > "$RUNNER_WORK_DIR/status-runner.sh" << 'EOF'
#!/bin/bash
if launchctl list | grep -q "com.github.actions.runner"; then
    echo "✅ GitHub Actions runner is running"
    echo "📊 Recent logs:"
    tail -n 10 ~/Library/Logs/github-runner.log
else
    echo "❌ GitHub Actions runner is not running"
fi
EOF

# Make scripts executable
chmod +x "$RUNNER_WORK_DIR"/*.sh

print_status "Management scripts created"

echo ""
echo -e "${GREEN}🎉 GitHub Actions Runner Setup Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}Runner Details:${NC}"
echo -e "  Name: $RUNNER_NAME"
echo -e "  Directory: $RUNNER_WORK_DIR"
echo -e "  Repository: $REPO_URL"
echo -e "  Labels: macos, xcode, ios, swift"
echo ""
echo -e "${BLUE}Management Commands:${NC}"
echo -e "  Start:  $RUNNER_WORK_DIR/start-runner.sh"
echo -e "  Stop:   $RUNNER_WORK_DIR/stop-runner.sh"
echo -e "  Status: $RUNNER_WORK_DIR/status-runner.sh"
echo ""
echo -e "${BLUE}Logs:${NC}"
echo -e "  Output: ~/Library/Logs/github-runner.log"
echo -e "  Errors: ~/Library/Logs/github-runner-error.log"
echo ""
echo -e "${YELLOW}The runner is now starting automatically and will restart on system reboot.${NC}"
echo -e "${YELLOW}Check the GitHub repository settings to see the runner status.${NC}"
