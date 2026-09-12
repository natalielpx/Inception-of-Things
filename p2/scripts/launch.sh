#!/usr/bin/env bash
set -e

echo "================================================================"
echo "RUNNING: launch.sh"
echo "Deploys web applications (app1, app2, app3) and ingress"
echo "================================================================"

# Constants
CONF_DIR="$PWD/configs"
APPS=(app1 app2 app3)

# Variables
step=1
total_steps=$((${#APPS[@]} + 1))

# Point kubectl to correct credentials/config
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Launch apps
for app in "${APPS[@]}"; do
  echo "[${step}/${total_steps}] Deploying ${app} resources..."
  kubectl apply -f "${CONF_DIR}/${app}.yaml"
  step=$((step + 1))
done

# Create Ingress
echo "[${step}/${total_steps}] Applying ingress..."
kubectl apply -f "${CONF_DIR}/ingress.yaml"

echo "================================================================"
echo "COMPLETED: launch.sh"
echo "================================================================"