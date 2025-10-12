#!/usr/bin/env bash

# Install dependencies
apt update && apt install -y curl

# Export values (essential to install K3s as agent)
export K3S_TOKEN_FILE=/vagrant_shared/token
export K3S_URL=https://192.168.56.110:6443

# Install K3s (as agent)
curl -sfL https://get.k3s.io | sh -