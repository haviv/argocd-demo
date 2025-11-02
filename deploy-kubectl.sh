#!/bin/bash
set -e

echo "📦 Quick Deploy with kubectl"
echo "============================"
echo ""
echo "This deploys the demo app directly with kubectl (no ArgoCD/GitOps)."
echo "Perfect for quick testing before setting up GitHub!"
echo ""

kubectl apply -f demo-app/k8s/

echo ""
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/demo-app 2>/dev/null || true

echo ""
echo "=========================================="
echo "✅ Demo App Deployed!"
echo "=========================================="
echo ""
echo "📋 Access Your App:"
echo ""
echo "Run in a new terminal:"
echo "  kubectl port-forward svc/demo-app 8081:80"
echo ""
echo "Then open: http://localhost:8081"
echo ""
echo "💡 To experience GitOps with ArgoCD:"
echo "   1. Push this code to GitHub: ./github-setup.sh"
echo "   2. Delete this deployment: kubectl delete -f demo-app/k8s/"
echo "   3. Deploy with ArgoCD: ./deploy-local.sh (option 2)"
echo ""

