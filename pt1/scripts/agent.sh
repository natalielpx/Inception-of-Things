#!/usr/bin/env bash

# Install dependencies
apt update && apt install -y curl

# Export values (essential to install K3s as agent)
export K3S_URL=https://192.168.56.110:6443
export K3S_TOKEN_FILE=/vagrant_shared/token

# Wait for token to be created and shared
while ! [ -f /vagrant_shared/token ]
do
	echo "Waiting for token..."
	sleep 5
done

# Install K3s (as agent) with forced IP configuration
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.111 --flannel-iface=eth1" sh -