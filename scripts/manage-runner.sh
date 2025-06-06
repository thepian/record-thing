#!/bin/bash

# GitHub Actions Runner Management Script
# Provides easy commands to manage your self-hosted runner

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

RUNNER_WORK_DIR="${RUNNER_WORK_DIR:-$HOME/actions-runner}"
PLIST_FILE="$HOME/Library/LaunchAgents/com.github.actions.runner.plist"

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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if runner is installed
check_runner_installed() {
    if [[ ! -d "$RUNNER_WORK_DIR" ]] || [[ ! -f "$RUNNER_WORK_DIR/run.sh" ]]; then
        print_error "GitHub Actions runner is not installed."
        print_info "Run './setup-github-runner.sh' to install it."
        exit 1
    fi
}

# Check runner status
status() {
    echo -e "${BLUE}GitHub Actions Runner Status${NC}"
    echo -e "${BLUE}=============================${NC}"
    
    if [[ ! -f "$PLIST_FILE" ]]; then
        print_error "Runner service is not configured"
        return 1
    fi
    
    if launchctl list | grep -q "com.github.actions.runner"; then
        print_status "Runner service is running"
        
        # Check if runner process is actually running
        if pgrep -f "Runner.Listener" > /dev/null; then
            print_status "Runner process is active"
        else
            print_warning "Runner service is loaded but process may not be running"
        fi
        
        # Show recent logs
        echo ""
        echo -e "${BLUE}Recent Activity (last 10 lines):${NC}"
        if [[ -f "$HOME/Library/Logs/github-runner.log" ]]; then
            tail -n 10 "$HOME/Library/Logs/github-runner.log"
        else
            print_warning "No log file found"
        fi
        
    else
        print_error "Runner service is not running"
        return 1
    fi
}

# Start runner
start() {
    echo -e "${BLUE}Starting GitHub Actions Runner...${NC}"
    
    check_runner_installed
    
    if launchctl list | grep -q "com.github.actions.runner"; then
        print_warning "Runner is already running"
        return 0
    fi
    
    launchctl load "$PLIST_FILE"
    sleep 2
    
    if launchctl list | grep -q "com.github.actions.runner"; then
        print_status "Runner started successfully"
    else
        print_error "Failed to start runner"
        return 1
    fi
}

# Stop runner
stop() {
    echo -e "${BLUE}Stopping GitHub Actions Runner...${NC}"
    
    if ! launchctl list | grep -q "com.github.actions.runner"; then
        print_warning "Runner is not running"
        return 0
    fi
    
    launchctl unload "$PLIST_FILE"
    sleep 2
    
    if ! launchctl list | grep -q "com.github.actions.runner"; then
        print_status "Runner stopped successfully"
    else
        print_error "Failed to stop runner"
        return 1
    fi
}

# Restart runner
restart() {
    echo -e "${BLUE}Restarting GitHub Actions Runner...${NC}"
    stop
    sleep 1
    start
}

# Show logs
logs() {
    local lines=${1:-50}
    
    echo -e "${BLUE}GitHub Actions Runner Logs (last $lines lines)${NC}"
    echo -e "${BLUE}============================================${NC}"
    
    if [[ -f "$HOME/Library/Logs/github-runner.log" ]]; then
        tail -n "$lines" "$HOME/Library/Logs/github-runner.log"
    else
        print_warning "No log file found at ~/Library/Logs/github-runner.log"
    fi
    
    echo ""
    echo -e "${BLUE}Error Logs:${NC}"
    if [[ -f "$HOME/Library/Logs/github-runner-error.log" ]]; then
        tail -n "$lines" "$HOME/Library/Logs/github-runner-error.log"
    else
        print_info "No error log file found"
    fi
}

# Follow logs in real-time
follow() {
    echo -e "${BLUE}Following GitHub Actions Runner Logs (Ctrl+C to exit)${NC}"
    echo -e "${BLUE}=====================================================${NC}"
    
    if [[ -f "$HOME/Library/Logs/github-runner.log" ]]; then
        tail -f "$HOME/Library/Logs/github-runner.log"
    else
        print_error "No log file found at ~/Library/Logs/github-runner.log"
        exit 1
    fi
}

# Update runner
update() {
    echo -e "${BLUE}Updating GitHub Actions Runner...${NC}"
    
    check_runner_installed
    
    print_warning "This will stop the current runner and download the latest version"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Update cancelled"
        return 0
    fi
    
    # Stop runner
    stop
    
    # Remove runner
    cd "$RUNNER_WORK_DIR"
    ./config.sh remove --token "$GITHUB_TOKEN"
    
    # Re-run setup script
    print_info "Please run './setup-github-runner.sh' to install the latest version"
}

# Remove runner completely
remove() {
    echo -e "${BLUE}Removing GitHub Actions Runner...${NC}"
    
    print_warning "This will completely remove the runner and all its data"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removal cancelled"
        return 0
    fi
    
    # Stop runner
    stop
    
    # Remove from GitHub
    if [[ -d "$RUNNER_WORK_DIR" ]] && [[ -f "$RUNNER_WORK_DIR/config.sh" ]]; then
        cd "$RUNNER_WORK_DIR"
        if [[ -n "$GITHUB_TOKEN" ]]; then
            ./config.sh remove --token "$GITHUB_TOKEN"
        else
            print_warning "No GITHUB_TOKEN provided. You may need to manually remove the runner from GitHub."
        fi
    fi
    
    # Remove plist file
    if [[ -f "$PLIST_FILE" ]]; then
        rm "$PLIST_FILE"
        print_status "Removed service configuration"
    fi
    
    # Remove runner directory
    if [[ -d "$RUNNER_WORK_DIR" ]]; then
        rm -rf "$RUNNER_WORK_DIR"
        print_status "Removed runner directory"
    fi
    
    print_status "Runner removed completely"
}

# Show help
help() {
    echo -e "${BLUE}GitHub Actions Runner Management${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  status    - Show runner status and recent activity"
    echo "  start     - Start the runner service"
    echo "  stop      - Stop the runner service"
    echo "  restart   - Restart the runner service"
    echo "  logs [n]  - Show last n lines of logs (default: 50)"
    echo "  follow    - Follow logs in real-time"
    echo "  update    - Update runner to latest version"
    echo "  remove    - Completely remove the runner"
    echo "  help      - Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  RUNNER_WORK_DIR - Runner installation directory (default: ~/actions-runner)"
    echo "  GITHUB_TOKEN    - GitHub Personal Access Token (required for update/remove)"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 logs 100"
    echo "  $0 restart"
}

# Main command handling
case "${1:-help}" in
    status)
        status
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    logs)
        logs "${2:-50}"
        ;;
    follow)
        follow
        ;;
    update)
        update
        ;;
    remove)
        remove
        ;;
    help|--help|-h)
        help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        help
        exit 1
        ;;
esac
