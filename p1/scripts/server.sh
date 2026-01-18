#!/bin/bash

set -e

LOGIN=$1

echo "========================================="
echo "Installing K3s on ${LOGIN}S (Server mode)"
echo "========================================="

# Mise à jour du système
apt-get update
apt-get install -y curl

# Installation de K3s en mode serveur
# --write-kubeconfig-mode 644 : permet à tous les utilisateurs d'utiliser kubectl
# --node-ip : spécifie l'IP du nœud
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --node-ip=192.168.56.110" sh -

# Attendre que K3s soit prêt
echo "Waiting for K3s to be ready..."
sleep 10

# Vérifier que K3s fonctionne
systemctl status k3s --no-pager

# Copier le token pour le worker
echo "Saving K3s token for worker..."
cp /var/lib/rancher/k3s/server/node-token /vagrant/scripts/node-token
chmod 644 /vagrant/scripts/node-token

# Configuration kubectl pour l'utilisateur vagrant
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Alias pour kubectl
echo "alias k='kubectl'" >> /home/vagrant/.bashrc
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/vagrant/.bashrc

echo ""
echo "========================================="
echo "K3s Server installation completed!"
echo "========================================="
echo "Node IP: 192.168.56.110"
echo "Node name: ${LOGIN}S"
echo ""
echo "To check the cluster:"
echo "  vagrant ssh ${LOGIN}S"
echo "  kubectl get nodes"
echo "========================================="