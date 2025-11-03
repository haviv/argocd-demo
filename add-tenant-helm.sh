#!/bin/bash
set -e

echo "🏢 Add New Tenant (Helm Method)"
echo "==============================="
echo ""

# Get tenant name
read -p "Enter new tenant name (e.g., tenant-c, customer-xyz): " TENANT_NAME

if [ -z "$TENANT_NAME" ]; then
    echo "❌ Tenant name cannot be empty"
    exit 1
fi

TENANT_FILE="examples/helm-example/values-${TENANT_NAME}.yaml"

# Check if already exists
if [ -f "$TENANT_FILE" ]; then
    echo "⚠️  Tenant $TENANT_NAME already exists!"
    read -p "Overwrite? (y/n): " overwrite
    if [ "$overwrite" != "y" ]; then
        echo "Cancelled"
        exit 0
    fi
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

read -p "Database URL [postgres://${TENANT_NAME}-db:5432]: " DB_URL
DB_URL=${DB_URL:-postgres://${TENANT_NAME}-db:5432}

echo ""
echo "🔧 Creating tenant configuration..."

# Create values file
cat > "$TENANT_FILE" << EOF
# ${TENANT_NAME} specific values
# Generated on $(date)

replicaCount: ${REPLICAS}

resources:
  requests:
    memory: "${MEMORY_REQUEST}Mi"
    cpu: "200m"
  limits:
    memory: "${MEMORY_LIMIT}Mi"
    cpu: "400m"

env:
  ENVIRONMENT: "${ENVIRONMENT}"
  TENANT_NAME: "${TENANT_NAME}"
  LOG_LEVEL: "info"
  DATABASE_URL: "${DB_URL}"

tenant:
  name: "${TENANT_NAME}"
  namespace: "${TENANT_NAME}"
EOF

echo "✅ Created: $TENANT_FILE"
echo ""

# Test locally
echo "🧪 Testing configuration..."
helm template ${TENANT_NAME} examples/helm-example -f "$TENANT_FILE" > /dev/null
echo "✅ Configuration is valid"
echo ""

# Show what was created
echo "📄 Generated Configuration:"
echo "---"
cat "$TENANT_FILE"
echo "---"
echo ""

# Commit
read -p "Commit and push to Git? (y/n): " commit
if [ "$commit" = "y" ]; then
    git add "$TENANT_FILE"
    git commit -m "Add tenant: ${TENANT_NAME}"
    git push
    echo "✅ Pushed to Git"
else
    echo "ℹ️  File created but not committed. Run manually:"
    echo "   git add $TENANT_FILE"
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
echo "     --path examples/helm-example \\"
echo "     --dest-server https://kubernetes.default.svc \\"
echo "     --dest-namespace ${TENANT_NAME} \\"
echo "     --helm-set-file values=values-${TENANT_NAME}.yaml \\"
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

