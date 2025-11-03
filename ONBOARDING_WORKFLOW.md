# Onboarding New Tenants with ApplicationSet

## 🎯 Two Approaches

### **Approach A: Manual List** (Explicit, more control)
### **Approach B: Git Auto-Discovery** (Fully automatic!)

Let me show you both...

---

## 🟦 Approach A: Manual List ApplicationSet

### Initial Setup (ONE TIME ONLY)

**Step 1: Create the ApplicationSet**

```yaml
# applicationset-tenants.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: all-tenants
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      # Start with existing tenants
      - tenant: customer-1
      - tenant: customer-2
  
  template:
    metadata:
      name: '{{tenant}}-app'
    spec:
      project: default
      source:
        repoURL: https://github.com/haviv/argocd-demo
        path: examples/helm-example
        targetRevision: HEAD
        helm:
          valueFiles:
          - 'values-{{tenant}}.yaml'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{tenant}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

**Step 2: Apply it once**

```bash
kubectl apply -f applicationset-tenants.yaml
```

**Done!** Now customer-1 and customer-2 are managed!

---

### 🚀 Adding a New Tenant (Customer 3)

**Step 1: Create tenant values file**

```bash
cd examples/helm-example

# Option A: Use the automated script
../../add-tenant-helm.sh
# Enter: customer-3
# Enter: replicas, memory, etc.

# Option B: Manual
cat > values-customer-3.yaml << 'EOF'
replicaCount: 3

resources:
  requests:
    memory: "128Mi"
  limits:
    memory: "256Mi"

env:
  ENVIRONMENT: "production"
  TENANT_NAME: "customer-3"
  DATABASE_URL: "postgres://customer-3-db:5432"

tenant:
  name: "customer-3"
  namespace: "customer-3"
EOF
```

**Step 2: Add to ApplicationSet list**

Edit `applicationset-tenants.yaml`:

```yaml
spec:
  generators:
  - list:
      elements:
      - tenant: customer-1
      - tenant: customer-2
      - tenant: customer-3        # ← Add this line!
```

**Step 3: Commit and push**

```bash
git add values-customer-3.yaml applicationset-tenants.yaml
git commit -m "Onboard customer-3"
git push
```

**Step 4: Apply the updated ApplicationSet**

```bash
kubectl apply -f applicationset-tenants.yaml
```

**That's it!** ArgoCD automatically:
- ✅ Creates `customer-3-app` Application
- ✅ Deploys to `customer-3` namespace
- ✅ Syncs from Git

**Verification:**

```bash
# See the new Application
argocd app get customer-3-app

# See all tenant Applications
argocd app list | grep customer

# See the pods
kubectl get pods -n customer-3
```

---

## 🟩 Approach B: Git Auto-Discovery (FULLY AUTOMATIC!)

This is the ultimate automation - no need to edit ApplicationSet at all!

### Initial Setup (ONE TIME ONLY)

**Step 1: Create Auto-Discovery ApplicationSet**

```yaml
# applicationset-auto.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: auto-tenants
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: https://github.com/haviv/argocd-demo
      revision: HEAD
      files:
      - path: "examples/helm-example/values-*.yaml"
  
  template:
    metadata:
      # Extract tenant name from filename
      # values-customer-3.yaml → customer-3-app
      name: '{{path.basenameNormalized}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/haviv/argocd-demo
        path: examples/helm-example
        targetRevision: HEAD
        helm:
          valueFiles:
          - '{{path.filename}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{path.basenameNormalized}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

**Step 2: Apply it once**

```bash
kubectl apply -f applicationset-auto.yaml
```

**Done!** ApplicationSet now watches for new values files!

---

### 🚀 Adding a New Tenant (Customer 3) - AUTOMATIC MODE

**Step 1: Create tenant values file**

```bash
cd examples/helm-example

# Create values file
cat > values-customer-3.yaml << 'EOF'
replicaCount: 3
resources:
  requests:
    memory: "128Mi"
env:
  ENVIRONMENT: "production"
  TENANT_NAME: "customer-3"
tenant:
  name: "customer-3"
  namespace: "customer-3"
EOF
```

**Step 2: Commit and push**

```bash
git add values-customer-3.yaml
git commit -m "Onboard customer-3"
git push
```

**Step 3: Wait ~3 minutes**

That's it! No ApplicationSet edit needed!

ArgoCD automatically:
- 🔍 Detects new `values-customer-3.yaml` file
- 🎯 Creates `customer-3-app` Application
- 🚀 Deploys to Kubernetes
- ✅ Customer 3 is live!

**Magic! 🪄**

---

## 📊 Side-by-Side Comparison

### Manual Applications (OLD WAY):

```
1. Create values-customer-3.yaml
2. Commit & push
3. Run: argocd app create customer-3-app \
        --repo ... \
        --path ... \
        --helm-set-file values=values-customer-3.yaml
4. Run: argocd app sync customer-3-app
```

**4 steps, manual command required**

---

### ApplicationSet Manual List:

```
1. Create values-customer-3.yaml
2. Edit applicationset-tenants.yaml (add one line)
3. Commit & push both files
4. Run: kubectl apply -f applicationset-tenants.yaml
```

**4 steps, but more maintainable**

---

### ApplicationSet Auto-Discovery:

```
1. Create values-customer-3.yaml
2. Commit & push
```

**2 steps, FULLY AUTOMATIC!** 🎉

---

## 🎯 Real-World Example: Onboarding Customer ACME

Let's walk through a complete real example:

### You're using Auto-Discovery ApplicationSet

**Scenario:** New customer "ACME Corp" signs up, needs:
- 5 replicas
- 512Mi memory
- Production environment
- Custom database URL

**What you do:**

```bash
cd examples/helm-example

# 1. Create values file (30 seconds)
cat > values-acme-corp.yaml << 'EOF'
replicaCount: 5

resources:
  requests:
    memory: "256Mi"
    cpu: "500m"
  limits:
    memory: "512Mi"
    cpu: "1000m"

env:
  ENVIRONMENT: "production"
  TENANT_NAME: "acme-corp"
  LOG_LEVEL: "warn"
  DATABASE_URL: "postgres://acme-prod-db.example.com:5432/acme"
  REDIS_URL: "redis://acme-cache.example.com:6379"
  API_KEY: "acme-secret-key-prod"

tenant:
  name: "acme-corp"
  namespace: "acme-corp"
EOF

# 2. Commit and push (20 seconds)
git add values-acme-corp.yaml
git commit -m "Onboard ACME Corp - 5 replicas, 512Mi"
git push

# 3. Wait (2-3 minutes)
# ArgoCD polls Git every 3 minutes

# 4. Verify (30 seconds)
argocd app get acme-corp-app
kubectl get pods -n acme-corp
```

**Total time:** ~5 minutes (mostly waiting for ArgoCD poll)

**Manual work:** ~1 minute!

---

## 🔄 Complete Workflow Diagram

### Auto-Discovery Mode:

```
Developer                     Git                    ArgoCD
    |                          |                        |
    |-- Create values file --->|                        |
    |-- git commit/push ------>|                        |
    |                          |                        |
    |                          |<--- Poll every 3min ---|
    |                          |                        |
    |                          |--- New file detected ->|
    |                          |                        |
    |                          |          Creates Application
    |                          |          Deploys to K8s
    |                          |          Tenant is live! ✅
    |                          |                        |
    |<------------------------ Notification ------------|
    
```

**No manual Application creation needed!**

---

## 📝 Step-by-Step Checklist

### For Auto-Discovery ApplicationSet:

**One-time setup:**
- [ ] Create `applicationset-auto.yaml`
- [ ] Apply: `kubectl apply -f applicationset-auto.yaml`

**For each new tenant:**
- [ ] Create `values-TENANT.yaml` with configuration
- [ ] Test locally: `helm template TENANT . -f values-TENANT.yaml`
- [ ] Commit: `git add values-TENANT.yaml`
- [ ] Commit: `git commit -m "Onboard TENANT"`
- [ ] Push: `git push`
- [ ] Wait 3 minutes (or force sync)
- [ ] Verify: `argocd app get TENANT-app`
- [ ] Done! ✅

**For Manual List ApplicationSet, add:**
- [ ] Edit `applicationset-tenants.yaml`
- [ ] Add tenant to list
- [ ] Apply: `kubectl apply -f applicationset-tenants.yaml`

---

## 🚀 Pro Tips

### Tip 1: Force Immediate Discovery

Don't want to wait 3 minutes?

```bash
# Option A: Refresh the ApplicationSet
kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller

# Option B: Manually trigger sync
argocd app sync NEW-TENANT-app
```

### Tip 2: Use Templates for Consistency

```bash
# Create a template
cp values-template.yaml values-new-customer.yaml

# Edit with customer-specific values
nano values-new-customer.yaml
```

### Tip 3: Validation Script

```bash
#!/bin/bash
# validate-tenant.sh

TENANT=$1

# Test Helm template
echo "Testing Helm template..."
helm template $TENANT examples/helm-example \
  -f examples/helm-example/values-${TENANT}.yaml

# Dry-run in Kubernetes
echo "Testing Kubernetes apply..."
helm template $TENANT examples/helm-example \
  -f examples/helm-example/values-${TENANT}.yaml \
  | kubectl apply --dry-run=client -f -

echo "✅ Validation passed!"
```

Use it:
```bash
./validate-tenant.sh customer-3
```

### Tip 4: Organize Large Numbers of Tenants

```
tenants/
├── applicationset.yaml
├── production/
│   ├── values-customer-1.yaml
│   ├── values-customer-2.yaml
│   └── ...
├── staging/
│   ├── values-customer-1.yaml
│   └── ...
└── dev/
    └── ...
```

Update ApplicationSet to match:
```yaml
files:
- path: "tenants/production/values-*.yaml"
```

---

## ⚡ Quick Reference

### Auto-Discovery - New Tenant Workflow:

```bash
# 1. Create
./add-tenant-helm.sh

# 2. Push
git add . && git commit -m "Add tenant" && git push

# 3. Wait or force
argocd app sync NEW-TENANT-app

# Done! ✅
```

### Manual List - New Tenant Workflow:

```bash
# 1. Create values
./add-tenant-helm.sh

# 2. Edit ApplicationSet
nano applicationset-tenants.yaml
# Add: - tenant: NEW-TENANT

# 3. Push everything
git add . && git commit -m "Add tenant" && git push

# 4. Apply ApplicationSet
kubectl apply -f applicationset-tenants.yaml

# Done! ✅
```

---

## 🎓 Key Takeaways

1. **One-time setup** = ApplicationSet deployed once
2. **New tenant** = Create values file + commit + push
3. **Auto-discovery** = Fully automatic (2 steps)
4. **Manual list** = Need to edit ApplicationSet (4 steps)
5. **No more** `argocd app create` commands! 🎉

---

**Ready to try it?** Start with Auto-Discovery - it's the best! 🚀

