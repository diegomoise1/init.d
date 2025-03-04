#!/usr/bin/env bash
###
# File: install-ryujinx.sh
# Project: scripts
# File Created: Friday, 1st September 2023 3:57:42 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 17th September 2023 4:26:27 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install Ryujinx during container startup.
#   This will also configure Ryujinx with some default options for Steam Headless.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "./scripts/install-ryujinx.sh" "${USER_HOME:?}/init.d/install-ryujinx.sh"
#
###

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user


# Config
package_name="Ryujinx"
package_description="Nintendo Switch Emulator"
package_icon_url="https://upload.wikimedia.org/wikipedia/commons/0/07/Ryujinx_Logo.png"
package_executable="${USER_HOME:?}/.local/bin/${package_name}"
package_category="Game"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget --header="Accept: application/vnd.github+json" -O - -o /dev/null https://api.github.com/repos/Ryubing/Ryujinx/releases/latest)
__latest_package_version=$(echo ${__registry_package_json:?} | jq -r '.tag_name')
__latest_package_id=$(echo "${__registry_package_json:?}" | jq -r '.assets[] | select(.name | endswith("-linux_x64.tar.gz") and startswith("ryujinx-")) | .id' | head -n 1)
__latest_package_url=$(echo "${__registry_package_json:?}" | jq -r '.assets[] | select(.name | endswith("-linux_x64.tar.gz") and startswith("ryujinx-")) | .browser_download_url' | head -n 1)
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"
__installed_version=$(catalog -g ${package_name,,})



# Only install if the latest version does not already exist locally
if ([ ! -f "${package_executable:?}" ] || [ "${__installed_version:-X}" != "${__latest_package_version:?}" ]); then
    __install_dir="${USER_HOME:?}/.local/share/${package_name,,}"
    # Download and extract package to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    mkdir -p "${__install_dir:?}"
    wget -O "${__install_dir:?}/${package_name,,}-${__latest_package_version:?}-linux_x64.tar.gz" \
        --quiet -o /dev/null \
        --no-verbose --show-progress \
        --progress=bar:force:noscroll \
        "${__latest_package_url:?}"

    # Install package
    print_step_header "Installing ${package_name:?} version ${__latest_package_version:?}"
    pushd "${__install_dir:?}" &> /dev/null || { echo "Error: Failed to push directory to ${__install_dir:?}"; exit 1; }
    tar -xf "${__install_dir:?}/${package_name,,}-${__latest_package_version:?}-linux_x64.tar.gz"
    mkdir -p "${USER_HOME:?}/.local/bin"
    ln -snf "${__install_dir:?}/publish/Ryujinx.sh" "${package_executable:?}"
    popd &> /dev/null || { echo "Error: Failed to pop directory out of ${__install_dir:?}"; exit 1; }

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu shortcut is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    catalog -s ${package_name,,} ${__latest_package_version:?}
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi


# Generate Ryujinx Emulation directory structure
__emulation_path="/mnt/games/Emulation"
mkdir -p \
    "${USER_HOME:?}"/.config/Ryujinx \
    "${__emulation_path:?}/bios/ryujinx" \
    "${__emulation_path:?}/storage/ryujinx"/{bis,profiles,sdcard,system}

# Create relative symlinks from the BIOS paths to Ryujinx storage
ensure_symlink "../../storage/ryujinx/system" "${__emulation_path:?}/bios/ryujinx/keys"
if [ ! -f "${__emulation_path:?}/storage/ryujinx/system/putkeyshere.txt" ]; then
    echo "Place both 'title.keys' and 'prod.keys' files here." > "${__emulation_path:?}/storage/ryujinx/system/putkeyshere.txt"
fi

# Create absolute symlinks from the ~/.config/Ryujinx/ directories to our storage path
ensure_symlink "${__emulation_path:?}/storage/ryujinx/bis" "${USER_HOME:?}/.config/Ryujinx/bis"
ensure_symlink "${__emulation_path:?}/storage/ryujinx/profiles" "${USER_HOME:?}/.config/Ryujinx/profiles"
ensure_symlink "${__emulation_path:?}/storage/ryujinx/sdcard" "${USER_HOME:?}/.config/Ryujinx/sdcard"
ensure_symlink "${__emulation_path:?}/storage/ryujinx/system" "${USER_HOME:?}/.config/Ryujinx/system"

# Install default Ryujinx config
if [ ! -f "${USER_HOME:?}/.config/Ryujinx/Config.json" ]; then
    cat << EOF > "${USER_HOME:?}/.config/Ryujinx/Config.json"
{
  "version": 48,
  "enable_file_log": true,
  "backend_threading": "Auto",
  "res_scale": 1,
  "res_scale_custom": 1,
  "max_anisotropy": -1,
  "aspect_ratio": "Fixed16x9",
  "anti_aliasing": "None",
  "scaling_filter": "Bilinear",
  "scaling_filter_level": 80,
  "graphics_shaders_dump_path": "",
  "logging_enable_debug": false,
  "logging_enable_stub": true,
  "logging_enable_info": true,
  "logging_enable_warn": true,
  "logging_enable_error": true,
  "logging_enable_trace": false,
  "logging_enable_guest": true,
  "logging_enable_fs_access_log": false,
  "logging_filtered_classes": [],
  "logging_graphics_debug_level": "None",
  "system_language": "AmericanEnglish",
  "system_region": "USA",
  "system_time_zone": "UTC",
  "system_time_offset": 0,
  "docked_mode": true,
  "enable_discord_integration": false,
  "check_updates_on_start": false,
  "show_confirm_exit": false,
  "hide_cursor": 2,
  "enable_vsync": true,
  "enable_shader_cache": true,
  "enable_texture_recompression": false,
  "enable_macro_hle": true,
  "enable_color_space_passthrough": false,
  "enable_ptc": true,
  "enable_internet_access": false,
  "enable_fs_integrity_checks": true,
  "fs_global_access_log_mode": 0,
  "audio_backend": "SDL2",
  "audio_volume": 1,
  "memory_manager_mode": "HostMappedUnsafe",
  "expand_ram": false,
  "ignore_missing_services": false,
  "gui_columns": {
    "fav_column": true,
    "icon_column": true,
    "app_column": true,
    "dev_column": true,
    "version_column": true,
    "time_played_column": true,
    "last_played_column": true,
    "file_ext_column": true,
    "file_size_column": true,
    "path_column": true
  },
  "column_sort": {
    "sort_column_id": 0,
    "sort_ascending": false
  },
  "game_dirs": [
    "/mnt/games/Emulation/roms/switch"
  ],
  "shown_file_types": {
    "nsp": true,
    "pfs0": true,
    "xci": true,
    "nca": true,
    "nro": true,
    "nso": true
  },
  "window_startup": {
    "window_size_width": 1280,
    "window_size_height": 760,
    "window_position_x": 0,
    "window_position_y": 27,
    "window_maximized": false
  },
  "language_code": "en_US",
  "enable_custom_theme": false,
  "custom_theme_path": "",
  "base_style": "Dark",
  "game_list_view_mode": 0,
  "show_names": true,
  "grid_size": 2,
  "application_sort": 0,
  "is_ascending_order": true,
  "start_fullscreen": false,
  "show_console": true,
  "enable_keyboard": false,
  "enable_mouse": false,
  "hotkeys": {
    "toggle_vsync": "F1",
    "screenshot": "F8",
    "show_ui": "F4",
    "pause": "F5",
    "toggle_mute": "F2",
    "res_scale_up": "Unbound",
    "res_scale_down": "Unbound",
    "volume_up": "Unbound",
    "volume_down": "Unbound"
  },
  "keyboard_config": [],
  "controller_config": [],
  "input_config": [
    {
      "left_joycon_stick": {
        "joystick": "Left",
        "invert_stick_x": false,
        "invert_stick_y": false,
        "rotate90_cw": false,
        "stick_button": "LeftStick"
      },
      "right_joycon_stick": {
        "joystick": "Right",
        "invert_stick_x": false,
        "invert_stick_y": false,
        "rotate90_cw": false,
        "stick_button": "RightStick"
      },
      "deadzone_left": 0.1,
      "deadzone_right": 0.1,
      "range_left": 1,
      "range_right": 1,
      "trigger_threshold": 0.5,
      "motion": {
        "motion_backend": "GamepadDriver",
        "sensitivity": 100,
        "gyro_deadzone": 1,
        "enable_motion": true
      },
      "rumble": {
        "strong_rumble": 1,
        "weak_rumble": 1,
        "enable_rumble": false
      },
      "left_joycon": {
        "button_minus": "Minus",
        "button_l": "LeftShoulder",
        "button_zl": "LeftTrigger",
        "button_sl": "Unbound",
        "button_sr": "Unbound",
        "dpad_up": "DpadUp",
        "dpad_down": "DpadDown",
        "dpad_left": "DpadLeft",
        "dpad_right": "DpadRight"
      },
      "right_joycon": {
        "button_plus": "Plus",
        "button_r": "RightShoulder",
        "button_zr": "RightTrigger",
        "button_sl": "Unbound",
        "button_sr": "Unbound",
        "button_x": "X",
        "button_b": "B",
        "button_y": "Y",
        "button_a": "A"
      },
      "version": 1,
      "backend": "GamepadSDL2",
      "id": "0-f0030003-045e-0000-8e02-000010010000",
      "controller_type": "ProController",
      "player_index": "Player1"
    }
  ],
  "graphics_backend": "OpenGl",
  "preferred_gpu": "",
  "multiplayer_lan_interface_id": "0",
  "use_hypervisor": true
}
EOF
fi

# Configure EmulationStation DE
mkdir -p "${__emulation_path:?}/roms/switch"
cat << 'EOF' > "${__emulation_path:?}/roms/switch/systeminfo.txt"
System name:
switch

Full system name:
Nintendo Switch

Supported file extensions:
.nca .NCA .nro .NRO .nso .NSO .nsp .NSP .xci .XCI .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_YUZU% -f -g %ROM%

Alternative launch command:
%EMULATOR_RYUJINX% %ROM%

Platform (for scraping):
switch

Theme folder:
switch
EOF
if ! grep -ri "switch:" "${__emulation_path:?}/roms/systems.txt" &>/dev/null; then
    print_step_header "Adding 'switch' path to '${__emulation_path:?}/roms/systems.txt'"
    echo "switch: " >> "${__emulation_path:?}/roms/systems.txt"
fi
sed -i 's|^switch:.*$|switch: Nintendo Switch|' "${__emulation_path:?}/roms/systems.txt"

echo "DONE"
