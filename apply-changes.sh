#!/bin/bash
set -e

echo "🔄 Applying Changes to Kubernetes"
echo "=================================="
echo ""

kubectl apply -f demo-app/k8s/

echo ""
echo "⏳ Waiting for changes to roll out..."
kubectl rollout status deployment/demo-app --timeout=60s

echo ""
echo "✅ Changes applied!"
echo ""
echo "🔄 Restart your port-forward to see changes:"
echo "   kubectl port-forward svc/demo-app 8081:80"
echo ""
echo "💡 TIP: With ArgoCD (Option 1), this happens automatically!"
echo "   Changes in Git → Auto-deployed. That's GitOps! 🚀"
echo ""
