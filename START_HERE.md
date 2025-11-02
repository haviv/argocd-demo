# 🚀 Start Here - Two Learning Paths

You have **two options** for learning ArgoCD. Choose based on how much time you have:

---

## ⚡ Path 1: Quick Start (10 minutes)
**Best for**: Trying it out quickly without GitHub setup

### Steps:
```bash
cd /Users/havivrosh/work/misc/argocd-learning

# 1. Setup ArgoCD (2-3 minutes)
./setup.sh

# 2. Deploy the demo app with kubectl
./deploy-kubectl.sh

# 3. Access your app
kubectl port-forward svc/demo-app 8081:80
# Open: http://localhost:8081
```

**What you'll see**: A beautiful demo app running on Kubernetes!

**What you'll learn**: Kubernetes deployment basics

**Limitation**: Not using ArgoCD/GitOps yet (no auto-sync from Git)

---

## 🎓 Path 2: Full GitOps Experience (20 minutes)
**Best for**: Learning the real GitOps workflow with ArgoCD

### Steps:
```bash
cd /Users/havivrosh/work/misc/argocd-learning

# 1. Setup ArgoCD (2-3 minutes)
./setup.sh

# 2. Push code to GitHub
./github-setup.sh
# Follow the prompts to create a GitHub repo and push

# 3. Deploy with ArgoCD
./deploy-local.sh
# Choose option 2 and enter your GitHub repo URL

# 4. Access your app
kubectl port-forward svc/demo-app 8081:80
# Open: http://localhost:8081

# 5. Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: https://localhost:8080
```

**What you'll see**: 
- Your app deployed via ArgoCD
- Real-time sync status in ArgoCD UI
- Automatic deployment when you push changes to Git

**What you'll learn**: The full GitOps workflow!

---

## 🤔 Which Path Should I Choose?

### Choose Path 1 if:
- ✅ You want to see results in 10 minutes
- ✅ You don't want to create a GitHub repo right now
- ✅ You want to understand Kubernetes first

### Choose Path 2 if:
- ✅ You want the full GitOps learning experience
- ✅ You're okay creating a public GitHub repo
- ✅ You want to see ArgoCD in action

---

## 💡 Pro Tip

Do both! Start with Path 1 to see the app working, then:
```bash
# Clean up kubectl deployment
kubectl delete -f demo-app/k8s/

# Switch to GitOps
./github-setup.sh
./deploy-local.sh  # Choose option 2
```

---

## 🆘 Need Help?

All scripts have safety checks and helpful error messages. If something goes wrong:

1. Check if Docker Desktop is running
2. Run `./cleanup.sh` to start fresh
3. Check the troubleshooting section in `README.md`

---

## 📚 Next Steps

After deployment, try these exercises:

### Exercise 1: Change the Greeting
Edit `demo-app/k8s/configmap.yaml`:
```yaml
greeting: "I'm learning GitOps! 🎉"
```

**Path 1**: Apply with `kubectl apply -f demo-app/k8s/configmap.yaml`

**Path 2**: Commit and push - watch ArgoCD auto-deploy!

### Exercise 2: Scale the App
Edit `demo-app/k8s/deployment.yaml`:
```yaml
replicas: 5  # Change from 2 to 5
```

Watch it scale up!

---

**Ready?** Pick your path and let's go! 🚀

