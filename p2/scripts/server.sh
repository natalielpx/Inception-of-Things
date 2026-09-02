#!/usr/bin/env bash
set -e

echo "================================================================"
echo "RUNNING: server.sh"
echo "Installs K3s as server on local machine"
echo "================================================================"

# Install dependencies
echo "[1/2] Installing dependencies"
apt-get update && apt-get install -y curl

# Install K3s (as server) with forced IP configuration
echo "[2/2] Installing K3s as server"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --flannel-iface=eth1" sh -

echo "================================================================"
echo "COMPLETED: server.sh"
echo "================================================================"
