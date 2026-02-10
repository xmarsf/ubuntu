#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
TARGET_USER="xmars"
USER_HOME="/home/${TARGET_USER}"

install_vitals_minimal() {
  local EXT_UUID="Vitals@CoreCoding.com"
  local EXT_DIR="${USER_HOME}/.local/share/gnome-shell/extensions/${EXT_UUID}"

  echo "[Vitals] Installing GNOME Shell extension for ${TARGET_USER}"
  
  # Check if user exists before running sudo
  if ! id "$TARGET_USER" &>/dev/null; then
      echo "User $TARGET_USER does not exist!"
      return 1
  fi

  sudo -u "${TARGET_USER}" mkdir -p "$(dirname "${EXT_DIR}")"
  sudo -u "${TARGET_USER}" rm -rf "${EXT_DIR}"
  
  sudo -u "${TARGET_USER}" git clone --depth 1 \
    https://github.com/corecoding/Vitals.git \
    "${EXT_DIR}"

  echo "[Vitals] Configuring metrics..."
  # dbus-run-session is correct here for cloud-init context
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
setup_fcitx5_unikey() {
    echo "[Fcitx5] Configuring for ${TARGET_USER}..."

    # 1. Use im-config to set Fcitx5 as the active IM for the user
    # This creates ~/.xinputrc and ensures GTK/QT modules load correctly on next login.
    sudo -u "${TARGET_USER}" im-config -n fcitx5

    # 2. Create the Fcitx5 Config Directory
    local CONFIG_DIR="${USER_HOME}/.config/fcitx5"
    sudo -u "${TARGET_USER}" mkdir -p "${CONFIG_DIR}"

    # 3. Create the Profile (Force Unikey as Default)
    # This format is standard for Fcitx5.
    cat <<EOF | sudo -u "${TARGET_USER}" tee "${CONFIG_DIR}/profile" > /dev/null
[Groups/0]
Name=Default
Default Layout=us
Default IM=unikey

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=unikey
Layout=

[GroupList]
0=Default
EOF

    # 4. Create an Autostart Entry (Insurance)
    # Sometimes GNOME doesn't start the IM automatically on the very first run.
    local AUTOSTART_DIR="${USER_HOME}/.config/autostart"
    sudo -u "${TARGET_USER}" mkdir -p "${AUTOSTART_DIR}"
    cp /usr/share/applications/org.fcitx.Fcitx5.desktop "${AUTOSTART_DIR}/"
    chown "${TARGET_USER}:${TARGET_USER}" "${AUTOSTART_DIR}/org.fcitx.Fcitx5.desktop"

    # 5. Global Environment Variables (Backup)
    # Even with im-config, these help specific apps (like Electron apps) behave.
    # Note: These will only apply after a REBOOT.
    if ! grep -q "INPUT_METHOD=fcitx5" /etc/environment; then
        cat <<EOF >> /etc/environment
INPUT_METHOD=fcitx5
GTK_IM_MODULE=fcitx5
QT_IM_MODULE=fcitx5
XMODIFIERS=@im=fcitx5
EOF
    fi
}

# --- Execution ---
install_vitals_minimal
setup_fcitx5_unikey
clone_odoo_community_versions