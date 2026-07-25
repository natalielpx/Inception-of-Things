#!/usr/bin/env bash

# Install dependencies
apt update && apt install -y curl

# Install K3s (as server) with forced IP configuration
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.110" sh -

# Wait for token to generate
for i in {1..6};
do
    if [ -f /var/lib/rancher/k3s/server/node-token ]; then
        echo "Node token successfully generated"
        break
    fi
    echo "Waiting for node-token to be generated"
    sleep 30
done

if [ ! -f /var/lib/rancher/k3s/server/node-token ]; then
    echo "Node token generation failed"
    exit 1
fi
