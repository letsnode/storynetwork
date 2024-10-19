#!/bin/bash

set -euo pipefail

# Function to log messages with timestamp
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to handle errors
die() {
  echo "Error: $1" >&2
  exit 1
}

# Stop Story and Story-Geth services
log "Stopping Story and Story-Geth services..."
systemctl stop story || die "Failed to stop Story service"
systemctl stop story-geth || die "Failed to stop Story-Geth service"

# Backup priv_validator_state.json
log "Backing up priv_validator_state.json..."
cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup || die "Failed to backup priv_validator_state.json"

# Remove existing data directories
log "Removing existing data directories..."
rm -rf $HOME/.story/story/data || die "Failed to remove Story data directory"
rm -rf $HOME/.story/geth/iliad/geth/chaindata || die "Failed to remove Story-Geth chaindata directory"

# Prompt user to select the source for Story and Story-Geth data
echo "Select the source to download Story and Story-Geth data:"
echo "1. Source 1 (Archive, full snapshot)"
echo "2. Source 2 (Pruned)"
read -rp "Enter your choice (1 or 2): " choice

if [[ "$choice" == "1" ]]; then
  log "Downloading and extracting Story data from source 1..."
  curl -o - -L https://share102.utsa.tech/story/story_testnet.tar.lz4 | lz4 -c -d - | tar -x -C $HOME/.story/story/ || die "Failed to download or extract Story data from source 1"
  log "Downloading and extracting Story-Geth data from source 1..."
  curl -o - -L https://share102.utsa.tech/story/story_geth_testnet.tar.lz4 | lz4 -c -d - | tar -x -C $HOME/.story/geth/iliad/geth/ || die "Failed to download or extract Story-Geth data from source 1"
elif [[ "$choice" == "2" ]]; then
  log "Downloading and extracting Story data from source 2..."
  curl -o - -L https://share106-7.utsa.tech/story/story_testnet.tar.lz4 | lz4 -c -d - | tar -x -C $HOME/.story/story/ || die "Failed to download or extract Story data from source 2"
  log "Downloading and extracting Story-Geth data from source 2..."
  curl -o - -L https://share106-7.utsa.tech/story/story_geth_testnet.tar.lz4 | lz4 -c -d - | tar -x -C $HOME/.story/geth/iliad/geth/ || die "Failed to download or extract Story-Geth data from source 2"
else
  die "Invalid choice. Exiting."
fi

# Restore priv_validator_state.json
log "Restoring priv_validator_state.json..."
mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json || die "Failed to restore priv_validator_state.json"

# Restart Story and Story-Geth services
log "Restarting Story and Story-Geth services..."
systemctl restart story || die "Failed to restart Story service"
systemctl restart story-geth || die "Failed to restart Story-Geth service"

log "Script completed successfully."
