#!/bin/bash
set -e

echo "🎯 ApplicationSet Onboarding Demo"
echo "=================================="
echo ""
echo "This script demonstrates how to onboard a new tenant"
echo "when using ApplicationSet (Auto-Discovery mode)"
echo ""

TENANT_NAME="demo-customer"
TENANT_FILE="examples/helm-example/values-${TENANT_NAME}.yaml"

echo "📋 Scenario: Onboarding '${TENANT_NAME}'"
echo ""

# Step 1
echo "Step 1: Create tenant values file"
echo "----------------------------------"

cat > "$TENANT_FILE" << 'EOF'
# Demo customer configuration
replicaCount: 3

resources:
  requests:
    memory: "128Mi"
    cpu: "200m"
  limits:
    memory: "256Mi"
    cpu: "400m"

env:
  ENVIRONMENT: "production"
  TENANT_NAME: "demo-customer"
  LOG_LEVEL: "info"
  DATABASE_URL: "postgres://demo-customer-db:5432"

tenant:
  name: "demo-customer"
  namespace: "demo-customer"
EOF

echo "✅ Created: $TENANT_FILE"
echo ""

# Show contents
echo "📄 File contents:"
echo "---"
cat "$TENANT_FILE"
echo "---"
echo ""

# Step 2
echo "Step 2: Test locally (optional but recommended)"
echo "------------------------------------------------"

if command -v helm &> /dev/null; then
    echo "Testing Helm template..."
    helm template demo-customer examples/helm-example -f "$TENANT_FILE" > /dev/null
    echo "✅ Helm template valid!"
else
    echo "⚠️  Helm not installed, skipping validation"
fi
echo ""

# Step 3
echo "Step 3: Commit and push to Git"
echo "-------------------------------"

git add "$TENANT_FILE"

if git diff --cached --quiet; then
    echo "ℹ️  No changes to commit (file already exists)"
else
    git commit -m "Demo: Onboard ${TENANT_NAME}"
    echo "✅ Committed"
fi

echo ""
echo "Would push with: git push"
echo "ℹ️  Not pushing in demo mode"
echo ""

# Step 4
echo "Step 4: What happens next (Automatic!)"
echo "---------------------------------------"
echo ""
echo "With Auto-Discovery ApplicationSet:"
echo ""
echo "1. ArgoCD polls Git (every 3 minutes)"
echo "2. Detects new values-${TENANT_NAME}.yaml file"
echo "3. Automatically creates Application: ${TENANT_NAME}-app"
echo "4. Deploys to namespace: ${TENANT_NAME}"
echo "5. Tenant is live! ✅"
echo ""
echo "NO manual 'argocd app create' needed!"
echo ""

# Summary
echo "=========================================="
echo "🎉 Onboarding Complete!"
echo "=========================================="
echo ""
echo "📊 Summary:"
echo ""
echo "Files created:"
echo "  - $TENANT_FILE"
echo ""
echo "What you did:"
echo "  1. Created values file (30 seconds)"
echo "  2. Committed to Git (10 seconds)"
echo "  3. Push to GitHub (5 seconds)"
echo ""
echo "What ArgoCD does automatically:"
echo "  1. Detects new file (3 minutes)"
echo "  2. Creates Application"
echo "  3. Deploys tenant"
echo ""
echo "Total manual effort: ~45 seconds!"
echo ""
echo "🎯 To verify (when deployed):"
echo "  argocd app get ${TENANT_NAME}-app"
echo "  kubectl get pods -n ${TENANT_NAME}"
echo ""
echo "🧹 To clean up demo:"
echo "  git reset HEAD~1"
echo "  rm $TENANT_FILE"
echo ""

