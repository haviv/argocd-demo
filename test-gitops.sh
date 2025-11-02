#!/bin/bash
set -e

echo "🎯 Testing GitOps Workflow"
echo "=========================="
echo ""

# Make a change
echo "1️⃣  Making a change to configmap..."
sed -i.bak 's/greeting: ".*"/greeting: "GitOps is working! 🎉 Updated: '$(date +%H:%M:%S)'"/' demo-app/k8s/configmap.yaml
echo "✅ Changed greeting message"
echo ""

# Show the change
echo "📝 New greeting:"
grep "greeting:" demo-app/k8s/configmap.yaml
echo ""

# Commit
echo "2️⃣  Committing to Git..."
git add demo-app/k8s/configmap.yaml
git commit -m "Test: Update greeting at $(date +%H:%M:%S)"
echo "✅ Committed"
echo ""

# Push
echo "3️⃣  Pushing to GitHub..."
git push
echo "✅ Pushed to GitHub!"
echo ""

echo "=========================================="
echo "🎉 Change is now in Git!"
echo "=========================================="
echo ""
echo "⏳ Now ArgoCD will detect this change and auto-sync"
echo ""
echo "📊 Watch it happen:"
echo ""
echo "Option 1 - ArgoCD UI:"
echo "  1. Open: https://localhost:8080/applications/demo-app"
echo "  2. Click 'Refresh' button (top right)"
echo "  3. Watch it change from 'Synced' to 'OutOfSync'"
echo "  4. Watch it auto-sync within ~3 minutes"
echo ""
echo "Option 2 - Command line:"
echo "  argocd app get demo-app --refresh"
echo ""
echo "Option 3 - Watch in real-time:"
echo "  watch -n 2 'argocd app get demo-app'"
echo ""
echo "⏰ ArgoCD polls GitHub every 3 minutes by default"
echo "💡 Click 'Refresh' then 'Sync' in UI for instant sync"
echo ""
