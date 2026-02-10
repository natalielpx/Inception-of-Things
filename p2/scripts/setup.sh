#!/usr/bin/env bash
set -e

echo "================================================================"
echo "RUNNING: setup.sh"
echo "Sets up Kubernetes client environment for vagrant user"
echo "================================================================"

# Variables
user=vagrant
home=/home/$user
bashrc=$home/.bashrc
kube_dir=$home/.kube
conf_file=$kube_dir/config

# Create .kube directory
echo "[1/5] Creating $kube_dir directory"
mkdir -p $kube_dir

# Copy K3s config file
echo "[2/5] Copying K3s config file into $kube_dir"
cp /etc/rancher/k3s/k3s.yaml $conf_file

# Change ownership to user
echo "[3/5] Changing ownership to $user"
chown $user:$user $conf_file

# Set proper permissions
echo "[4/5] Setting proper permissions"
chmod 600 $conf_file

# Add KUBECONFIG export to .bashrc if not present
echo "[5/5] Ensure KUBECONFIG is set in .bashrc"
if ! grep -q "KUBECONFIG" $bashrc; then
  echo "export KUBECONFIG=$conf_file" >> $bashrc
fi
# Use `source .bashrc` to execute export in server machine

echo "================================================================"
echo "COMPLETED: setup.sh"
echo "================================================================"