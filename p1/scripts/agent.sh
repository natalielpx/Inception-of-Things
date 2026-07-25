#!/usr/bin/env bash

# Install dependencies
apt update && apt install -y curl openssh-client

# Export values (essential to install K3s as agent)
export K3S_URL=https://192.168.56.110:6443
export K3S_TOKEN=$(ssh  -o StrictHostKeyChecking=no \
                        -o ConnectTimeout=5 \
                        -i "/home/vagrant/key.txt" \
                        "vagrant@192.168.56.110" \
                        "sudo cat /var/lib/rancher/k3s/server/node-token" 2>/dev/null)
# K3S_TOKEN_FILE: K3s deletes file after reading
# K3S_TOKEN: K3s uses value directly

echo $K3S_URL
echo $K3S_TOKEN

# Install K3s (as agent) with forced IP configuration
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.111" sh -
