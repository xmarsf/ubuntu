#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
TARGET_USER="xmars"
USER_HOME="/home/${TARGET_USER}"

install_vitals_minimal() {
  local EXT_UUID="Vitals@CoreCoding.com"
  local EXT_DIR="${USER_HOME}/.local/share/gnome-shell/extensions/${EXT_UUID}"
  local SCHEMAS_DIR="${EXT_DIR}/schemas"

  echo "[Vitals] Installing GNOME Shell extension for ${TARGET_USER}..."
  
  if ! id "$TARGET_USER" &>/dev/null; then
      echo "Error: User $TARGET_USER does not exist!"
      return 1
  fi

  # 1. Clean and Clone
  sudo -u "${TARGET_USER}" mkdir -p "$(dirname "${EXT_DIR}")"
  sudo -u "${TARGET_USER}" rm -rf "${EXT_DIR}"
  
  echo "[Vitals] Cloning repository..."
  sudo -u "${TARGET_USER}" git clone --depth 1 \
    https://github.com/corecoding/Vitals.git \
    "${EXT_DIR}"

  # 2. Compile Schemas
  echo "[Vitals] Compiling GSettings schemas..."
  sudo -u "${TARGET_USER}" glib-compile-schemas "${SCHEMAS_DIR}"

  # 3. Configure settings
  # We use --schemadir so gsettings knows exactly where to look for the Vitals schema
  echo "[Vitals] Configuring metrics..."
  sudo -u "${TARGET_USER}" dbus-run-session bash <<EOF
    # Define schema dir inside the session for clarity
    SCHEMAS="${SCHEMAS_DIR}"

    # Note: We use --schemadir for Vitals commands because the extension isn't loaded yet.
    gsettings --schemadir "\$SCHEMAS" set org.gnome.shell.extensions.vitals show-cpu true
    gsettings --schemadir "\$SCHEMAS" set org.gnome.shell.extensions.vitals show-memory true
    gsettings --schemadir "\$SCHEMAS" set org.gnome.shell.extensions.vitals show-storage false
    gsettings --schemadir "\$SCHEMAS" set org.gnome.shell.extensions.vitals show-temperature false
    gsettings --schemadir "\$SCHEMAS" set org.gnome.shell.extensions.vitals show-voltage false
    gsettings --schemadir "\$SCHEMAS" set org.gnome.shell.extensions.vitals show-fan false
    gsettings --schemadir "\$SCHEMAS" set org.gnome.shell.extensions.vitals show-network false
    gsettings --schemadir "\$SCHEMAS" set org.gnome.shell.extensions.vitals show-battery false

    # Enable the extension (This uses the standard schema, so no --schemadir needed here)
    current_exts=\$(gsettings get org.gnome.shell enabled-extensions)
    if [[ "\$current_exts" != *"${EXT_UUID}"* ]]; then
      if [[ "\$current_exts" == "[]" || "\$current_exts" == "@as []" ]]; then
        new_exts="['${EXT_UUID}']"
      else
        new_exts="\${current_exts%]*}, '${EXT_UUID}']"
      fi
      gsettings set org.gnome.shell enabled-extensions "\$new_exts"
    fi
EOF

  echo "[Vitals] Success: Vitals extension installed and enabled for ${TARGET_USER}."
}

install_pycharm_pro() {
  echo "[PyCharm] Installing PyCharm Professional for ${TARGET_USER}..."

  sudo -u ${TARGET_USER} -H bash -lc '
    set -euo pipefail

    INSTALL_DIR="$HOME/.local/share/JetBrains/pycharm"
    BIN_DIR="$HOME/.local/bin"
    DESKTOP_DIR="$HOME/.local/share/applications"

    # Get the latest PyCharm Pro download URL from JetBrains API
    PYCHARM_URL=$(curl -s "https://data.services.jetbrains.com/products/releases?code=PCP&latest=true&type=release" \
      | grep -Po "\"linux\":\{\"link\":\"\K[^\"]+")

    TEMP_DIR=$(mktemp -d)
    echo "[PyCharm] Downloading..."
    curl -fsSL -o "${TEMP_DIR}/pycharm.tar.gz" "${PYCHARM_URL}"

    echo "[PyCharm] Extracting to ${INSTALL_DIR}..."
    rm -rf "${INSTALL_DIR}"
    mkdir -p "${INSTALL_DIR}"
    tar -xzf "${TEMP_DIR}/pycharm.tar.gz" --strip-components=1 -C "${INSTALL_DIR}"
    rm -rf "${TEMP_DIR}"

    # Create symlink in ~/.local/bin for PATH access
    mkdir -p "${BIN_DIR}"
    ln -sf "${INSTALL_DIR}/bin/pycharm" "${BIN_DIR}/pycharm"

    # Create desktop entry for GNOME integration
    mkdir -p "${DESKTOP_DIR}"
    cat > "${DESKTOP_DIR}/pycharm-professional.desktop" <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=PyCharm Professional
Icon=${INSTALL_DIR}/bin/pycharm.svg
Exec=${INSTALL_DIR}/bin/pycharm %f
Comment=Python IDE for Professional Developers
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-pycharm



StartupNotify=true
DESKTOP

    echo "[PyCharm] PyCharm Professional installed to ${INSTALL_DIR}"
  '
}

install_rustrover() {
  echo "[RustRover] Installing RustRover for ${TARGET_USER}..."

  sudo -u ${TARGET_USER} -H bash -lc '
    set -euo pipefail

    INSTALL_DIR="$HOME/.local/share/JetBrains/rustrover"
    BIN_DIR="$HOME/.local/bin"
    DESKTOP_DIR="$HOME/.local/share/applications"

    # Get the latest RustRover download URL from JetBrains API
    RUSTROVER_URL=$(curl -s "https://data.services.jetbrains.com/products/releases?code=RR&latest=true&type=release" \
      | grep -Po "\"linux\":\{\"link\":\"\K[^\"]+")

    TEMP_DIR=$(mktemp -d)
    echo "[RustRover] Downloading..."
    curl -fsSL -o "${TEMP_DIR}/rustrover.tar.gz" "${RUSTROVER_URL}"

    echo "[RustRover] Extracting to ${INSTALL_DIR}..."
    rm -rf "${INSTALL_DIR}"
    mkdir -p "${INSTALL_DIR}"
    tar -xzf "${TEMP_DIR}/rustrover.tar.gz" --strip-components=1 -C "${INSTALL_DIR}"
    rm -rf "${TEMP_DIR}"

    # Create symlink in ~/.local/bin for PATH access
    mkdir -p "${BIN_DIR}"
    ln -sf "${INSTALL_DIR}/bin/rustrover" "${BIN_DIR}/rustrover"

    # Create desktop entry for GNOME integration
    mkdir -p "${DESKTOP_DIR}"
    cat > "${DESKTOP_DIR}/rustrover.desktop" <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=RustRover
Icon=${INSTALL_DIR}/bin/rustrover.svg
Exec=${INSTALL_DIR}/bin/rustrover %f
Comment=Rust IDE by JetBrains
Categories=Development;IDE;
Terminal=false
StartupWMClass=jetbrains-rustrover
StartupNotify=true
DESKTOP

    echo "[RustRover] RustRover installed to ${INSTALL_DIR}"
  '
}

install_datagrip() {
  echo "[DataGrip] Installing DataGrip for ${TARGET_USER}..."

  sudo -u ${TARGET_USER} -H bash -lc '
    set -euo pipefail

    INSTALL_DIR="$HOME/.local/share/JetBrains/datagrip"
    BIN_DIR="$HOME/.local/bin"
    DESKTOP_DIR="$HOME/.local/share/applications"

    # Get the latest DataGrip download URL from JetBrains API
    DATAGRIP_URL=$(curl -s "https://data.services.jetbrains.com/products/releases?code=DG&latest=true&type=release" \
      | grep -Po "\"linux\":\{\"link\":\"\K[^\"]+")

    TEMP_DIR=$(mktemp -d)
    echo "[DataGrip] Downloading..."
    curl -fsSL -o "${TEMP_DIR}/datagrip.tar.gz" "${DATAGRIP_URL}"

    echo "[DataGrip] Extracting to ${INSTALL_DIR}..."
    rm -rf "${INSTALL_DIR}"
    mkdir -p "${INSTALL_DIR}"
    tar -xzf "${TEMP_DIR}/datagrip.tar.gz" --strip-components=1 -C "${INSTALL_DIR}"
    rm -rf "${TEMP_DIR}"

    # Create symlink in ~/.local/bin for PATH access
    mkdir -p "${BIN_DIR}"
    ln -sf "${INSTALL_DIR}/bin/datagrip" "${BIN_DIR}/datagrip"

    # Create desktop entry for GNOME integration
    mkdir -p "${DESKTOP_DIR}"
    cat > "${DESKTOP_DIR}/datagrip.desktop" <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=DataGrip
Icon=${INSTALL_DIR}/bin/datagrip.svg
Exec=${INSTALL_DIR}/bin/datagrip %f
Comment=Database IDE by JetBrains
Categories=Development;IDE;Database;
Terminal=false
StartupWMClass=jetbrains-datagrip
StartupNotify=true
DESKTOP

    echo "[DataGrip] DataGrip installed to ${INSTALL_DIR}"
  '
}

install_warp_cli() {
  echo "[WARP] Installing Cloudflare WARP CLI..."

  # Add cloudflare gpg key
  curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg \
    | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

  # Add repo to apt sources
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/cloudflare-client.list > /dev/null

  # Install
  apt-get update
  apt-get install -y cloudflare-warp

  echo "[WARP] Cloudflare WARP CLI installed successfully."
}

install_google_chrome() {
  echo "[Chrome] Installing Google Chrome..."

  local DEB_FILE="/tmp/google-chrome-stable_current_amd64.deb"

  echo "[Chrome] Downloading .deb package..."
  wget -O "${DEB_FILE}" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

  echo "[Chrome] Installing..."
  apt-get install -y "${DEB_FILE}"

  rm -f "${DEB_FILE}"

  echo "[Chrome] Google Chrome installed successfully."
}

install_vscode() {
  echo "[VSCode] Installing Visual Studio Code..."

  local DEB_FILE="/tmp/code_latest.deb"

  # Download the .deb package
  echo "[VSCode] Downloading .deb package..."
  curl -L -o "${DEB_FILE}" "https://go.microsoft.com/fwlink/?LinkID=760868"

  # Auto-accept the Microsoft repo prompt for non-interactive install
  echo "code code/add-microsoft-repo boolean true" | debconf-set-selections

  # Install the .deb (this also sets up the apt repo and signing key for auto-updates)
  echo "[VSCode] Installing..."
  apt-get install -y "${DEB_FILE}"

  rm -f "${DEB_FILE}"

  echo "[VSCode] Visual Studio Code installed successfully."
}



install_antigravity() {
  echo "[Antigravity] Installing Antigravity..."

  # Add the repository signing key
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
    gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg

  # Add the repository to sources
  echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
    tee /etc/apt/sources.list.d/antigravity.list > /dev/null

  # Update and install
  apt-get update
  apt-get install -y antigravity

  echo "[Antigravity] Antigravity installed successfully."
}

install_nodejs_npm() {
  sudo -u ${TARGET_USER} -H bash -lc '
    set -euo pipefail

    # Install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    # Load NVM without restarting the shell
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

    # Install Node.js 24 and set it as default
    nvm install 24
    nvm alias default 24

    npm install -g rtlcss
  '
}

install_odoo_community() {

  
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
    cd "${dest}" && sudo ./setup/debinstall.sh
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
install_odoo_community
install_nodejs_npm
install_google_chrome
install_antigravity
install_vscode
install_pycharm_pro
install_rustrover
install_datagrip
install_warp_cli