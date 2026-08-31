#!/usr/bin/env bash
# install.sh
# This script provisions the Coder control plane on your Kubernetes cluster.

set -e

echo "================================================================"
echo "🚀 Deploying Coder Control Plane on VKS (POC)"
echo "================================================================"

echo "[1/4] Adding the Coder Helm repository..."
# Add the Coder Helm repository as requested
helm repo add coder-v2 https://helm.coder.com/v2
helm repo update

echo "[2/4] Creating the 'coder' namespace..."
# Create the namespace if it doesn't already exist
kubectl create namespace coder --dry-run=client -o yaml | kubectl apply -f -

echo "[3/4] Installing Coder via Helm..."
# Run helm upgrade --install with our values file to setup the LoadBalancer
helm upgrade --install coder coder-v2/coder \
  --namespace coder \
  --values deploy/coder-values.yaml \
  --wait

echo "[4/4] Installation Complete!"
echo "================================================================"
echo "To retrieve the LoadBalancer IP for the Coder Dashboard, run:"
echo "  kubectl get svc coder -n coder"
echo ""
echo "Once provisioned, navigate to http://<LOAD_BALANCER_IP> in your browser to create your initial admin user."
echo "================================================================"
