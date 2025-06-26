#!/bin/bash

# Exit on any error
set -e

# --- Configuration ---
# You can change these values
ARGO_CD_NAMESPACE="argo-cd"


# --- 1. Install k3s ---
echo "Installing k3s..."
curl -sfL https://get.k3s.io | sh -

# Wait for the cluster to be ready
echo "Waiting for k3s cluster to be ready..."
sudo k3s kubectl get nodes

# --- 2. Install Argo CD ---
echo "Installing Argo CD..."
sudo k3s kubectl create namespace "${ARGO_CD_NAMESPACE}" || true
sudo k3s kubectl apply -n "${ARGO_CD_NAMESPACE}" -f "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"


# Wait for Argo CD to be ready
echo "Waiting for Argo CD to be ready..."
sudo k3s kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n "${ARGO_CD_NAMESPACE}"

# --- 3. Apply the app-of-apps application ---
echo "Applying the app-of-apps application..."
sudo k3s kubectl apply -f "k8s/templates/Application.yaml"

echo "Installation complete!"
echo "You can now access the Argo CD UI by port-forwarding the argo-cd-server service:"
echo "sudo k3s kubectl port-forward svc/argo-cd-argocd-server -n argo-cd 8080:443"
echo "Then, open https://localhost:8080 in your browser."