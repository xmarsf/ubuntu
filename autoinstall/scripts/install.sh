#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
TARGET_USER="xmars"
USER_HOME="/home/${TARGET_USER}"

install_vitals_minimal() {
  local EXT_UUID="Vitals@CoreCoding.com"
  local EXT_DIR="${USER_HOME}/.local/share/gnome-shell/extensions/${EXT_UUID}"

  echo "[Vitals] Installing GNOME Shell extension for ${TARGET_USER}"

  # Ensure directory structure exists with correct ownership
  sudo -u "${TARGET_USER}" mkdir -p "$(dirname "${EXT_DIR}")"
  sudo -u "${TARGET_USER}" rm -rf "${EXT_DIR}"
  
  # Clone directly as user
  sudo -u "${TARGET_USER}" git clone --depth 1 \
    https://github.com/corecoding/Vitals.git \
    "${EXT_DIR}"

  echo "[Vitals] Configuring metrics and enabling extension"
  # Use dbus-run-session to bypass the lack of an X11 session during cloud-init
  sudo -u "${TARGET_USER}" dbus-run-session bash <<EOF
    gsettings set org.gnome.shell.extensions.vitals show-cpu true
    gsettings set org.gnome.shell.extensions.vitals show-memory true
    gsettings set org.gnome.shell.extensions.vitals show-storage true
    gsettings set org.gnome.shell.extensions.vitals show-temperature false
    gsettings set org.gnome.shell.extensions.vitals show-voltage false
    gsettings set org.gnome.shell.extensions.vitals show-fan false
    gsettings set org.gnome.shell.extensions.vitals show-network false
    gsettings set org.gnome.shell.extensions.vitals show-battery false

    current_exts=\$(gsettings get org.gnome.shell enabled-extensions)
    if [[ ! "\$current_exts" == *"${EXT_UUID}"* ]]; then
      if [[ "\$current_exts" == "[]" || "\$current_exts" == "@as []" ]]; then
        new_exts="['${EXT_UUID}']"
      else
        new_exts="\${current_exts%]*}, '${EXT_UUID}']"
      fi
      gsettings set org.gnome.shell enabled-extensions "\$new_exts"
    fi
EOF
}

clone_odoo_community_versions() {
  local BASE_DIR="${USER_HOME}/dev/odoo"
  local REPO_URL="https://github.com/odoo/odoo.git"

  declare -A VERSIONS=(
    ["16.0"]="16"
    ["17.0"]="17"
    ["18.0"]="18"
    ["19.0"]="19"
  )

  echo "[Odoo] Base directory: ${BASE_DIR}"
  # Ensure the base directory is owned by xmars before cloning
  mkdir -p "${BASE_DIR}"
  chown "${TARGET_USER}:${TARGET_USER}" "${BASE_DIR}"

  for branch in "${!VERSIONS[@]}"; do
    local folder="ce-${VERSIONS[$branch]}"
    local dest="${BASE_DIR}/${folder}"

    if [[ -d "${dest}/.git" ]]; then
      echo "[Odoo] Skipping existing: ${dest}"
      continue
    fi

    echo "[Odoo] Cloning ${branch} to ${dest}"
    sudo -u "${TARGET_USER}" git clone \
      --depth 1 \
      --branch "${branch}" \
      "${REPO_URL}" \
      "${dest}"
  done
}

# --- Execution ---
# These are called as root, but perform operations as xmars internally
install_vitals_minimal
clone_odoo_community_versions