#!/bin/bash
set -e

echo "🚀 Setting up ArgoCD Learning Environment"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo -e "${YELLOW}📦 Installing kind...${NC}"
    brew install kind
else
    echo -e "${GREEN}✅ kind already installed${NC}"
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}📦 Installing kubectl...${NC}"
    brew install kubectl
else
    echo -e "${GREEN}✅ kubectl already installed${NC}"
fi

# Check if ArgoCD CLI is installed
if ! command -v argocd &> /dev/null; then
    echo -e "${YELLOW}📦 Installing ArgoCD CLI...${NC}"
    brew install argocd
else
    echo -e "${GREEN}✅ ArgoCD CLI already installed${NC}"
fi

echo ""
echo -e "${YELLOW}🔧 Creating kind cluster...${NC}"
# Check if cluster already exists
if kind get clusters | grep -q "argocd-learning"; then
    echo -e "${GREEN}✅ Cluster 'argocd-learning' already exists${NC}"
else
    kind create cluster --name argocd-learning
    echo -e "${GREEN}✅ Cluster created${NC}"
fi

echo ""
echo -e "${YELLOW}🔧 Installing ArgoCD...${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ""
echo -e "${YELLOW}⏳ Waiting for ArgoCD to be ready (this may take 2-3 minutes)...${NC}"
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
sleep 5

echo ""
echo -e "${GREEN}✅ ArgoCD is ready!${NC}"
echo ""

# Get admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "=========================================="
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Access ArgoCD UI:"
echo "   Run: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   Open: https://localhost:8080"
echo "   (Accept the self-signed certificate warning)"
echo ""
echo "2. Login credentials:"
echo "   Username: admin"
echo "   Password: ${ARGOCD_PASSWORD}"
echo ""
echo "3. Or login via CLI:"
echo "   argocd login localhost:8080 --username admin --password ${ARGOCD_PASSWORD} --insecure"
echo ""
echo "4. Deploy the demo app - see README.md for instructions!"
echo ""
echo "💡 Tip: Keep the port-forward terminal running to access the UI"
echo ""

