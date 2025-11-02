#!/bin/bash

echo "🧹 Cleaning up ArgoCD Learning Environment"
echo "=========================================="
echo ""

# Delete the kind cluster
if kind get clusters | grep -q "argocd-learning"; then
    echo "🗑️  Deleting kind cluster 'argocd-learning'..."
    kind delete cluster --name argocd-learning
    echo "✅ Cluster deleted"
else
    echo "ℹ️  Cluster 'argocd-learning' not found"
fi

echo ""
echo "✨ Cleanup complete!"
echo ""
echo "To start fresh, run: ./setup.sh"

