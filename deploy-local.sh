#!/bin/bash
set -e

echo "🚀 Deploying Demo App to ArgoCD (Local Mode)"
echo "============================================="
echo ""

# Get the absolute path to the demo-app directory
REPO_PATH="file://$(pwd)"

echo "📍 Using local repository: $REPO_PATH"
echo ""

# Check if ArgoCD CLI is logged in
if ! argocd account get-user-info &> /dev/null; then
    echo "⚠️  Not logged in to ArgoCD"
    echo ""
    echo "Please login first:"
    echo "  argocd login localhost:8080 --username admin --insecure"
    echo ""
    read -p "Press Enter to continue after logging in, or Ctrl+C to exit..."
fi

echo "🔧 Creating ArgoCD application..."

# Check if app already exists
if argocd app get demo-app &> /dev/null; then
    echo "ℹ️  Application 'demo-app' already exists"
    echo "🔄 Syncing application..."
    argocd app sync demo-app
else
    # Create the application
    argocd app create demo-app \
      --repo "$REPO_PATH" \
      --path demo-app/k8s \
      --dest-server https://kubernetes.default.svc \
      --dest-namespace default \
      --sync-policy automated \
      --sync-option Prune=true \
      --sync-option CreateNamespace=true

    echo "✅ Application created"
    echo ""
    echo "⏳ Syncing application..."
    sleep 2
    argocd app sync demo-app
fi

echo ""
echo "⏳ Waiting for application to be healthy..."
argocd app wait demo-app --timeout 120

echo ""
echo "=========================================="
echo "✅ Demo App Deployed Successfully!"
echo "=========================================="
echo ""
echo "📋 Access Your App:"
echo ""
echo "1. In a new terminal, run:"
echo "   kubectl port-forward svc/demo-app 8081:80"
echo ""
echo "2. Open your browser:"
echo "   http://localhost:8081"
echo ""
echo "3. View in ArgoCD UI:"
echo "   https://localhost:8080"
echo ""
echo "🎯 Try modifying demo-app/k8s/configmap.yaml and watch it sync!"
echo ""

# Show app status
echo "📊 Current Status:"
argocd app get demo-app

