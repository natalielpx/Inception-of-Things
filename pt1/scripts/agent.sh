#!/usr/bin/env bash

# Install dependencies
apt update && apt install -y curl

# Wait until token exists and server responds
until curl -k https://192.168.56.110:6443 >/dev/null 2>&1; do
  echo "Waiting for K3s server to be ready..."
  sleep 5
done

# Export values (essential to install K3s as agent)
export K3S_URL=https://192.168.56.110:6443
export K3S_TOKEN_FILE=/vagrant_shared/token

# Install K3s (as agent) with forced IP configuration
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.111 --flannel-iface=eth1" sh -