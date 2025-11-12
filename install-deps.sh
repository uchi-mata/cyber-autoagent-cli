#!/usr/bin/env bash
set -euo pipefail

readonly TOOLS_DIR="/tools"
readonly JWT_TOOL_DIR="${TOOLS_DIR}/jwt_tool"
readonly GO_BIN_DIR="/root/go/bin"

# Function to log messages
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Function to update and upgrade system packages
update_system() {
  log "Updating system packages..."
  rm -rf /var/lib/apt/lists/*
  apt-get update
  apt-get full-upgrade -y
}

# Function to install system packages
install_packages() {
  log "Installing security tools and dependencies..."
  local packages=(
    git python3 python3-pip python3-venv nmap nikto sqlmap gobuster
    whatweb wafw00f zaproxy burpsuite cookiecutter nuclei naabu amass
    subfinder ffuf feroxbuster dirb arjun wapiti wfuzz wpscan gospider
    httprobe subjack knockpy assetfinder dnsrecon dnsenum theharvester
    masscan smbclient smbmap nbtscan arp-scan ike-scan onesixtyone
    snmpcheck netdiscover hping3 socat proxychains4 sslscan john
    iproute2 net-tools curl tcpdump ncat netcat-openbsd build-essential
    wget ca-certificates nodejs npm metasploit-framework golang snmpcheck
  )
  
  apt-get install -y "${packages[@]}"
}

# Function to clean up apt
cleanup_apt() {
  log "Cleaning up apt cache..."
  apt-get autoremove -y
  apt-get autopurge -y
  apt-get clean -y
  apt-get autoclean -y
  rm -rf /var/lib/apt/lists/*
}

# Function to create symbolic links
create_symlinks() {
  log "Creating symbolic links..."
  if [[ -x /usr/bin/snmp-check ]]; then
    ln -sf /usr/bin/snmp-check /usr/bin/snmpcheck
  fi
}

# Function to install npm packages
install_npm_packages() {
  log "Installing npm packages..."
  npm install -g @graphql-inspector/cli graphql jwt-decode
}

# Function to create jwt-decode wrapper
create_jwt_decode_wrapper() {
  log "Creating jwt-decode wrapper..."
  cat > /usr/local/bin/jwt-decode << 'EOF'
#!/usr/bin/env node
const jwtDecode = require('/usr/local/lib/node_modules/jwt-decode');
const fs = require('fs');

let token = null;
if (process.argv.length > 2) {
  token = process.argv[2];
} else {
  const stat = fs.fstatSync(0);
  if (stat.size > 0) token = fs.readFileSync(0, 'utf8').trim();
}

if (!token) {
  console.error('Usage: jwt-decode <jwt> OR echo <jwt> | jwt-decode');
  process.exit(1);
}

try {
  const decoded = jwtDecode(token);
  console.log(JSON.stringify(decoded, null, 2));
} catch (err) {
  console.error('Error decoding token:', err.message || err);
  process.exit(2);
}
EOF
  
  chmod +x /usr/local/bin/jwt-decode
}

# Function to setup jwt_tool
setup_jwt_tool() {
  log "Setting up jwt_tool..."
  
  # Create tools directory
  mkdir -p "${JWT_TOOL_DIR}"
  
  # Clone repository if it doesn't exist
  if [[ ! -d "${JWT_TOOL_DIR}/.git" ]]; then
    git clone https://github.com/ticarpi/jwt_tool.git "${JWT_TOOL_DIR}"
  fi
  
  # Create virtual environment
  python3 -m venv "${JWT_TOOL_DIR}"
  
  # Upgrade pip and install dependencies
  "${JWT_TOOL_DIR}/bin/pip" install --upgrade pip setuptools wheel
  
  # Create jwt_tool wrapper
  cat > /usr/local/bin/jwt-tool << 'EOF'
#!/usr/bin/env bash
# Wrapper to run jwt_tool inside its dedicated venv
set -euo pipefail

readonly VENV="/tools/jwt_tool"
readonly REPO="/tools/jwt_tool"

if [[ ! -x "${VENV}/bin/python" ]]; then
  echo "jwt_tool venv not found: ${VENV}" >&2
  exit 1
fi

# Run jwt_tool.py inside the venv
exec "${VENV}/bin/python" "${REPO}/jwt_tool.py" "$@"
EOF
  
  chmod +x /usr/local/bin/jwt-tool
}

# Function to install Go tools
install_go_tools() {
  log "Installing Go tools..."
  
  # Install katana with CGO enabled
  CGO_ENABLED=1 go install github.com/projectdiscovery/katana/cmd/katana@latest
  
  # Create symlink if the binary exists
  if [[ -x "${GO_BIN_DIR}/katana" ]]; then
    ln -sf "${GO_BIN_DIR}/katana" /usr/local/bin/katana
  else
    log "Warning: katana binary not found at ${GO_BIN_DIR}/katana"
  fi
}

# Main function
main() {
  log "Starting security tools installation..."
  
  update_system
  install_packages
  cleanup_apt
  create_symlinks
  install_npm_packages
  create_jwt_decode_wrapper
  setup_jwt_tool
  install_go_tools
  cleanup_apt
  
  log "Installation completed successfully!"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Run main function
main "$@"