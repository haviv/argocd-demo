#!/bin/bash
set -e

echo "🐙 GitHub Setup Guide"
echo "====================="
echo ""
echo "To use the full GitOps experience with ArgoCD, you need to:"
echo ""
echo "1️⃣  Create a GitHub repository"
echo "   - Go to: https://github.com/new"
echo "   - Repository name: argocd-demo (or any name you like)"
echo "   - Make it Public (easier for learning, no auth needed)"
echo "   - Don't initialize with README, .gitignore, or license"
echo "   - Click 'Create repository'"
echo ""
echo "2️⃣  Push this code to GitHub"
echo ""

# Initialize git if not already done
if [ ! -d .git ]; then
    echo "Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit: ArgoCD demo app"
fi

echo "After creating your GitHub repo, run these commands:"
echo ""
echo "---------------------------------------------------"
echo "git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
echo "git branch -M main"
echo "git push -u origin main"
echo "---------------------------------------------------"
echo ""
read -p "Have you created the GitHub repo and want to continue? (y/n): " continue

if [ "$continue" != "y" ]; then
    echo ""
    echo "No problem! Come back and run this script when you're ready."
    echo "Or run ./deploy-local.sh and choose option 1 for quick testing!"
    exit 0
fi

echo ""
read -p "Enter your GitHub repository URL (e.g., https://github.com/username/repo.git): " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo "❌ Repository URL cannot be empty"
    exit 1
fi

# Extract username and repo name for display
REPO_INFO=$(echo "$REPO_URL" | sed 's/.*github.com[:/]\(.*\)\.git/\1/' | sed 's/.*github.com[:/]\(.*\)/\1/')

echo ""
echo "📤 Pushing to GitHub..."
echo ""

# Add remote if not exists
if ! git remote get-url origin &> /dev/null; then
    git remote add origin "$REPO_URL"
else
    git remote set-url origin "$REPO_URL"
fi

# Push to GitHub
git branch -M main
git push -u origin main

echo ""
echo "=========================================="
echo "✅ Code pushed to GitHub!"
echo "=========================================="
echo ""
echo "Your repository: https://github.com/$REPO_INFO"
echo ""
echo "🎯 Next Steps:"
echo ""
echo "1. Verify your code is on GitHub (check the URL above)"
echo ""
echo "2. Deploy with ArgoCD:"
echo "   ./deploy-local.sh"
echo "   Choose option 2 (Full GitOps)"
echo "   Enter your repo URL when prompted"
echo ""
echo "3. Make changes to demo-app/k8s/configmap.yaml"
echo "   git add ."
echo "   git commit -m 'Update greeting'"
echo "   git push"
echo ""
echo "4. Watch ArgoCD automatically sync your changes! 🚀"
echo ""

