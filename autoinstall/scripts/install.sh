#!/usr/bin/env bash
set -euo pipefail


install_vitals_minimal() {
  # Define explicit paths since $HOME might resolve to /root in cloud-init
  local TARGET_USER="xmars"
  local USER_HOME="/home/${TARGET_USER}"
  local EXT_UUID="Vitals@CoreCoding.com"
  local EXT_DIR="${USER_HOME}/.local/share/gnome-shell/extensions/${EXT_UUID}"

  echo "[Vitals] Installing GNOME Shell extension for ${TARGET_USER}"

  # 1. Create directory and clone as the specific user
  sudo -u "${TARGET_USER}" mkdir -p "$(dirname "${EXT_DIR}")"
  sudo -u "${TARGET_USER}" rm -rf "${EXT_DIR}"
  sudo -u "${TARGET_USER}" git clone --depth 1 \
    https://github.com/corecoding/Vitals.git \
    "${EXT_DIR}"

  # 2. Use dbus-run-session to apply settings without a live GUI session
  echo "[Vitals] Configuring metrics and enabling extension"
  sudo -u "${TARGET_USER}" dbus-run-session bash <<EOF
    # Set individual preferences
    gsettings set org.gnome.shell.extensions.vitals show-cpu true
    gsettings set org.gnome.shell.extensions.vitals show-memory true
    gsettings set org.gnome.shell.extensions.vitals show-storage true
    gsettings set org.gnome.shell.extensions.vitals show-temperature false
    gsettings set org.gnome.shell.extensions.vitals show-voltage false
    gsettings set org.gnome.shell.extensions.vitals show-fan false
    gsettings set org.gnome.shell.extensions.vitals show-network false
    gsettings set org.gnome.shell.extensions.vitals show-battery false

    # Enable the extension by adding it to the enabled-extensions list
    # This is more reliable than 'gnome-extensions enable' in a headless script
    current_exts=\$(gsettings get org.gnome.shell enabled-extensions)
    if [[ ! "\$current_exts" == *"${EXT_UUID}"* ]]; then
      # If list is empty/default '[]', handle it; otherwise append
      if [[ "\$current_exts" == "[]" || "\$current_exts" == "@as []" ]]; then
        new_exts="['${EXT_UUID}']"
      else
        new_exts="\${current_exts%]*}, '${EXT_UUID}']"
      fi
      gsettings set org.gnome.shell enabled-extensions "\$new_exts"
    fi
EOF

  echo "[Vitals] Done. Configuration applied to dconf database."
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

# clone_odoo_community_versions
install_vitals_minimal