#!/usr/bin/env bash

# Install dependencies
apt update && apt install -y curl

# Export values (essential to install K3s as agent)
export K3S_URL=https://192.168.56.110:6443
export K3S_TOKEN=$(cat /vagrant_shared/token)
# K3S_TOKEN_FILE: K3s deletes file after reading
# K3S_TOKEN: K3s uses value directly

# Install K3s (as agent) with forced IP configuration
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.111 --flannel-iface=eth1" sh -