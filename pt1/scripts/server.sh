#!/usr/bin/env bash

# Install dependencies
apt update && apt install -y curl

# Install K3s (as server)
curl -sfL https://get.k3s.io | sh -

# Wait a few seconds to ensure K3s is fully initialised
sleep 10

# Copy the generated token into the shared folder for the agent
cp /var/lib/rancher/k3s/server/node-token /vagrant_shared/token
chmod 644 /vagrant_shared/token