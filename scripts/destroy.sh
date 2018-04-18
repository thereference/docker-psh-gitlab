#!/usr/bin/env bash
set -e

# Config.
if [ -z "$PLATFORMSH_CLI_TOKEN" ]; then
  echo "PLATFORMSH_CLI_TOKEN is required"
  exit 1
fi

if [ -z "$PF_PROJECT_ID" ]; then
  echo "PF_PROJECT_ID is required"
  exit 1
fi

PF_BRANCH=${PF_DEST_BRANCH:-$CI_COMMIT_REF_NAME}

if [ -z "$PF_BRANCH" ]; then
  echo "Branch name (CI_COMMIT_REF_NAME or PF_DEST_BRANCH) not defined."
  exit 1
fi

# Delete the specified branch.
platform environment:delete --yes --no-wait --project="$PF_PROJECT_ID" --environment="$PF_BRANCH"

# Clean up inactive environments.
platform environment:delete --project="$PF_PROJECT_ID" --inactive --exclude=master --yes --delete-branch --no-wait || true