#!/bin/bash

set -e

CONFIG_FILE=".submodule-versions.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Config file $CONFIG_FILE not found."
  exit 1
fi

# Parse the JSON and loop through submodules
jq -r 'to_entries[] | "\(.key)\t\(.value)"' "$CONFIG_FILE" | while IFS=$'\t' read -r submodule_path expected_tag; do
  echo "🔍 Checking $submodule_path against expected tag $expected_tag"

  if [ ! -d "$submodule_path" ]; then
    echo "❌ Submodule path $submodule_path not found"
    exit 1
  fi

  cd "$submodule_path"
  git fetch --tags > /dev/null 2>&1
  current_commit=$(git rev-parse HEAD)

  if git tag --points-at "$current_commit" | grep -qx "$expected_tag"; then
    echo "✅ $submodule_path is correctly pinned to $expected_tag"
  else
    echo "❌ $submodule_path is NOT at expected tag $expected_tag"
    echo "Current commit: $current_commit"
    echo "Tags at this commit: $(git tag --points-at "$current_commit")"
    exit 1
  fi

  cd - > /dev/null
done


echo "✅ All submodules are correctly pinned"