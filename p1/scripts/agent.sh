#!/usr/bin/env bash

echo "================================================================"
echo "RUNNING: agent.sh"
echo "Installs K3s as agent on local machine"
echo "================================================================"

echo "[1/4] Installing dependencies"
apt-get update && apt-get install -y curl openssh-client

echo "[2/3] Export essential values for K3s installation as agent"
export K3S_URL=https://192.168.56.110:6443
export K3S_TOKEN=$(ssh  -o UserKnownHostsFile=/dev/null \
                        -o StrictHostKeyChecking=no \
                        -o ConnectTimeout=5 \
                        -i "/home/vagrant/key.txt" \
                        "vagrant@192.168.56.110" \
                        "sudo cat /var/lib/rancher/k3s/server/node-token" 2>/dev/null)
# K3S_TOKEN_FILE: K3s deletes file after reading
# K3S_TOKEN: K3s uses value directly

echo "[3/3] Install K3s as agent"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.111" sh -

echo "================================================================"
echo "COMPLETED: agent.sh"
echo "================================================================"