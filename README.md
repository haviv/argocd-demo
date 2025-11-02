# ArgoCD Learning Environment

Welcome to your ArgoCD learning environment! This setup will help you understand GitOps principles and ArgoCD functionality.

## 🚀 Quick Start

### Step 1: Initial Setup
```bash
cd argocd-learning
chmod +x setup.sh
./setup.sh
```

This will:
- Install kind, kubectl, and ArgoCD CLI (if not already installed)
- Create a local Kubernetes cluster
- Install ArgoCD
- Display your admin credentials

### Step 2: Access ArgoCD UI

In a **new terminal window**, run:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then open: https://localhost:8080

Login with:
- **Username**: `admin`
- **Password**: (shown at end of setup.sh output)

> 💡 You can also retrieve the password anytime with:
> ```bash
> kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
> ```

### Step 3: Deploy the Demo App

#### Option A: Using ArgoCD CLI
```bash
# Login to ArgoCD
argocd login localhost:8080 --username admin --insecure

# Create the application
argocd app create demo-app \
  --repo https://github.com/YOUR_USERNAME/YOUR_FORKED_REPO \
  --path demo-app/k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Sync (deploy) the application
argocd app sync demo-app
```

#### Option B: Using ArgoCD UI
1. Click **"+ New App"**
2. Fill in:
   - **Application Name**: `demo-app`
   - **Project**: `default`
   - **Sync Policy**: `Manual` (or `Automatic` for auto-deploy)
   - **Repository URL**: Your Git repo URL
   - **Path**: `demo-app/k8s`
   - **Cluster URL**: `https://kubernetes.default.svc`
   - **Namespace**: `default`
3. Click **"Create"**
4. Click **"Sync"** to deploy

### Step 4: Access Your Demo App
```bash
# Port-forward the demo app
kubectl port-forward svc/demo-app 8081:80

# Open in browser
open http://localhost:8081
```

## 🎯 Learning Exercises

### Exercise 1: Manual Sync
1. Edit `demo-app/k8s/configmap.yaml` - change the greeting message
2. Commit and push to Git
3. In ArgoCD UI, click "Refresh" to detect changes
4. Click "Sync" to deploy
5. Refresh your browser at http://localhost:8081

### Exercise 2: Auto-Sync
1. In ArgoCD UI, go to App Details → App Details (top bar)
2. Enable "Auto-Sync"
3. Edit the ConfigMap again
4. Commit and push
5. Watch ArgoCD automatically deploy (within 3 minutes)

### Exercise 3: Scaling
1. Edit `demo-app/k8s/deployment.yaml` - change `replicas: 2` to `replicas: 5`
2. Commit, push, and sync
3. Watch: `kubectl get pods -w`

### Exercise 4: Rollback
1. Make a breaking change (e.g., invalid image name)
2. Commit and sync
3. In ArgoCD UI, go to "History and Rollback"
4. Click "Rollback" to previous version

## 📁 Project Structure

```
argocd-learning/
├── setup.sh              # Installation script
├── README.md             # This file
├── cleanup.sh            # Cleanup script
└── demo-app/
    └── k8s/
        ├── deployment.yaml   # App deployment
        ├── service.yaml      # Service to expose app
        └── configmap.yaml    # Configuration (edit this!)
```

## 🔧 Useful Commands

### ArgoCD CLI
```bash
# List all applications
argocd app list

# Get app details
argocd app get demo-app

# Sync an app
argocd app sync demo-app

# View app history
argocd app history demo-app

# Rollback
argocd app rollback demo-app <REVISION_ID>

# Delete an app
argocd app delete demo-app
```

### Kubectl
```bash
# View ArgoCD pods
kubectl get pods -n argocd

# View your app pods
kubectl get pods

# View app logs
kubectl logs -l app=demo-app

# Describe pod
kubectl describe pod <POD_NAME>
```

## 🧹 Cleanup

When you're done learning:
```bash
./cleanup.sh
```

This will delete the kind cluster and free up resources.

## 🎓 What You're Learning

- **GitOps**: Git as the single source of truth
- **Declarative Deployments**: Desired state in Git
- **Automatic Synchronization**: ArgoCD keeps cluster in sync with Git
- **Rollback**: Easy revert to previous versions
- **Health Monitoring**: Real-time app health status
- **Diff Detection**: See what changed before deploying

## 📚 Next Steps

1. Try Helm charts with ArgoCD
2. Explore Kustomize overlays
3. Set up multiple environments (dev, staging, prod)
4. Implement progressive delivery with Argo Rollouts
5. Configure webhooks for instant syncs

## 🆘 Troubleshooting

**ArgoCD UI won't load?**
- Check port-forward is running: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
- Try: `kubectl get pods -n argocd` (all should be Running)

**App won't sync?**
- Check repository URL is correct
- Verify path to k8s manifests
- Check ArgoCD logs: `kubectl logs -n argocd deployment/argocd-application-controller`

**Forgot admin password?**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Happy Learning! 🎉

