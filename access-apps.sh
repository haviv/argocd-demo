#!/bin/bash

echo "🌐 Access Your Apps"
echo "==================="
echo ""
echo "You need 2 port-forwards running:"
echo ""
echo "Terminal 1 - ArgoCD UI (Admin Console):"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Then open: https://localhost:8080"
echo ""
echo "Terminal 2 - Demo App (Your Web App):"
echo "  kubectl port-forward svc/demo-app 8081:80"
echo "  Then open: http://localhost:8081"
echo ""
echo "💡 Keep both terminals running!"
echo ""
echo "Which one do you want to start?"
echo "1) ArgoCD UI (https://localhost:8080)"
echo "2) Demo App (http://localhost:8081)"
echo "3) Both (in background - will show logs)"
echo ""
read -p "Choice (1-3): " choice

case $choice in
  1)
    echo ""
    echo "🚀 Starting ArgoCD UI port-forward..."
    echo "📱 Open: https://localhost:8080"
    echo ""
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo "Login: admin / $ARGOCD_PASSWORD"
    echo ""
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    ;;
  2)
    echo ""
    echo "🚀 Starting Demo App port-forward..."
    echo "📱 Open: http://localhost:8081"
    echo ""
    kubectl port-forward svc/demo-app 8081:80
    ;;
  3)
    echo ""
    echo "🚀 Starting both port-forwards in background..."
    kubectl port-forward svc/argocd-server -n argocd 8080:443 > /tmp/argocd-pf.log 2>&1 &
    ARGOCD_PID=$!
    kubectl port-forward svc/demo-app 8081:80 > /tmp/demo-app-pf.log 2>&1 &
    DEMO_PID=$!
    sleep 2
    echo ""
    echo "✅ Port forwards started!"
    echo ""
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo "📱 ArgoCD UI: https://localhost:8080 (admin / $ARGOCD_PASSWORD)"
    echo "📱 Demo App: http://localhost:8081"
    echo ""
    echo "PIDs: ArgoCD=$ARGOCD_PID, Demo=$DEMO_PID"
    echo ""
    echo "To stop:"
    echo "  kill $ARGOCD_PID $DEMO_PID"
    echo ""
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac

