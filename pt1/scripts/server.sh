#!/usr/bin/env bash

# Install dependencies
apt update && apt install -y curl

# Install K3s (as server)
curl -sfL https://get.k3s.io | sh -

# Copy K3s token into synced folder
cp /var/lib/rancher/k3s/server/token /vagrant_shared