# Quick Comparison: How to Onboard a New Tenant

## 🔴 OLD WAY: Manual Application per Tenant

### Adding Customer 3:

```bash
# Step 1: Create values
cat > values-customer-3.yaml << 'EOF'
replicaCount: 3
# ... tenant config
EOF

# Step 2: Commit & Push
git add values-customer-3.yaml
git commit -m "Add customer-3"
git push

# Step 3: Create Application manually
argocd app create customer-3-app \
  --repo https://github.com/haviv/argocd-demo \
  --path examples/helm-example \
  --dest-namespace customer-3 \
  --helm-set-file values=values-customer-3.yaml \
  --sync-policy automated

# Step 4: Sync
argocd app sync customer-3-app
```

**Repeat for customer 4, 5, 6... 20! 😫**

---

## 🟢 NEW WAY: ApplicationSet Auto-Discovery

### One-Time Setup (do this once):

```bash
# Create ApplicationSet
cat > applicationset-auto.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: auto-tenants
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: https://github.com/haviv/argocd-demo
      files:
      - path: "examples/helm-example/values-*.yaml"
  template:
    metadata:
      name: '{{path.basenameNormalized}}'
    spec:
      source:
        repoURL: https://github.com/haviv/argocd-demo
        path: examples/helm-example
        helm:
          valueFiles:
          - '{{path.filename}}'
      destination:
        namespace: '{{path.basenameNormalized}}'
      syncPolicy:
        automated: {}
EOF

# Apply once
kubectl apply -f applicationset-auto.yaml
```

### Adding Customer 3 (and 4, 5, 6... forever):

```bash
# Step 1: Create values
cat > values-customer-3.yaml << 'EOF'
replicaCount: 3
# ... tenant config
EOF

# Step 2: Commit & Push
git add values-customer-3.yaml
git commit -m "Add customer-3"
git push

# Step 3: Done! ✅
# ArgoCD automatically creates customer-3-app
# No manual commands needed!
```

**Same 2 steps for every customer! 🎉**

---

## 📊 Visual Comparison

### Manual (20 customers):

```
Customer 1:  Create values → Commit → argocd app create → sync
Customer 2:  Create values → Commit → argocd app create → sync
Customer 3:  Create values → Commit → argocd app create → sync
...
Customer 20: Create values → Commit → argocd app create → sync

Total: 80 commands (4 per customer)
```

### ApplicationSet (20 customers):

```
Setup:       Create ApplicationSet → kubectl apply (ONCE!)

Customer 1:  Create values → Commit → Push → ✅ Auto-deployed
Customer 2:  Create values → Commit → Push → ✅ Auto-deployed
Customer 3:  Create values → Commit → Push → ✅ Auto-deployed
...
Customer 20: Create values → Commit → Push → ✅ Auto-deployed

Setup: 1 command
Per customer: 3 commands (no ArgoCD commands!)
Total: 1 + (3 × 20) = 61 commands (vs 80)
```

### ApplicationSet with script (20 customers):

```
Setup:       Create ApplicationSet → kubectl apply (ONCE!)

Customer 1:  ./add-tenant-helm.sh → Push → ✅ Auto-deployed
Customer 2:  ./add-tenant-helm.sh → Push → ✅ Auto-deployed
Customer 3:  ./add-tenant-helm.sh → Push → ✅ Auto-deployed
...
Customer 20: ./add-tenant-helm.sh → Push → ✅ Auto-deployed

Setup: 1 command
Per customer: 2 commands
Total: 1 + (2 × 20) = 41 commands
```

---

## ⚡ Bottom Line

| Method | Commands per Tenant | For 20 Tenants | Scalable? |
|--------|---------------------|----------------|-----------|
| **Manual** | 4 | 80 | ❌ No |
| **ApplicationSet** | 3 | 61 | ✅ Yes |
| **ApplicationSet + Script** | 2 | 41 | ✅✅ Yes! |

**Time saved per tenant: ~2 minutes**
**Time saved for 20 tenants: ~40 minutes**
**Time saved for 100 tenants: ~3+ hours!**

---

## 🎯 The Workflow You Want

```
New customer signs up
       ↓
Run: ./add-tenant-helm.sh
(Enter tenant name and config)
       ↓
Run: git push
       ↓
Wait 3 minutes
       ↓
Customer is deployed! ✅
```

**That's it!**

No `argocd app create`
No `argocd app sync`
No manual Application management

**Fully automated!** 🚀

