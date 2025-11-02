# 🚀 ArgoCD Quick Start Guide

Follow these steps to get your ArgoCD learning environment up and running in minutes!

## Prerequisites

- Docker Desktop running on your Mac
- Terminal access

That's it! The setup script will install everything else.

---

## Step-by-Step Setup

### 1️⃣ Run the Setup Script (5 minutes)

```bash
cd argocd-learning
./setup.sh
```

This will:
- ✅ Install kind, kubectl, and ArgoCD CLI
- ✅ Create a local Kubernetes cluster
- ✅ Install ArgoCD
- ✅ Show you the admin password

**⚠️ Save the admin password shown at the end!**

---

### 2️⃣ Access ArgoCD UI

**Open a NEW terminal tab/window** and run:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Keep this running! Then open in your browser:
- **URL**: https://localhost:8080
- **Username**: `admin`
- **Password**: (from setup.sh output)

**Note**: You'll see a security warning about the self-signed certificate. Click "Advanced" → "Proceed anyway"

---

### 3️⃣ Initialize Git Repository

```bash
./init-git-repo.sh
```

This prepares your demo app to be tracked in Git (required for ArgoCD).

---

### 4️⃣ Deploy the Demo App

**Option A: Automated (Recommended for First Try)**

```bash
./deploy-local.sh
```

This will automatically:
- Login to ArgoCD
- Create and deploy the demo app
- Wait for it to be healthy

**Option B: Manual (Using ArgoCD UI)**

1. In ArgoCD UI, click **"+ NEW APP"**
2. Fill in:
   - **Application Name**: `demo-app`
   - **Project Name**: `default`
   - **Sync Policy**: Choose `Automatic`
   - **Repository URL**: `file:///Users/havivrosh/work/misc/argocd-learning`
   - **Path**: `demo-app/k8s`
   - **Cluster URL**: `https://kubernetes.default.svc`
   - **Namespace**: `default`
3. Click **CREATE**
4. Click **SYNC** (if not automatic)

---

### 5️⃣ Access Your Demo App

**Open ANOTHER new terminal window** and run:

```bash
kubectl port-forward svc/demo-app 8081:80
```

Then open: **http://localhost:8081**

You should see a beautiful purple gradient page with "Hello from ArgoCD! 🚀"

---

## 🎯 Your First GitOps Change

Now let's see the magic of GitOps in action!

### Step 1: Edit the App
```bash
# Open the config file in your favorite editor
nano demo-app/k8s/configmap.yaml
# or
code demo-app/k8s/configmap.yaml
```

### Step 2: Change the Greeting
Find this line:
```yaml
greeting: "Hello from ArgoCD! 🚀"
```

Change it to:
```yaml
greeting: "I just deployed with GitOps! 🎉"
```

### Step 3: Commit the Change
```bash
git add demo-app/k8s/configmap.yaml
git commit -m "Update greeting message"
```

### Step 4: Watch ArgoCD Sync

**If auto-sync is enabled:**
- Wait ~30 seconds to 3 minutes
- Watch the ArgoCD UI refresh
- The app will automatically update!

**If manual sync:**
1. In ArgoCD UI, click **"Refresh"**
2. You'll see the app is "Out of Sync"
3. Click **"Sync"** → **"Synchronize"**

### Step 5: See the Change
Refresh your browser at http://localhost:8081

**🎉 Boom! Your change is live!**

---

## 📊 What's Running?

You should have **3 terminal windows** open:

1. **ArgoCD UI Port-Forward**: `kubectl port-forward svc/argocd-server -n argocd 8080:443`
2. **Demo App Port-Forward**: `kubectl port-forward svc/demo-app 8081:80`
3. **Your working terminal**: For making changes, running commands

---

## 🎓 Learning Exercises

### Exercise 1: Scale the App
Edit `demo-app/k8s/deployment.yaml`:
```yaml
replicas: 2  # Change to 5
```
Commit, sync, and run: `kubectl get pods -w`

### Exercise 2: Change the Version
Edit `demo-app/k8s/configmap.yaml`:
```yaml
version: "v1.0"  # Change to "v2.0"
```
Commit and sync. See the version change on the webpage!

### Exercise 3: Break and Rollback
1. Edit deployment.yaml - change image to: `nginx:invalid-tag`
2. Commit and sync
3. Watch it fail in ArgoCD
4. In ArgoCD UI → "History and Rollback" → Click rollback on a working version
5. See it recover!

### Exercise 4: Multiple Changes
Change both greeting and version at once, commit, and sync. Watch both update!

---

## 🔍 Useful Commands

```bash
# View ArgoCD apps
argocd app list

# Get app details
argocd app get demo-app

# View Kubernetes pods
kubectl get pods

# View pod logs
kubectl logs -l app=demo-app

# View ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Restart from scratch
./cleanup.sh
./setup.sh
```

---

## 🐛 Troubleshooting

### ArgoCD UI won't load?
```bash
# Check if port-forward is running
ps aux | grep "port-forward"

# Check ArgoCD is healthy
kubectl get pods -n argocd
```

### Demo app won't load?
```bash
# Check pods are running
kubectl get pods

# Check for errors
kubectl describe pod -l app=demo-app
kubectl logs -l app=demo-app
```

### Forgot admin password?
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

### Need to start fresh?
```bash
./cleanup.sh
./setup.sh
```

---

## 🎉 What You've Learned

- ✅ Installed and configured ArgoCD
- ✅ Deployed an app using GitOps
- ✅ Made changes and watched them sync
- ✅ Understood declarative deployments
- ✅ Experienced Git as the source of truth

## 📚 Next Steps

1. **Push to GitHub**: Push this repo to GitHub and use a real Git URL
2. **Try Helm**: Deploy a Helm chart with ArgoCD
3. **Multiple Environments**: Create dev/staging/prod configurations
4. **Webhooks**: Set up instant syncs on Git push
5. **Argo Rollouts**: Try blue-green and canary deployments

---

## 🧹 When You're Done

```bash
./cleanup.sh
```

This deletes the cluster and frees up resources.

---

**Happy Learning! 🚀**

Need help? Check the full README.md for more details!

