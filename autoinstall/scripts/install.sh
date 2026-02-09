#!/usr/bin/env bash
set -euo pipefail

# Clone Odoo community versions (shallow, latest commit only)
# Folder structure:
#   <BASE_DIR>/
#     ├── 16/
#     ├── 17/
#     ├── 18/
#     └── 19/
#
# Usage:
#   ./clone_odoo_versions.sh /path/to/odoo-versions
# If no path is given, defaults to ./odoo-versions

BASE_DIR="${1:-./odoo-versions}"

# Map branch -> folder name
declare -A VERSIONS=(
  ["16.0"]="16"
  ["17.0"]="17"
  ["18.0"]="18"
  ["19.0"]="19"
)

REPO_URL="https://github.com/odoo/odoo.git"

mkdir -p "$BASE_DIR"

for branch in "${!VERSIONS[@]}"; do
  folder="${VERSIONS[$branch]}"
  dest="${BASE_DIR}/${folder}"

  echo "==> Cloning Odoo ${branch} into: ${dest}"

  if [[ -d "$dest" ]]; then
    echo "    - Destination already exists, skipping: $dest"
    continue
    # Uncomment if you prefer overwrite behavior:
    # rm -rf "$dest"
  fi

  # Shallow clone: latest commit only for that branch
  git clone --depth 1 --branch "$branch" "$REPO_URL" "$dest"
done

echo "Done. Cloned Odoo versions into: $BASE_DIR"