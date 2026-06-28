#!/usr/bin/env bash

# Install dependencies
apk update && apk upgrade && apt add curl

# Install K3s (as server) with forced IP configuration
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --flannel-iface=eth1" sh -

# Copy the generated token into the shared folder for the agent
cp /var/lib/rancher/k3s/server/node-token /vagrant_shared/token
chmod 644 /vagrant_shared/token