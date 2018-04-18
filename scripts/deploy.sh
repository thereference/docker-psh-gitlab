#!/usr/bin/env bash
set -e

# Push Gitlab branches to Platform.sh environments.
# -------------------------------------------------
#
# This script can be configured by specifying environment variables in your
# repository settings or in the .gitlab-ci.yml file:
#
# variables:
#
#     # The project ID (required).
#     PF_PROJECT_ID: abcdefg123456
#
#     # The platform.sh API token (required).
#     PLATFORMSH_CLI_TOKEN: b5801542ac9f0cae...
#
#     # The parent environment of new branches.
#     PF_PARENT_ENV: master

if [ -z "$PF_PROJECT_ID" ]; then
  echo "PF_PROJECT_ID is required"
  exit 1
fi

if [ -z "$PLATFORMSH_CLI_TOKEN" ]; then
  echo "PLATFORMSH_CLI_TOKEN is required"
  exit 1
fi

PF_PARENT_ENV=${PF_PARENT_ENV:-master}
PF_BRANCH=${PF_DEST_BRANCH:-$CI_COMMIT_REF_NAME}

if [ -z "$PF_BRANCH" ]; then
  echo "Branch name (CI_BUILD_REF_NAME or PF_DEST_BRANCH) not defined."
  exit 1
fi

# Set the project for further CLI commands.
platform project:set-remote "$PF_PROJECT_ID"

# Get a URL to the web UI for this environment, before pushing.
pf_ui=$(platform web --environment="$PF_BRANCH" --pipe)
echo ""
echo "Web UI: ${pf_ui}"
echo ""

# Build the push command.
push_command="platform push --force --target=${PF_BRANCH}"
if [ "$PF_PARENT_ENV" != "$PF_BRANCH" ]; then
  push_command="$push_command --activate --parent=${PF_PARENT_ENV}"
fi

# Run the push command, copying its output to push.log.
$push_command 2>&1 | tee push.log

# Analyse the result for a push failure or build failure.
push_result=${PIPESTATUS[0]}
[ "$push_result" != 0 ] && exit "$push_result"
build_error=$(grep -m 1 'Unable to build project' push.log) || true
rm push.log || true
[ ! -z "$build_error" ] && exit 1

# Clean up already merged and inactive environments.
platform environment:delete --inactive --merged --environment="$PF_PARENT_ENV" --exclude=master --exclude=development --exclude="$PF_BRANCH" --yes --delete-branch --no-wait || true
