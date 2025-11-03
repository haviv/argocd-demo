# 🏢 Multi-Tenant & Centralized Configuration Guide

## 📋 Your Questions Answered

### Q1: How does ArgoCD know what to sync?

**Answer:** ArgoCD uses an **Application** resource that tells it:

1. **WHERE** to get configs (Git repo + path)
2. **WHAT** to deploy (all YAML files in that path)
3. **HOW** to sync (manual vs automatic)
4. **WHERE** to deploy (cluster + namespace)

```yaml
# This is created when you run: argocd app create
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
spec:
  source:
    repoURL: https://github.com/haviv/argocd-demo  # ← Git repo
    path: demo-app/k8s                              # ← Directory to sync
    targetRevision: HEAD                             # ← Branch/tag
  destination:
    server: https://kubernetes.default.svc           # ← Cluster
    namespace: default                               # ← Namespace
  syncPolicy:
    automated:                                       # ← Auto-sync enabled
      prune: true                                    # ← Delete removed resources
      selfHeal: true                                 # ← Revert manual changes
```

**How syncing works:**
1. ArgoCD **polls GitHub every 3 minutes** (configurable)
2. Compares Git state vs Cluster state
3. If different → shows "OutOfSync"
4. If auto-sync enabled → automatically applies changes
5. Applies ALL YAML files in the specified path

### Q2: How to have a central values file for multiple tenants?

**Answer:** There are **3 proven patterns**. I've created examples for all of them!

---

## 🎯 Pattern 1: Kustomize (Recommended for Most Cases)

**Best for:** Multiple tenants/environments with slight variations

### Structure:
```
kustomize-example/
├── base/                    # ← Common config (ONE place!)
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/                # ← Per-tenant overrides
    ├── tenant-a/
    │   └── kustomization.yaml  # 3 replicas, 128Mi memory
    └── tenant-b/
        └── kustomization.yaml  # 5 replicas, 256Mi memory
```

### Try it now:
```bash
cd examples/kustomize-example

# See what each tenant gets
kubectl kustomize overlays/tenant-a
kubectl kustomize overlays/tenant-b

# Compare them
diff <(kubectl kustomize overlays/tenant-a) \
     <(kubectl kustomize overlays/tenant-b)
```

### Benefits:
✅ **One base, many tenants** - Update base → all tenants get it
✅ **Simple** - No complex templating language
✅ **Built into kubectl** - No extra tools needed
✅ **Easy to understand** - Clear what's different per tenant

### Deploy with ArgoCD:
```bash
# Create one Application per tenant
argocd app create tenant-a \
  --repo https://github.com/haviv/argocd-demo \
  --path examples/kustomize-example/overlays/tenant-a \
  --dest-namespace tenant-a \
  --sync-policy automated

argocd app create tenant-b \
  --repo https://github.com/haviv/argocd-demo \
  --path examples/kustomize-example/overlays/tenant-b \
  --dest-namespace tenant-b \
  --sync-policy automated
```

---

## 🎯 Pattern 2: Helm (Recommended for Complex Apps)

**Best for:** Complex applications with many configurable parameters

### Structure:
```
helm-example/
├── Chart.yaml
├── values.yaml              # ← DEFAULT values (central!)
├── values-tenant-a.yaml     # ← Tenant A overrides
├── values-tenant-b.yaml     # ← Tenant B overrides
└── templates/
    ├── deployment.yaml      # Uses {{ .Values.replicas }}
    └── service.yaml
```

### Central Values (values.yaml):
```yaml
# All tenants inherit these defaults
replicaCount: 2
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
env:
  LOG_LEVEL: "info"
  ENVIRONMENT: "development"
```

### Tenant Override (values-tenant-a.yaml):
```yaml
# Only override what's different
replicaCount: 3              # ← Different
resources:
  requests:
    memory: "128Mi"          # ← Different
env:
  ENVIRONMENT: "production"  # ← Different
  TENANT_NAME: "tenant-a"    # ← New variable
  # LOG_LEVEL inherited from values.yaml ✅
```

### Try it now:
```bash
cd examples/helm-example

# See what each tenant gets
helm template tenant-a . -f values-tenant-a.yaml
helm template tenant-b . -f values-tenant-b.yaml
```

### Benefits:
✅ **Powerful templating** - Complex logic possible
✅ **Central defaults** - One values.yaml for everything
✅ **Easy overrides** - Only specify differences
✅ **Ecosystem** - Use existing Helm charts

### Deploy with ArgoCD:
```bash
argocd app create tenant-a-helm \
  --repo https://github.com/haviv/argocd-demo \
  --path examples/helm-example \
  --dest-namespace tenant-a \
  --helm-set-file values=values-tenant-a.yaml \
  --sync-policy automated
```

---

## 🎯 Pattern 3: ApplicationSet (Advanced Multi-Tenant)

**Best for:** Many similar tenants, auto-generate apps

### One YAML creates apps for ALL tenants:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: all-tenants
spec:
  generators:
  - list:
      elements:
      # ← Central tenant list with values!
      - tenant: tenant-a
        replicas: "3"
        memory: "128Mi"
      - tenant: tenant-b
        replicas: "5"
        memory: "256Mi"
      - tenant: tenant-c
        replicas: "2"
        memory: "64Mi"
  template:
    metadata:
      name: '{{tenant}}-app'
    spec:
      source:
        repoURL: https://github.com/haviv/argocd-demo
        path: examples/helm-example
        helm:
          valueFiles:
          - values-{{tenant}}.yaml
      destination:
        namespace: '{{tenant}}'
      syncPolicy:
        automated: {}
```

### Benefits:
✅ **One file** = All tenants
✅ **Auto-generate** applications
✅ **Centralized** tenant list
✅ **DRY** - Don't repeat yourself

---

## 📊 Real-World Example: SaaS Platform

Let's say you have a SaaS platform with 100 customers (tenants):

### Structure:
```
myapp/
├── base/                           # Common app code
│   └── deployment.yaml
├── helm-chart/                     # Helm chart with defaults
│   ├── Chart.yaml
│   ├── values.yaml               # ← CENTRAL defaults
│   └── templates/
├── tenants/
│   ├── tenant-config.yaml        # ← CENTRAL tenant list
│   ├── customer-a.yaml           # Only overrides
│   ├── customer-b.yaml
│   └── ...                       # 100 files
└── applicationset.yaml           # Generates 100 Applications
```

### Central Tenant Config (tenant-config.yaml):
```yaml
# All tenants inherit these
defaults:
  image: myapp:v1.2.3
  replicas: 2
  memory: 128Mi
  features:
    analytics: true
    caching: true

# Per-tenant overrides
tenants:
  customer-a:
    replicas: 5               # High traffic customer
    memory: 512Mi
    features:
      premium: true
  
  customer-b:
    replicas: 2               # Standard customer
    # memory inherited from defaults
    features:
      analytics: false        # Opted out
```

### Benefits of This Approach:

1. **Update all tenants** - Change `defaults.image` → everyone updated
2. **Per-tenant customization** - Override what's needed
3. **Clear overview** - See all tenants in one place
4. **Scalable** - Add tenant = Add 5 lines to YAML
5. **GitOps** - All changes tracked and reviewable

---

## 🎓 Which Pattern Should You Use?

| Scenario | Recommended Pattern |
|----------|-------------------|
| 2-5 environments (dev/staging/prod) | **Kustomize** |
| Simple tenant differences | **Kustomize** |
| Complex app with many parameters | **Helm** |
| Using existing Helm charts | **Helm** |
| Many similar tenants (10+) | **ApplicationSet + Helm** |
| Need templates/logic | **Helm** |
| Want simplicity | **Kustomize** |

### Production Pattern (Many Companies Use):

```
├── helm-chart/              # ← Helm for templating & defaults
├── overlays/                # ← Kustomize for environments
│   ├── dev/
│   ├── staging/
│   └── prod/
└── applicationset.yaml      # ← ArgoCD for automation
```

**Best of all worlds!**

---

## 🚀 Try The Examples

```bash
# Test Kustomize example
cd examples/kustomize-example
kubectl kustomize overlays/tenant-a

# Test Helm example  
cd examples/helm-example
helm template test . -f values-tenant-a.yaml

# See full documentation
cat examples/kustomize-example/README.md
cat examples/helm-example/README.md
```

---

## 📚 Key Takeaways

### How ArgoCD Syncs:
1. ✅ Polls Git every 3 minutes
2. ✅ Compares Git vs Cluster
3. ✅ Auto-syncs if enabled
4. ✅ Only syncs what's in Git (not local files!)

### Centralized Configuration:
1. ✅ **Kustomize** - Base + Overlays pattern
2. ✅ **Helm** - values.yaml + per-tenant overrides
3. ✅ **ApplicationSet** - Generate multiple apps from one config

### Best Practices:
- ✅ One base/default configuration
- ✅ Per-tenant overrides only
- ✅ Version everything in Git
- ✅ Use ArgoCD Applications to deploy
- ✅ Start simple (Kustomize), grow as needed

---

## 🎯 Next Steps

1. Read the example READMEs:
   - `examples/kustomize-example/README.md`
   - `examples/helm-example/README.md`

2. Try them locally:
   ```bash
   kubectl kustomize examples/kustomize-example/overlays/tenant-a
   helm template examples/helm-example -f examples/helm-example/values-tenant-a.yaml
   ```

3. Push to GitHub and deploy with ArgoCD

4. Experiment with adding your own tenant!

---

**Questions?** Check `ADVANCED_CONCEPTS.md` for deep dives!

