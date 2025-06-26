#!/bin/bash

# Exit on any error
set -e

# --- Configuration ---
ARGO_CD_NAMESPACE="argo-cd"
ARGO_CD_CHART_PATH="k8s/modules/argo-cd"
ARGO_CD_RELEASE_NAME="argo-cd"

# --- 1. Install k3s ---
echo "Installing k3s and creating a readable kubeconfig..."
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# Give the k3s service a moment to start up properly
echo "Waiting for k3s server to initialize..."
sleep 15

# Set KUBECONFIG env variable for this script session
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "Waiting for k3s node to be ready..."
# Now this command should find the node resource
k3s kubectl wait --for=condition=Ready node --all --timeout=300s

sleep 60

# --- 2. Install Argo CD using your existing Helm ---
echo "Installing Argo CD with Helm from local chart..."
helm install ${ARGO_CD_RELEASE_NAME} ${ARGO_CD_CHART_PATH} \
    --namespace ${ARGO_CD_NAMESPACE} \
    --create-namespace

# Wait for Argo CD to be ready
echo "Waiting for Argo CD to be ready..."
k3s kubectl wait --for=condition=available --timeout=600s deployment/${ARGO_CD_RELEASE_NAME}-argocd-server -n "${ARGO_CD_NAMESPACE}"

# --- 3. Apply the app-of-apps application ---
echo "Applying the app-of-apps application..."
k3s kubectl apply -f "k8s/templates/Application.yaml"

echo "--------------------------------------"
echo "Installation complete!"
echo "Argo CD and the app-of-apps are set up."
echo "--------------------------------------"