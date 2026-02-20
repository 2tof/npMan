#!/usr/bin/env bash

SCRIPT_VERSION='0.0.9-Online-Auto-Final'
export DEBIAN_FRONTEND=noninteractive

TEMP_DIR='/tmp/nodepass'
WORK_DIR='/etc/nodepass'

trap "rm -rf $TEMP_DIR >/dev/null 2>&1 ; echo -e '\n' ;exit" INT QUIT TERM EXIT
mkdir -p $TEMP_DIR

# --- 英文文本字典 ---
E[0]="Language setup complete."
E[1]="Doomsday Protocol (Online Auto)"
E[2]="The script must be run as root, you can enter sudo -i and then run again."
E[3]="Unsupported architecture: \$(uname -m)"
E[4]="Please choose: "
E[5]="The script supports Linux systems only."
E[6]="NodePass help menu"
E[7]="Install dependence-list:"
E[8]="Failed to install download tool."
E[9]="Failed to load \$APP"
E[10]="NodePass installed successfully!"
E[11]="NodePass has been uninstalled"
E[12]="The external network of the current machine is single-stack:\\\n 1. \${SERVER_IPV4_DEFAULT}\${SERVER_IPV6_DEFAULT}\(default\)\\\n 2. Do not listen on the public network, only listen locally"
E[13]="Please enter the port (1024-65535, NAT machine must use an open port, press Enter for random port):"
E[14]="Please enter API prefix (lowercase letters, numbers and / only, press Enter for default \"api\"):"
E[15]="Please select TLS mode (press Enter for Self-Signed TLS encryption):"
E[16]="0. None TLS encryption (plain TCP) - Fastest performance, no overhead\n 1. Self-signed certificate (auto-generated) - Fine security with simple setups (default)\n 2. Custom certificate (requires pre-prepared crt and key files) - Highest security with certificate validation"
E[17]="Please enter the correct option"
E[18]="NodePass is already installed, please uninstall it before reinstalling"
E[19]="NodePass downloaded and extracted successfully."
E[20]="Failed to get latest version"
E[21]="Running in container environment, skipping service creation and starting process directly"
E[22]="NodePass Script Usage:\n np - Show menu\n np -i - Install NodePass\n np -u - Uninstall NodePass\n np -o - Toggle service status (start/stop)\n np -k - Change NodePass API key\n np -v - Upgrade NodePass Core\n np -s - Show NodePass API info\n np -h - Show help information"
E[23]="Please enter the path to your TLS certificate file:"
E[24]="Please enter the path to your TLS private key file:"
E[25]="Certificate file does not exist:"
E[26]="Private key file does not exist:"
E[27]="Using custom TLS certificate"
E[28]="Install"
E[29]="Uninstall"
E[30]="Upgrade core"
E[31]="Exit"
E[32]="not installed"
E[33]="stopped"
E[34]="running"
E[35]="NodePass Installation Information:"
E[36]="Port is already in use, please try another one."
E[37]="Using random port:"
E[38]="Please select: "
E[39]="API URL:"
E[40]="API KEY:"
E[41]="Invalid port number, please enter a number between 1024 and 65535."
E[42]="NodePass service has been stopped"
E[43]="NodePass service has been started"
E[44]="Unable to get local version"
E[45]="NodePass Local Core: Stable \$STABLE_LOCAL_VERSION"
E[46]="NodePass Latest Core: Stable \$STABLE_LATEST_VERSION"
E[47]="Current version is already the latest, no need to upgrade"
E[48]="Found new version, upgrade? (y/N)"
E[49]="Upgrade cancelled"
E[50]="Stopping NodePass service..."
E[51]="Starting NodePass service..."
E[52]="NodePass upgrade successful!"
E[53]="Failed to start NodePass service, please check logs"
E[54]="Rolled back to previous version"
E[55]="Rollback failed, please check manually"
E[56]="Stop API"
E[57]="Create shortcuts successfully: script can be run with [ np ] command, and [ nodepass ] binary is directly executable."
E[58]="Start API"
E[59]="NodePass is not installed. Configuration file not found"
E[60]="NodePass API:"
E[61]="PREFIX can only contain lowercase letters, numbers, and slashes (/), please re-enter"
E[62]="Change KEY"
E[63]="API KEY changed successfully!"
E[64]="Failed to change API KEY"
E[65]="Changing NodePass API KEY..."
E[66]="Current running version: Development Version"
E[67]="Current running version: Stable Version"
E[74]="Not a valid IPv4,IPv6 address or domain name"
E[78]="The external network of the current machine is dual-stack:\\\n 1. \${SERVER_IPV4_DEFAULT}，listen all stacks \(default\)\\\n 2. \${SERVER_IPV6_DEFAULT}，listen all stacks\\\n 3. Do not listen on the public network, only listen locally"
E[79]="Please select or enter the domain or IP directly:"
E[85]="Getting machine IP address..."

# --- 输出格式函数 ---
warning() { echo -e "\033[31m\033[01m$*\033[0m"; }
error() { echo -e "\033[31m\033[01m$*\033[0m" && exit 1; }
info() { echo -e "\033[32m\033[01m$*\033[0m"; }
hint() { echo -e "\033[33m\033[01m$*\033[0m"; }
reading() { read -rp "$(info "$1")" "$2"; }
text() { grep -q '\$' <<< "${E[$*]}" && eval echo "\$(eval echo "\${E[$*]}")" || eval echo "\${E[$*]}"; }

help() {
  hint " ${E[22]} "
}

check_root() {
  [ "$(id -u)" != 0 ] && error " $(text 2) "
}

check_system() {
  [ "$(uname -s)" != "Linux" ] && error " $(text 5) "

  check_system_info

  case "$SYSTEM" in
    alpine) PACKAGE_INSTALL='apk add --no-cache'; PACKAGE_UPDATE='apk update -f'; PACKAGE_UNINSTALL='apk del' ;;
    arch) PACKAGE_INSTALL='pacman -S --noconfirm'; PACKAGE_UPDATE='pacman -Syu --noconfirm'; PACKAGE_UNINSTALL='pacman -R --noconfirm' ;;
    debian|ubuntu) PACKAGE_INSTALL='apt-get -y install'; PACKAGE_UPDATE='apt-get update'; PACKAGE_UNINSTALL='apt-get -y autoremove' ;;
    centos|fedora) PACKAGE_INSTALL='yum -y install'; PACKAGE_UPDATE='yum -y update'; PACKAGE_UNINSTALL='yum -y autoremove' ;;
    *) PACKAGE_INSTALL='apt-get -y install'; PACKAGE_UPDATE='apt-get update'; PACKAGE_UNINSTALL='apt-get -y autoremove' ;;
  esac
}

check_install() {
  if [ ! -f "$WORK_DIR/nodepass" ]; then
    return 2
  else
    if [ "$IN_CONTAINER" = 1 ] || [ "$SERVICE_MANAGE" = "none" ]; then
      grep -q '^CMD=.*tls=0' ${WORK_DIR}/data && HTTP_S="http" || HTTP_S="https"
    elif [ "$SERVICE_MANAGE" = "systemctl" ]; then
      grep -q '^ExecStart=.*tls=0' /etc/systemd/system/nodepass.service && HTTP_S="http" || HTTP_S="https"
    fi
  fi

  if [ "$SERVICE_MANAGE" = "systemctl" ] && ! systemctl is-active nodepass &>/dev/null; then
    return 1
  else
    if ps -ef | grep -vE "grep|<defunct>" | grep -q "nodepass"; then
      return 0
    else
      return 1
    fi
  fi
}

check_dependencies() {
  DEPS_INSTALL=()
  for cmd in curl wget tar unzip ps; do
    [ ! -x "$(type -p $cmd)" ] && DEPS_INSTALL+=("$cmd")
  done
  if [ "${#DEPS_INSTALL[@]}" -gt 0 ]; then
    info "\n $(text 7) ${DEPS_INSTALL[@]} \n"
    ${PACKAGE_UPDATE} >/dev/null 2>&1
    ${PACKAGE_INSTALL} ${DEPS_INSTALL[@]} >/dev/null 2>&1
  fi
}

check_system_info() {
  if [ -f /.dockerenv ] || grep -q 'docker\|lxc' /proc/1/cgroup; then IN_CONTAINER=1; else IN_CONTAINER=0; fi
  if [ -x "$(type -p systemctl)" ]; then SERVICE_MANAGE="systemctl"; else SERVICE_MANAGE="none"; fi
  if [ -f /etc/os-release ]; then source /etc/os-release; SYSTEM="${ID}"; elif [ -f /etc/arch-release ]; then SYSTEM="arch"; fi
  case "$(uname -m)" in
    x86_64 | amd64 ) ARCH=amd64 ;;
    armv8 | arm64 | aarch64 ) ARCH=arm64 ;;
    armv7l ) ARCH=arm ;;
    s390x ) ARCH=s390x ;;
    * ) error " $(text 3) " ;;
  esac
}

validate_ip_address() {
  local IP="$1"
  local IPV4_REGEX='^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
  local IPV6_REGEX='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$'
  local DOMAIN_REGEX='^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'
  [ "$IP" = "localhost" ] && IP="127.0.0.1"
  if [[ "$IP" =~ $IPV4_REGEX ]] || [[ "$IP" =~ $IPV6_REGEX ]] || [[ "$IP" =~ $DOMAIN_REGEX ]]; then
    return 0
  else
    warning " $(text 74) "
    return 1
  fi
}

check_port() {
  local PORT=$1
  if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1024 ] || [ "$PORT" -gt 65535 ]; then return 2; fi
  if [ $(type -p ss) ]; then ss -nltup 2>/dev/null | grep -q ":$PORT " && return 1; fi
  return 0
}

get_api_url() {
  [ -s "$WORK_DIR/data" ] && source "$WORK_DIR/data"
  if [ -s "$WORK_DIR/gob/nodepass.gob" ]; then
    local CMD_LINE=$(sed -n 's/.*ExecStart=.*\(master.*\)"/\1/p' "/etc/systemd/system/nodepass.service" 2>/dev/null)
    if [ -n "$CMD_LINE" ]; then
      [[ "$CMD_LINE" =~ master://.*:([0-9]+)/([^?]+)\?(log=[^&]+&)?tls=([0-2]) ]]
      PORT="${BASH_REMATCH[1]}"
      PREFIX="${BASH_REMATCH[2]}"
      TLS_MODE="${BASH_REMATCH[4]}"
      grep -qw '0' <<< "$TLS_MODE" && local HTTP_S="http" || local HTTP_S="https"
    fi
    local URL_SERVER_PORT=$(sed -n 's#.*:\([0-9]\+\)\/.*#\1#p' <<< "$CMD_LINE")
    
    grep -q ':' <<< "$SERVER_IP" && local URL_SERVER_IP="[$SERVER_IP]" || local URL_SERVER_IP="$SERVER_IP"
    API_URL="${HTTP_S}://${URL_SERVER_IP}:${URL_SERVER_PORT}/${PREFIX:+${PREFIX%/}/}v1"
    
    local LOCAL_IPV6=$(ip -6 addr show scope global | grep inet6 | awk '{print $2}' | cut -d/ -f1 | head -n 1)
    if [ -n "$LOCAL_IPV6" ]; then
      API_URL_V6="${HTTP_S}://[${LOCAL_IPV6}]:${URL_SERVER_PORT}/${PREFIX:+${PREFIX%/}/}v1"
    else
      API_URL_V6=""
    fi

    if grep -q 'output' <<< "$1"; then
      info " $(text 39) (v4): $API_URL"
      [ -n "$API_URL_V6" ] && info " $(text 39) (v6): $API_URL_V6"
    fi
  else
    warning " $(text 59) "
  fi
}

get_api_key() {
  if [ -s "$WORK_DIR/gob/nodepass.gob" ]; then
    KEY=$(grep -a -o '[0-9a-f]\{32\}' $WORK_DIR/gob/nodepass.gob | head -n 1)
    grep -q 'output' <<< "$1" && info " $(text 40) $KEY"
  else
    warning " $(text 59) "
  fi
}

get_random_port() {
  local RANDOM_PORT
  while true; do
    RANDOM_PORT=$((RANDOM % 7168 + 1024))
    check_port "$RANDOM_PORT" "check_used" && break
  done
  echo "$RANDOM_PORT"
}

get_local_version() {
  if [ -f "$WORK_DIR/nodepass" ]; then
    STABLE_LOCAL_VERSION=$($WORK_DIR/nodepass -v 2>&1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
  fi
  [ -z "$STABLE_LOCAL_VERSION" ] && STABLE_LOCAL_VERSION="Unknown"
  VERSION_TYPE_TEXT=$(text 67)
}

get_latest_version() {
  STABLE_LATEST_VERSION=$(curl -s https://api.github.com/repos/NodePassProject/nodepass/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)
  [ -z "$STABLE_LATEST_VERSION" ] && STABLE_LATEST_VERSION="Unknown"
}

on_off() {
  if systemctl is-active nodepass >/dev/null 2>&1; then stop_nodepass; info " $(text 42) "; else start_nodepass; info " $(text 43) "; fi
}
start_nodepass() { info " $(text 51) "; systemctl start nodepass; sleep 2; }
stop_nodepass() { info " $(text 50) "; systemctl stop nodepass; sleep 2; }

download_core() {
  info "Fetching latest NodePass release from GitHub..."
  local API_RESP=$(curl -s https://api.github.com/repos/NodePassProject/nodepass/releases/latest)
  local DOWNLOAD_URL=$(echo "$API_RESP" | grep '"browser_download_url":' | grep -i "linux" | grep -i "$ARCH" | grep -v -i "sha256" | grep -v -i "md5" | cut -d '"' -f 4 | head -n 1)
  [ -z "$DOWNLOAD_URL" ] && error "Could not find a valid download URL for architecture: linux-$ARCH on Github."

  info "Downloading from: $DOWNLOAD_URL"
  local FILE_NAME=$(basename "$DOWNLOAD_URL")
  wget -qO "$TEMP_DIR/$FILE_NAME" "$DOWNLOAD_URL" || error "Download failed!"

  mkdir -p "$TEMP_DIR/extract"
  if [[ "$FILE_NAME" == *.tar.gz ]]; then tar -xzf "$TEMP_DIR/$FILE_NAME" -C "$TEMP_DIR/extract/"; elif [[ "$FILE_NAME" == *.zip ]]; then unzip -q -o "$TEMP_DIR/$FILE_NAME" -d "$TEMP_DIR/extract/"; else cp "$TEMP_DIR/$FILE_NAME" "$TEMP_DIR/extract/nodepass"; fi

  local BIN_FILE=$(find "$TEMP_DIR/extract" -type f | grep -i "nodepass" | head -n 1)
  [ -z "$BIN_FILE" ] && BIN_FILE=$(find "$TEMP_DIR/extract" -type f | head -n 1)
  [ -z "$BIN_FILE" ] && error "Failed to locate the binary file after extraction."

  mv "$BIN_FILE" "$TEMP_DIR/nodepass" && chmod +x "$TEMP_DIR/nodepass"
  echo -e '#!/bin/bash\necho "QR Code unavailable"' > "$TEMP_DIR/qrencode"
}

upgrade_nodepass() {
  get_latest_version; get_local_version
  info "$(text 45)"; info "$(text 46)"
  if [ "$STABLE_LOCAL_VERSION" != "Unknown" ] && [ "$STABLE_LOCAL_VERSION" == "$STABLE_LATEST_VERSION" ]; then info " $(text 47) "; return 0; fi

  reading " $(text 48) " CONFIRM
  if [[ "$CONFIRM" =~ ^[yY]$ ]]; then
    download_core; stop_nodepass
    cp "$TEMP_DIR/nodepass" "$WORK_DIR/np-stb"
    ln -sf "$WORK_DIR/np-stb" "$WORK_DIR/nodepass"
    start_nodepass; info " $(text 52) "
  else
    info " $(text 49) "
  fi
}

parse_args() {
  unset ARGS_PORT ARGS_PREFIX ARGS_TLS_MODE ARGS_LANGUAGE
  while [[ $# -gt 0 ]]; do shift; done
}

install() {
  handle_ip_input() {
    local IP="$1"
    unset SERVER_INPUT
    IP=$(sed 's/[][]//g' <<< "$IP")
    if [[ "$IP" = "localhost" || "$IP" = "127.0.0.1" || "$IP" = "::1" ]]; then
      SERVER_INPUT="127.0.0.1"
    else
      case "$IP" in
        1|"") SERVER_INPUT="${SERVER_IPV4_DEFAULT:-$SERVER_IPV6_DEFAULT}" ;;
        2) 
          if [ "$IS_DUAL_STACK" = 1 ]; then SERVER_INPUT="${SERVER_IPV6_DEFAULT}"; else SERVER_INPUT="127.0.0.1"; fi ;;
        3) SERVER_INPUT="127.0.0.1" ;;
        *) SERVER_INPUT="$IP" ;;
      esac
    fi
  }

  download_core
  info " $(text 19) "
  hint "\n $(text 85) "
  
  local DEFAULT_LOCAL_IP4=$(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -n 1)
  local DEFAULT_LOCAL_IP6=$(ip -6 addr show scope global | grep inet6 | awk '{print $2}' | cut -d/ -f1 | head -n 1)
  
  SERVER_IPV4_DEFAULT=$DEFAULT_LOCAL_IP4
  SERVER_IPV6_DEFAULT=$DEFAULT_LOCAL_IP6

  if [ -n "$SERVER_IPV4_DEFAULT" ] && [ -n "$SERVER_IPV6_DEFAULT" ]; then
    IS_DUAL_STACK=1
    hint "\n (2/5) $(text 78) "
  else
    IS_DUAL_STACK=0
    hint "\n (2/5) $(text 12) "
  fi

  reading "\n $(text 79) " SERVER_INPUT
  handle_ip_input "$SERVER_INPUT"
  
  while ! validate_ip_address "$SERVER_INPUT"; do
    hint "\n $(text 12) " && reading "\n $(text 79) " SERVER_INPUT
    handle_ip_input "$SERVER_INPUT"
  done

  while true; do
    reading "\n (3/5) $(text 13) " PORT
    if [ -z "$PORT" ]; then PORT=$(get_random_port); info " $(text 37) $PORT"; break; else
      check_port "$PORT" "check_used"
      local PORT_STATUS=$?
      if [ "$PORT_STATUS" = 2 ]; then warning " $(text 41) "; elif [ "$PORT_STATUS" = 1 ]; then warning " $(text 36) "; else break; fi
    fi
  done

  if [[ "$SERVER_INPUT" =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]]; then
    CMD_SERVER_IP="$SERVER_INPUT"
    SERVER_IP="$SERVER_INPUT"
  else
    if [[ "$SERVER_INPUT" == "127.0.0.1" || "$SERVER_INPUT" == "localhost" ]]; then
      CMD_SERVER_IP="127.0.0.1"
    else
      CMD_SERVER_IP="" 
    fi
    SERVER_IP="$SERVER_INPUT"
  fi
  URL_SERVER_PORT="$PORT"

  while true; do
    reading "\n (4/5) $(text 14) " PREFIX
    [ -z "$PREFIX" ] && PREFIX="api" && break
    if grep -q '^[a-z0-9/]*$' <<< "$PREFIX"; then PREFIX=$(sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s#^/##;s#/$##' <<< "$PREFIX"); break; else warning " $(text 61) "; fi
  done

  hint "\n (5/5) $(text 15) "
  hint " $(text 16) "
  reading "\n $(text 38) " TLS_MODE
  if [ -z "$TLS_MODE" ]; then TLS_MODE=1; info "Using default: Self-signed certificate"; elif [[ ! "$TLS_MODE" =~ ^[0-2]$ ]]; then warning " $(text 17) "; exit 1; fi

  CMD="master://${CMD_SERVER_IP}:${PORT}/${PREFIX}?tls=${TLS_MODE}${CRT_PATH:-}"
  mkdir -p $WORK_DIR
  echo -e "LANGUAGE=E\nSERVER_IP=$SERVER_IP" > $WORK_DIR/data

  mv $TEMP_DIR/nodepass $WORK_DIR/np-stb
  mv $TEMP_DIR/qrencode $WORK_DIR/
  chmod +x $WORK_DIR/{np-stb,qrencode}
  ln -sf "$WORK_DIR/np-stb" "$WORK_DIR/nodepass"

  create_service
  sleep 3
  check_install
  local INSTALL_STATUS=$?

  if [ $INSTALL_STATUS -eq 0 ]; then
    create_shortcut
    info "\n $(text 10) "
    echo "------------------------"
    info " $(text 60) $(text 34) "
    info " $(text 35) "
    get_api_url output
    get_api_key output
    echo "------------------------"
  else
    warning " $(text 53) "
  fi
  help
}

create_service() {
  cat > /etc/systemd/system/nodepass.service << EOF
[Unit]
Description=NodePass Service
Documentation=https://github.com/NodePassProject/nodepass
After=network.target
[Service]
Type=simple
ExecStart=$WORK_DIR/nodepass "$CMD"
Restart=on-failure
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload; systemctl enable nodepass; systemctl start nodepass
}

create_shortcut() {
  local CURRENT_SCRIPT="$(readlink -f "$0")"
  cp "$CURRENT_SCRIPT" "${WORK_DIR}/np.sh"
  chmod +x "${WORK_DIR}/np.sh"
  ln -sf "${WORK_DIR}/np.sh" /usr/bin/np
  ln -sf "${WORK_DIR}/nodepass" /usr/bin/nodepass
  [ -s /usr/bin/np ] && info "\n $(text 57) "
}

uninstall() {
  systemctl stop nodepass; systemctl disable nodepass; rm -f /etc/systemd/system/nodepass.service; systemctl daemon-reload
  rm -rf "$WORK_DIR" /usr/bin/{np,nodepass}
  info " $(text 11) "
}

change_api_key() {
  local INSTALL_STATUS=$1; info " $(text 65) "
  if [ "$INSTALL_STATUS" = 1 ]; then start_nodepass; local NEED_STOP=1; sleep 2; fi
  [[ -z "$PORT" || -z "$PREFIX" ]] && get_api_url
  [ -z "$KEY" ] && get_api_key
  [[ -z "$PORT" || -z "$PREFIX" || -z "$KEY" ]] && error " $(text 64) "

  local RESPONSE=$(curl -ks -X 'PATCH' "${HTTP_S}://127.0.0.1:${PORT}/${PREFIX}/v1/instances/********" -H "accept: application/json" -H "X-API-Key: ${KEY}" -H "Content-Type: application/json" -d '{"action": "restart"}')
  local NEW_KEY=$(sed 's/.*url":"\([^"]\+\)".*/\1/' <<< "$RESPONSE")

  if [ "${#NEW_KEY}" = 32 ]; then
    info " $(text 63) "; get_api_url output; info " $(text 40) $NEW_KEY"; [ "$NEED_STOP" = 1 ] && stop_nodepass; return 0
  else
    warning " $(text 64) "; [ "$NEED_STOP" = 1 ] && stop_nodepass; return 1
  fi
}

menu_setting() {
  INSTALL_STATUS=$1
  unset OPTION ACTION
  get_latest_version

  if [ "$INSTALL_STATUS" = 2 ]; then
    NODEPASS_STATUS=$(text 32)
    OPTION[1]="1. $(text 28)"; OPTION[0]="0. $(text 31)"
    ACTION[1]() { install; exit 0; }; ACTION[0]() { exit 0; }
  else
    get_api_key; get_api_url; get_local_version all

    if [ $INSTALL_STATUS -eq 0 ]; then
      NODEPASS_STATUS=$(text 34); OPTION[1]="1. $(text 56) (np -o)"
    else
      NODEPASS_STATUS=$(text 33); OPTION[1]="1. $(text 58) (np -o)"
    fi

    OPTION[2]="2. $(text 62) (np -k)"
    OPTION[3]="3. $(text 30) (np -v)"
    OPTION[4]="4. $(text 29) (np -u)"
    OPTION[0]="0. $(text 31)"

    ACTION[1]() { on_off $INSTALL_STATUS; exit 0; }
    ACTION[2]() { change_api_key $INSTALL_STATUS; exit 0; }
    ACTION[3]() { upgrade_nodepass; exit 0; }
    ACTION[4]() { uninstall; exit 0; }
    ACTION[0]() { exit 0; }
  fi
}

menu() {
  echo -e "\033[H\033[2J\033[3J"
  echo "
╭───────────────────────────────────────────╮
│    ░░█▀█░█▀█░░▀█░█▀▀░█▀█░█▀█░█▀▀░█▀▀░░    │
│    ░░█░█░█░█░█▀█░█▀▀░█▀▀░█▀█░▀▀█░▀▀█░░    │
│    ░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀░░    │
├───────────────────────────────────────────┤
│    >Universal TCP/UDP Tunneling Solution  │
╰───────────────────────────────────────────╯ "

  info " $VERSION_TYPE_TEXT"
  grep -qEw '0|1' <<< "$INSTALL_STATUS" && info " $(text 60) $NODEPASS_STATUS "
  
  grep -q '.' <<< "$API_URL" && info " $(text 39) (v4): $API_URL"
  grep -q '.' <<< "$API_URL_V6" && info " $(text 39) (v6): $API_URL_V6"
  grep -q '.' <<< "$KEY" && info " $(text 40) $KEY"
  
  info " Version: $SCRIPT_VERSION"
  echo "------------------------"

  for ((b=1;b<=${#OPTION[*]};b++)); do [ "$b" = "${#OPTION[*]}" ] && hint " ${OPTION[0]} " || hint " ${OPTION[b]} "; done
  echo "------------------------"

  reading " $(text 38) " MENU_CHOICE

  if grep -qE "^[0-9]+$" <<< "$MENU_CHOICE" && [ "$MENU_CHOICE" -ge 0 ] && [ "$MENU_CHOICE" -lt ${#OPTION[@]} ]; then
    ACTION[$MENU_CHOICE]
  else
    warning " $(text 17) [0-$((${#OPTION[@]}-1))] " && sleep 1 && menu
  fi
}

main() {
  parse_args "$@"
  OPTION="${1,,}"
  [ "${1,,}" = "-h" ] && help && exit 0

  check_root; check_system; check_dependencies
  check_install; local INSTALL_STATUS=$?

  case "$1" in
    -i) if [ "$INSTALL_STATUS" != 2 ]; then warning " ${E[18]} "; else install; fi ;;
    -u) [ "$INSTALL_STATUS" = 2 ] && warning " ${E[59]} " || uninstall ;;
    -v) [ "$INSTALL_STATUS" = 2 ] && warning " ${E[59]} " || upgrade_nodepass ;;
    -o) [ "$INSTALL_STATUS" = 2 ] && warning " ${E[59]} " || on_off $INSTALL_STATUS ;;
    -s)
      if [ "$INSTALL_STATUS" = 2 ]; then warning " ${E[59]} "; else
        [ "$INSTALL_STATUS" = 0 ] && info " $(text 60) $(text 34) " || info " $(text 60) $(text 33) "
        get_api_url output; get_api_key output
      fi
      ;;
    -k) [ "$INSTALL_STATUS" = 2 ] && warning " ${E[59]} " || change_api_key $INSTALL_STATUS ;;
    *) menu_setting $INSTALL_STATUS; menu ;;
  esac
}

main "$@"
