#!/usr/bin/env bash
set -euo pipefail


install_vitals_minimal() {
  set -euo pipefail

  local EXT_UUID="Vitals@CoreCoding.com"
  local EXT_DIR="$HOME/.local/share/gnome-shell/extensions/${EXT_UUID}"

  echo "[Vitals] Installing GNOME Shell extension (user-level)"
  mkdir -p "$(dirname "${EXT_DIR}")"
  rm -rf "${EXT_DIR}"

  git clone --depth 1 \
    https://github.com/corecoding/Vitals.git \
    "${EXT_DIR}"

  echo "[Vitals] Enabling extension"
  gnome-extensions enable "${EXT_UUID}" || true

  echo "[Vitals] Configuring metrics (CPU / RAM / Disk only)"
  gsettings set org.gnome.shell.extensions.vitals show-cpu true
  gsettings set org.gnome.shell.extensions.vitals show-memory true
  gsettings set org.gnome.shell.extensions.vitals show-storage true

  gsettings set org.gnome.shell.extensions.vitals show-temperature false
  gsettings set org.gnome.shell.extensions.vitals show-voltage false
  gsettings set org.gnome.shell.extensions.vitals show-fan false
  gsettings set org.gnome.shell.extensions.vitals show-network false
  gsettings set org.gnome.shell.extensions.vitals show-battery false

  echo "[Vitals] Done (may require logout/login)"
}

clone_odoo_community_versions() {
  set -euo pipefail

  local USER_NAME="xmars"
  local BASE_DIR="${1:-/home/${USER_NAME}/dev/odoo}"
  local REPO_URL="https://github.com/odoo/odoo.git"

  # Map branch -> folder suffix
  declare -A VERSIONS=(
    ["16.0"]="16"
    ["17.0"]="17"
    ["18.0"]="18"
    ["19.0"]="19"
  )

  echo "[Odoo] Base directory: ${BASE_DIR}"
  mkdir -p "${BASE_DIR}"
  chown -R "${USER_NAME}:${USER_NAME}" "${BASE_DIR}"

  for branch in "${!VERSIONS[@]}"; do
    local folder="ce-${VERSIONS[$branch]}"
    local dest="${BASE_DIR}/${folder}"

    echo "[Odoo] Cloning community ${branch} → ${dest}"

    if [[ -d "${dest}/.git" || -d "${dest}" ]]; then
      echo "[Odoo]   - Exists, skipping: ${dest}"
      continue
    fi

    # Clone as target user (clean ownership, no root-owned files)
    sudo -u "${USER_NAME}" git clone \
      --depth 1 \
      --branch "${branch}" \
      "${REPO_URL}" \
      "${dest}"
  done

  echo "[Odoo] Done. Community versions available under: ${BASE_DIR}"
}

clone_odoo_community_versions
install_vitals_minimal