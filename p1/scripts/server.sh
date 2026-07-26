#!/usr/bin/env bash

echo "================================================================"
echo "RUNNING: server.sh"
echo "Installs K3s as server on local machine"
echo "================================================================"

echo "[1/4] Installing dependencies"
apt-get update && apt-get install -y curl

echo "[2/4] Install K3s as server"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.110" sh -

echo "[3/4] Wait for token to generate"
for i in {1..6};
do
    if [ -f /var/lib/rancher/k3s/server/node-token ]; then
        echo "[4/4] Node token successfully generated"
        break
    fi
    echo "Waiting for node-token to be generated"
    sleep 30
done
if [ ! -f /var/lib/rancher/k3s/server/node-token ]; then
    echo "[4/4]Node token generation failed"
    exit 1
fi

echo "================================================================"
echo "COMPLETED: server.sh"
echo "================================================================"