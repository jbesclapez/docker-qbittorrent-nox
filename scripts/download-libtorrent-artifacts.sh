#!/bin/bash

# Script to download and install pre-built libtorrent GhostTrackers artifacts
# This script handles GitHub Actions artifacts that require authentication

set -euo pipefail

ARTIFACT_URL="${1:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
INSTALL_PREFIX="${2:-/usr}"

echo "=== GhostTrackers libtorrent Artifact Installer ==="

if [ -z "$ARTIFACT_URL" ]; then
    echo "Error: No artifact URL provided"
    echo "Usage: $0 <artifact_url> [install_prefix]"
    echo "Example: $0 https://github.com/jbesclapez/libtorrent/actions/runs/16276276484/artifacts/3529935533 /usr"
    exit 1
fi

echo "Artifact URL: $ARTIFACT_URL"
echo "Install prefix: $INSTALL_PREFIX"

# Extract repository and run information from the URL
if [[ "$ARTIFACT_URL" =~ github\.com/([^/]+)/([^/]+)/actions/runs/([0-9]+)/artifacts/([0-9]+) ]]; then
    REPO_OWNER="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
    RUN_ID="${BASH_REMATCH[3]}"
    ARTIFACT_ID="${BASH_REMATCH[4]}"
    
    echo "Repository: $REPO_OWNER/$REPO_NAME"
    echo "Run ID: $RUN_ID"
    echo "Artifact ID: $ARTIFACT_ID"
else
    echo "Error: Unable to parse GitHub Actions artifact URL"
    echo "Expected format: https://github.com/OWNER/REPO/actions/runs/RUN_ID/artifacts/ARTIFACT_ID"
    exit 1
fi

# Check if we're running in GitHub Actions (where we have access to artifacts)
if [ -n "${GITHUB_TOKEN:-}" ] && [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "Running in GitHub Actions environment, attempting to download artifact..."
    
    # Use GitHub CLI if available
    if command -v gh >/dev/null 2>&1; then
        echo "Using GitHub CLI to download artifact..."
        gh auth login --with-token <<< "$GITHUB_TOKEN"
        
        # Download the artifact
        echo "Downloading artifact $ARTIFACT_ID from run $RUN_ID..."
        gh run download "$RUN_ID" --repo "$REPO_OWNER/$REPO_NAME" --name "libtorrent-build" || {
            echo "Failed to download with specific name, trying without name filter..."
            gh run download "$RUN_ID" --repo "$REPO_OWNER/$REPO_NAME"
        }
        
        # Find and extract the artifact
        if [ -f "libtorrent-build.zip" ]; then
            echo "Extracting libtorrent-build.zip..."
            unzip -q libtorrent-build.zip
        elif [ -f "*.zip" ]; then
            echo "Extracting found zip file..."
            unzip -q *.zip
        else
            echo "Warning: No zip file found, falling back to source build"
            exit 2
        fi
        
        # Install the libraries
        if [ -d "usr" ]; then
            echo "Installing libtorrent libraries to $INSTALL_PREFIX..."
            cp -r usr/* "$INSTALL_PREFIX/"
            echo "✅ Successfully installed pre-built GhostTrackers libtorrent"
            exit 0
        else
            echo "Warning: Expected library structure not found in artifact"
            exit 2
        fi
    else
        echo "GitHub CLI not available, falling back to source build"
        exit 2
    fi
else
    echo "Not running in GitHub Actions or no token available"
    echo "Note: GitHub Actions artifacts require authentication and are only accessible from within GitHub Actions"
    echo "Falling back to source build..."
    exit 2
fi 