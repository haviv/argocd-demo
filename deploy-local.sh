#!/bin/bash
set -e

echo "🚀 Deploying Demo App to ArgoCD"
echo "================================"
echo ""
echo "Choose deployment method:"
echo ""
echo "1) Quick Test (kubectl apply) - No Git required, instant deployment"
echo "2) Full GitOps (GitHub) - Real GitOps experience with ArgoCD"
echo ""
read -p "Enter your choice (1 or 2): " choice

if [ "$choice" = "1" ]; then
    echo ""
    echo "📦 Deploying with kubectl..."
    echo ""
    
    kubectl apply -f demo-app/k8s/
    
    echo ""
    echo "⏳ Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=120s deployment/demo-app
    
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
    echo "💡 Note: This is NOT using ArgoCD - it's direct kubectl deployment."
    echo "   For the full GitOps experience, push to GitHub and use option 2!"
    echo ""
    
elif [ "$choice" = "2" ]; then
    echo ""
    read -p "Enter your GitHub repository URL (e.g., https://github.com/username/repo.git): " REPO_URL
    
    if [ -z "$REPO_URL" ]; then
        echo "❌ Repository URL cannot be empty"
        exit 1
    fi
    
    # Remove .git suffix if present for ArgoCD
    REPO_URL=${REPO_URL%.git}
    
    echo ""
    echo "📍 Using repository: $REPO_URL"
    echo ""
    
    # Check if ArgoCD CLI is logged in
    if ! argocd account get-user-info &> /dev/null; then
        echo "🔐 Logging in to ArgoCD..."
        
        # Get admin password
        ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
        
        argocd login localhost:8080 \
          --username admin \
          --password "$ARGOCD_PASSWORD" \
          --insecure
        
        echo "✅ Logged in"
    fi
    
    echo ""
    echo "🔧 Creating ArgoCD application..."
    
    # Check if app already exists
    if argocd app get demo-app &> /dev/null; then
        echo "ℹ️  Application 'demo-app' already exists"
        
        # Update the repo URL
        argocd app set demo-app --repo "$REPO_URL"
        
        echo "🔄 Syncing application..."
        argocd app sync demo-app
    else
        # Create the application
        argocd app create demo-app \
          --repo "$REPO_URL" \
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
    echo "🎯 Try modifying demo-app/k8s/configmap.yaml, commit, push, and watch ArgoCD sync!"
    echo ""
    
    # Show app status
    echo "📊 Current Status:"
    argocd app get demo-app
else
    echo "❌ Invalid choice"
    exit 1
fi

