#!/bin/bash
set -euo pipefail

# Install Cyber-AutoAgent
main() {
  local repo_url="https://github.com/westonbrown/Cyber-AutoAgent.git"
  local repo_dir="Cyber-AutoAgent"
  
  # Clone repository
  if [[ -d "$repo_dir" ]]; then
    echo "Directory $repo_dir already exists. Removing..."
    rm -rf "$repo_dir"
  fi
  
  git clone "$repo_url"
  cd "$repo_dir"
  
  # Create virtual environment
  python3 -m venv venv
  
  # Activate virtual environment and install package
  # shellcheck source=/dev/null
  source venv/bin/activate
  
  # Upgrade pip first (best practice)
  python -m pip install --upgrade pip
  
  # Install package in editable mode
  pip install -e .
  
  echo "Installation completed successfully"
}

main "$@"
