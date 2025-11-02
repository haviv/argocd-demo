#!/bin/bash
set -e

echo "🚀 Setting Up Full ArgoCD GitOps Experience"
echo "============================================"
echo ""

# Step 1: Create GitHub repo instructions
echo "📋 Step 1: Create GitHub Repository"
echo "------------------------------------"
echo ""
echo "Please complete these steps:"
echo ""
echo "1. Open: https://github.com/new"
echo ""
echo "2. Fill in:"
echo "   • Repository name: argocd-demo"
echo "   • Visibility: PUBLIC (very important!)"
echo "   • DON'T check any initialization options"
echo ""
echo "3. Click 'Create repository'"
echo ""
read -p "Press Enter when you've created the repo (or Ctrl+C to exit)..."

echo ""
echo "✅ Great! Moving to next step..."
echo ""

# Step 2: Commit current changes
echo "📦 Step 2: Committing Current Changes"
echo "--------------------------------------"
cd /Users/havivrosh/work/misc/argocd-learning

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Committing your changes..."
    git add .
    git commit -m "Update configuration for ArgoCD deployment" || true
    echo "✅ Changes committed"
else
    echo "✅ No new changes to commit"
fi

echo ""

# Step 3: Push to GitHub
echo "📤 Step 3: Pushing to GitHub"
echo "-----------------------------"
echo ""

# Check if origin exists and push
if git remote get-url origin &> /dev/null; then
    echo "Remote 'origin' already configured: $(git remote get-url origin)"
    echo ""
    read -p "Push to this repository? (y/n): " confirm
    if [ "$confirm" = "y" ]; then
        echo "Pushing to GitHub..."
        git push -u origin main
        echo "✅ Code pushed to GitHub!"
    else
        echo "❌ Cancelled"
        exit 1
    fi
else
    echo "❌ No remote configured"
    echo "Please run these commands manually:"
    echo ""
    echo "  git remote add origin https://github.com/YOUR_USERNAME/argocd-demo.git"
    echo "  git push -u origin main"
    exit 1
fi

echo ""

# Step 4: Clean up kubectl deployment
echo "🧹 Step 4: Cleaning Up kubectl Deployment"
echo "------------------------------------------"
echo "Removing the old kubectl deployment to switch to ArgoCD..."
kubectl delete -f demo-app/k8s/ --ignore-not-found=true
echo "✅ Cleanup complete"
echo ""

# Step 5: Deploy with ArgoCD
echo "🚀 Step 5: Deploying with ArgoCD"
echo "---------------------------------"
echo ""

# Get the remote URL
REPO_URL=$(git remote get-url origin | sed 's/\.git$//')
echo "Using repository: $REPO_URL"
echo ""

# Login to ArgoCD
echo "🔐 Logging into ArgoCD..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

argocd login localhost:8080 \
  --username admin \
  --password "$ARGOCD_PASSWORD" \
  --insecure

echo "✅ Logged in"
echo ""

# Create the application
echo "🔧 Creating ArgoCD application..."

if argocd app get demo-app &> /dev/null; then
    echo "Application 'demo-app' already exists, updating..."
    argocd app set demo-app --repo "$REPO_URL"
    argocd app sync demo-app
else
    argocd app create demo-app \
      --repo "$REPO_URL" \
      --path demo-app/k8s \
      --dest-server https://kubernetes.default.svc \
      --dest-namespace default \
      --sync-policy automated \
      --sync-option Prune=true \
      --sync-option CreateNamespace=true
    
    echo "✅ Application created"
    sleep 2
    argocd app sync demo-app
fi

echo ""
echo "⏳ Waiting for application to be healthy..."
argocd app wait demo-app --timeout 180

echo ""
echo "=========================================="
echo "🎉 SUCCESS! ArgoCD GitOps is Ready!"
echo "=========================================="
echo ""
echo "📋 What's Running:"
echo ""
echo "1. ArgoCD UI:"
echo "   URL: https://localhost:8080"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "   (Run in new terminal if not already running):"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "2. Demo App:"
echo "   URL: http://localhost:8081"
echo ""
echo "   (Run in new terminal):"
echo "   kubectl port-forward svc/demo-app 8081:80"
echo ""
echo "🎯 Try GitOps Now!"
echo ""
echo "1. Edit a file:"
echo "   nano demo-app/k8s/configmap.yaml"
echo ""
echo "2. Commit and push:"
echo "   git add ."
echo "   git commit -m 'Update greeting'"
echo "   git push"
echo ""
echo "3. Watch the magic:"
echo "   - Open ArgoCD UI: https://localhost:8080"
echo "   - Watch it detect changes (click Refresh if needed)"
echo "   - See it auto-sync within 3 minutes!"
echo "   - Refresh your app browser"
echo ""
echo "That's GitOps! 🚀"
echo ""

