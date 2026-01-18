#!/bin/bash

set -e

echo "========================================="
echo "Installing K3s on ServerWorker (Agent mode)"
echo "========================================="

# Mise à jour du système
apt-get update
apt-get install -y curl

# Attendre que le token soit disponible
echo "Waiting for server token..."
while [ ! -f /vagrant/scripts/node-token ]; do
  sleep 2
  echo "Still waiting for token..."
done

echo "Token found!"

# Lire le token du serveur
K3S_TOKEN=$(cat /vagrant/scripts/node-token)
K3S_URL="https://192.168.56.110:6443"

# Attendre que le serveur soit accessible
echo "Waiting for K3s server to be ready..."
until curl -k -s $K3S_URL/ping > /dev/null 2>&1; do
  echo "Server not ready yet, waiting..."
  sleep 5
done

echo "Server is ready! Installing K3s agent..."

# Installation de K3s en mode agent
curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN INSTALL_K3S_EXEC="--node-ip=192.168.56.111" sh -

# Attendre que K3s agent soit prêt
echo "Waiting for K3s agent to be ready..."
sleep 10

# Vérifier que K3s agent fonctionne
systemctl status k3s-agent --no-pager

echo ""
echo "========================================="
echo "K3s Agent installation completed!"
echo "========================================="
echo "Node IP: 192.168.56.111"
echo "Connected to: $K3S_URL"
echo ""
echo "To check the cluster, connect to the server:"
echo "  vagrant ssh pcheronS"
echo "  kubectl get nodes"
echo "========================================="