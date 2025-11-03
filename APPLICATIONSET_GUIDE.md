# ApplicationSet: Managing Multiple Tenants Automatically

## 🎯 The Problem You're Facing

**Scenario:** You have 20 customers, each needs their own deployment.

**Manual approach:**
```bash
argocd app create customer-1-app ...
argocd app create customer-2-app ...
argocd app create customer-3-app ...
# ... 17 more times 😫
```

**Problems:**
- ❌ 20 separate commands
- ❌ Repetitive and error-prone
- ❌ Adding customer 21? Run another command
- ❌ Updating all customers? Update 20 Applications!
- ❌ Not scalable

---

## ✅ The Solution: ApplicationSet

**One YAML file = All Applications automatically created!**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: all-my-customers
spec:
  generators:
  - list:
      elements:
      - tenant: customer-1
      - tenant: customer-2
      # ... all 20 customers
  
  template:
    # ArgoCD generates one Application per customer!
    metadata:
      name: '{{tenant}}-app'
    spec:
      source:
        repoURL: https://github.com/haviv/argocd-demo
        path: examples/helm-example
        helm:
          valueFiles:
          - 'values-{{tenant}}.yaml'
      destination:
        namespace: '{{tenant}}'
```

**Result:** ArgoCD automatically creates 20 Applications! 🎉

---

## 🚀 How to Use ApplicationSet

### Step 1: Create Your Tenant Values Files

You already have (or will create):
```
examples/helm-example/
├── values.yaml              # Defaults
├── values-customer-1.yaml
├── values-customer-2.yaml
├── values-customer-3.yaml
└── ... (17 more)
```

### Step 2: Create ApplicationSet

**Option A: Manual List (Simple & Explicit)**

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
      - tenant: customer-1
        replicas: "3"      # Optional: pass variables
      - tenant: customer-2
        replicas: "5"
      - tenant: customer-3
        replicas: "2"
      # Add all 20 here...
  
  template:
    metadata:
      name: '{{tenant}}-app'
    spec:
      project: default
      source:
        repoURL: https://github.com/haviv/argocd-demo
        path: examples/helm-example
        helm:
          valueFiles:
          - 'values-{{tenant}}.yaml'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{tenant}}'
      syncPolicy:
        automated: {}
        syncOptions:
        - CreateNamespace=true
```

**Deploy it:**
```bash
kubectl apply -f applicationset-tenants.yaml
```

**BOOM! 💥** ArgoCD creates all 20 Applications automatically!

---

**Option B: Git File Discovery (Fully Automatic!)**

This is even better - it auto-discovers values files!

```yaml
# applicationset-auto-discover.yaml
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
      name: '{{path.basenameNormalized}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/haviv/argocd-demo
        path: examples/helm-example
        helm:
          valueFiles:
          - '{{path.filename}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{path.basenameNormalized}}'
      syncPolicy:
        automated: {}
        syncOptions:
        - CreateNamespace=true
```

**Magic! 🪄**
- Add `values-customer-21.yaml` to Git
- Push to GitHub
- ArgoCD automatically creates `customer-21-app`
- Deploys customer 21 automatically!

**No manual commands needed!**

---

## 🔄 What About Existing 20 Customers?

### Q: "I already have 20 customers running. Will ArgoCD auto-manage them?"

**Answer:** Not automatically. You need to tell ArgoCD to manage them.

### Two Scenarios:

#### **Scenario A: They're NOT in ArgoCD yet**

You have 20 customers deployed with `kubectl` or manually.

**To bring them under ArgoCD management:**

1. **Create values files for each:**
   ```bash
   # For each customer, create a values file
   ./add-tenant-helm.sh  # Run 20 times
   # OR create them manually
   ```

2. **Apply ApplicationSet:**
   ```bash
   kubectl apply -f applicationset-tenants.yaml
   ```

3. **ArgoCD takes over:**
   - Creates Applications for all 20
   - Syncs Git → Cluster
   - May recreate resources (depending on sync policy)

#### **Scenario B: They're already in ArgoCD**

You manually created 20 Applications:

**To convert to ApplicationSet:**

1. **Delete individual Applications:**
   ```bash
   argocd app delete customer-1-app --cascade=false
   argocd app delete customer-2-app --cascade=false
   # --cascade=false keeps resources running!
   ```

2. **Apply ApplicationSet:**
   ```bash
   kubectl apply -f applicationset-tenants.yaml
   ```

3. **ApplicationSet recreates all Applications**
   - No downtime!
   - Resources keep running
   - Now managed by ApplicationSet

---

## 📊 Comparison

| Approach | Create 20 Apps | Add New Customer | Update All |
|----------|---------------|------------------|------------|
| **Manual** | 20 commands | 1 command | 20 updates |
| **ApplicationSet (List)** | 1 YAML | Add to list | 1 update |
| **ApplicationSet (Git)** | 1 YAML | Add values file | Automatic! |

---

## 🎯 Real-World Example: 100 Customers

### Directory Structure:
```
tenants/
├── applicationset.yaml          # ← One file manages all!
└── values/
    ├── values-customer-001.yaml
    ├── values-customer-002.yaml
    ├── ...
    └── values-customer-100.yaml
```

### ApplicationSet:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: production-tenants
spec:
  generators:
  - git:
      repoURL: https://github.com/haviv/argocd-demo
      files:
      - path: "tenants/values/values-*.yaml"
  
  template:
    metadata:
      name: '{{path.basenameNormalized}}'
    spec:
      source:
        repoURL: https://github.com/haviv/argocd-demo
        path: helm-chart
        helm:
          valueFiles:
          - '../tenants/values/{{path.filename}}'
      destination:
        namespace: '{{path.basenameNormalized}}'
      syncPolicy:
        automated: {}
```

**Benefits:**
- ✅ **One ApplicationSet** = 100 Applications
- ✅ **Add customer 101** = Add values file, push to Git, done!
- ✅ **Update all customers** = Update helm-chart, push, all sync!
- ✅ **Centralized management** = View all tenants in ArgoCD UI
- ✅ **Scalable** = 1000 customers? No problem!

---

## 🚀 Get Started Now

### Step 1: Look at the examples
```bash
cd examples/
cat applicationset-example.yaml
cat applicationset-git-discovery.yaml
```

### Step 2: Create a test ApplicationSet
```bash
# Copy and edit
cp applicationset-example.yaml my-applicationset.yaml
nano my-applicationset.yaml

# Apply it
kubectl apply -f my-applicationset.yaml
```

### Step 3: Watch the magic
```bash
# See ApplicationSet
kubectl get applicationset -n argocd

# See generated Applications
argocd app list

# All your tenants are now managed automatically! 🎉
```

---

## 📚 Advanced Patterns

### Pattern 1: Different Clusters per Tenant
```yaml
generators:
- list:
    elements:
    - tenant: customer-1
      cluster: https://cluster-1.example.com
    - tenant: customer-2
      cluster: https://cluster-2.example.com

template:
  destination:
    server: '{{cluster}}'
```

### Pattern 2: Matrix Generator (Multiple Environments × Tenants)
```yaml
generators:
- matrix:
    generators:
    - list:
        elements:
        - tenant: customer-1
        - tenant: customer-2
    - list:
        elements:
        - env: dev
        - env: prod

template:
  metadata:
    name: '{{tenant}}-{{env}}'
  source:
    helm:
      valueFiles:
      - 'values-{{tenant}}-{{env}}.yaml'
```

This creates:
- customer-1-dev
- customer-1-prod
- customer-2-dev
- customer-2-prod

Automatically!

---

## 🎓 Key Takeaways

### Q: Do I need to run `argocd app create` for each tenant?

**A: Without ApplicationSet:** Yes, manually 😫

**A: With ApplicationSet:** No! One YAML = All Applications ✅

### Q: Will ArgoCD auto-manage my 20 existing customers?

**A:** No, not automatically. But:
1. Create ApplicationSet once
2. It generates all 20 Applications
3. ArgoCD takes over management
4. Future customers: Just add values file!

### The Magic Formula:

```
1 ApplicationSet 
+ 20 values files 
= 20 Applications automatically managed by ArgoCD
```

**Add customer 21?**
Just add `values-customer-21.yaml` → Automatic! 🎉

---

**Try it now:**
```bash
kubectl apply -f examples/applicationset-example.yaml
```

Watch ArgoCD create multiple Applications from one YAML file! 🚀

