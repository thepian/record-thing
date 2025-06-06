#!/bin/bash

# GitHub Actions Test Status Checker
# Quickly check the status of recent workflow runs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPO="thepian/record-thing"
GITHUB_API="https://api.github.com"

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

# Check if jq is available
if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed. Install with: brew install jq"
    exit 1
fi

echo -e "${BLUE}GitHub Actions Test Status${NC}"
echo -e "${BLUE}==========================${NC}"
echo ""

# Get recent workflow runs
print_info "Fetching recent workflow runs..."

RUNS_JSON=$(curl -s -H "Accept: application/vnd.github.v3+json" \
    "$GITHUB_API/repos/$REPO/actions/runs?per_page=10")

if [[ $? -ne 0 ]]; then
    print_error "Failed to fetch workflow runs from GitHub API"
    exit 1
fi

# Parse and display results
echo "$RUNS_JSON" | jq -r '.workflow_runs[] | 
    "\(.workflow_name)|\(.status)|\(.conclusion)|\(.created_at)|\(.head_branch)|\(.html_url)"' | \
while IFS='|' read -r workflow status conclusion created_at branch url; do
    
    # Format date
    formatted_date=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_at" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$created_at")
    
    # Determine status icon and color
    if [[ "$status" == "completed" ]]; then
        if [[ "$conclusion" == "success" ]]; then
            status_icon="✅"
            status_color="$GREEN"
        elif [[ "$conclusion" == "failure" ]]; then
            status_icon="❌"
            status_color="$RED"
        elif [[ "$conclusion" == "cancelled" ]]; then
            status_icon="🚫"
            status_color="$YELLOW"
        else
            status_icon="❓"
            status_color="$YELLOW"
        fi
    elif [[ "$status" == "in_progress" ]]; then
        status_icon="🔄"
        status_color="$BLUE"
    else
        status_icon="⏸️"
        status_color="$YELLOW"
    fi
    
    echo -e "${status_color}${status_icon} ${workflow}${NC}"
    echo -e "   Branch: $branch"
    echo -e "   Status: $status ($conclusion)"
    echo -e "   Date: $formatted_date"
    echo -e "   URL: $url"
    echo ""
done

echo -e "${BLUE}Recent Test Summary${NC}"
echo -e "${BLUE}==================${NC}"

# Count successes and failures
SUCCESS_COUNT=$(echo "$RUNS_JSON" | jq '[.workflow_runs[] | select(.conclusion == "success")] | length')
FAILURE_COUNT=$(echo "$RUNS_JSON" | jq '[.workflow_runs[] | select(.conclusion == "failure")] | length')
IN_PROGRESS_COUNT=$(echo "$RUNS_JSON" | jq '[.workflow_runs[] | select(.status == "in_progress")] | length')

echo -e "✅ Successful runs: $SUCCESS_COUNT"
echo -e "❌ Failed runs: $FAILURE_COUNT"
echo -e "🔄 In progress: $IN_PROGRESS_COUNT"

echo ""
echo -e "${BLUE}Quick Actions${NC}"
echo -e "${BLUE}=============${NC}"
echo "View all runs: https://github.com/$REPO/actions"
echo "Setup self-hosted runner: ./scripts/setup-github-runner.sh"
echo "Manage runner: ./scripts/manage-runner.sh status"

# Check for self-hosted runners
echo ""
print_info "Checking for self-hosted runners..."

if [[ -n "$GITHUB_TOKEN" ]]; then
    RUNNERS_JSON=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$GITHUB_API/repos/$REPO/actions/runners")
    
    RUNNER_COUNT=$(echo "$RUNNERS_JSON" | jq '.total_count // 0')
    
    if [[ "$RUNNER_COUNT" -gt 0 ]]; then
        print_status "Found $RUNNER_COUNT self-hosted runner(s)"
        
        echo "$RUNNERS_JSON" | jq -r '.runners[]? | 
            "\(.name)|\(.status)|\(.os)|\(.labels[].name)"' | \
        while IFS='|' read -r name status os labels; do
            if [[ "$status" == "online" ]]; then
                echo -e "  ${GREEN}✅ $name${NC} ($os) - $labels"
            else
                echo -e "  ${RED}❌ $name${NC} ($os) - $status"
            fi
        done
    else
        print_warning "No self-hosted runners found"
        echo "  Run: ./scripts/setup-github-runner.sh"
    fi
else
    print_warning "Set GITHUB_TOKEN environment variable to check self-hosted runners"
fi
