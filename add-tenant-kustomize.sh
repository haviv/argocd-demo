#!/bin/bash
set -e

echo "🏢 Add New Tenant (Kustomize Method)"
echo "===================================="
echo ""

# Get tenant name
read -p "Enter new tenant name (e.g., tenant-c, customer-xyz): " TENANT_NAME

if [ -z "$TENANT_NAME" ]; then
    echo "❌ Tenant name cannot be empty"
    exit 1
fi

TENANT_DIR="examples/kustomize-example/overlays/${TENANT_NAME}"

# Check if already exists
if [ -d "$TENANT_DIR" ]; then
    echo "⚠️  Tenant $TENANT_NAME already exists!"
    exit 1
fi

echo ""
echo "📋 Tenant Configuration"
echo "-----------------------"
read -p "Number of replicas [3]: " REPLICAS
REPLICAS=${REPLICAS:-3}

read -p "Memory request in Mi [128]: " MEMORY_REQUEST
MEMORY_REQUEST=${MEMORY_REQUEST:-128}

read -p "Memory limit in Mi [256]: " MEMORY_LIMIT
MEMORY_LIMIT=${MEMORY_LIMIT:-256}

read -p "Environment (dev/staging/production) [production]: " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-production}

echo ""
echo "🔧 Creating tenant overlay..."

# Create directory
mkdir -p "$TENANT_DIR"

# Create kustomization.yaml
cat > "$TENANT_DIR/kustomization.yaml" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Generated on $(date)

namespace: ${TENANT_NAME}

bases:
  - ../../base

namePrefix: ${TENANT_NAME}-

commonLabels:
  tenant: ${TENANT_NAME}

replicas:
  - name: myapp
    count: ${REPLICAS}

patches:
  - patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/env/0/value
        value: "${ENVIRONMENT}"
      - op: replace
        path: /spec/template/spec/containers/0/env/1/value
        value: "${TENANT_NAME}"
      - op: replace
        path: /spec/template/spec/containers/0/resources/requests/memory
        value: "${MEMORY_REQUEST}Mi"
      - op: replace
        path: /spec/template/spec/containers/0/resources/limits/memory
        value: "${MEMORY_LIMIT}Mi"
    target:
      kind: Deployment
      name: myapp
EOF

echo "✅ Created: $TENANT_DIR/kustomization.yaml"
echo ""

# Test locally
echo "🧪 Testing configuration..."
kubectl kustomize "$TENANT_DIR" > /dev/null
echo "✅ Configuration is valid"
echo ""

# Show what was created
echo "📄 Generated Configuration:"
echo "---"
cat "$TENANT_DIR/kustomization.yaml"
echo "---"
echo ""

# Commit
read -p "Commit and push to Git? (y/n): " commit
if [ "$commit" = "y" ]; then
    git add "$TENANT_DIR"
    git commit -m "Add tenant: ${TENANT_NAME}"
    git push
    echo "✅ Pushed to Git"
else
    echo "ℹ️  Directory created but not committed. Run manually:"
    echo "   git add $TENANT_DIR"
    echo "   git commit -m 'Add tenant: ${TENANT_NAME}'"
    echo "   git push"
fi

echo ""
echo "=========================================="
echo "🎉 Tenant Created!"
echo "=========================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Create ArgoCD Application:"
echo ""
echo "   argocd app create ${TENANT_NAME}-app \\"
echo "     --repo https://github.com/haviv/argocd-demo \\"
echo "     --path examples/kustomize-example/overlays/${TENANT_NAME} \\"
echo "     --dest-server https://kubernetes.default.svc \\"
echo "     --dest-namespace ${TENANT_NAME} \\"
echo "     --sync-policy automated \\"
echo "     --sync-option CreateNamespace=true"
echo ""
echo "2. Sync the application:"
echo "   argocd app sync ${TENANT_NAME}-app"
echo ""
echo "3. Check status:"
echo "   argocd app get ${TENANT_NAME}-app"
echo "   kubectl get all -n ${TENANT_NAME}"
echo ""

