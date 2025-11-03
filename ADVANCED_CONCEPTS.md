# ArgoCD Advanced Concepts

## 🔍 How Does ArgoCD Know What to Sync?

### The Application Manifest

When you ran `argocd app create`, it created an **Application** resource. Let me show you:

```bash
argocd app get demo-app -o yaml
```

This creates a manifest like:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
spec:
  project: default
  
  # SOURCE: Where to get the configs
  source:
    repoURL: https://github.com/haviv/argocd-demo
    targetRevision: HEAD  # or specific branch/tag
    path: demo-app/k8s    # ← This directory!
  
  # DESTINATION: Where to deploy
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  
  # SYNC POLICY: How to sync
  syncPolicy:
    automated:
      prune: true      # Delete resources not in Git
      selfHeal: true   # Revert manual changes
    syncOptions:
    - CreateNamespace=true
```

### How ArgoCD Syncs:

1. **Polls GitHub** every 3 minutes (default)
2. **Compares** Git state vs Cluster state
3. **Detects differences** (OutOfSync)
4. **Auto-syncs** if automated sync is enabled
5. **Applies** all YAML files in the specified path

### What Gets Synced?

ArgoCD reads **all YAML/JSON files** in the `path` you specified:
```
demo-app/k8s/
├── configmap.yaml   ← Synced
├── deployment.yaml  ← Synced
└── service.yaml     ← Synced
```

**Important:** ArgoCD doesn't know about changes on your disk! Only changes pushed to Git!

---

## 🎯 Centralized Configuration Management

You're asking THE KEY question for production systems! There are 3 main approaches:

### **Approach 1: Kustomize Overlays** (Recommended for Multi-Environment)

Best for: Different environments (dev/staging/prod) or tenants

```
├── base/                        # Common configs
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
├── overlays/
│   ├── tenant-a/               # Tenant A specific
│   │   ├── kustomization.yaml
│   │   └── values.yaml
│   ├── tenant-b/               # Tenant B specific
│   │   ├── kustomization.yaml
│   │   └── values.yaml
│   └── production/
│       ├── kustomization.yaml
│       └── replicas.yaml
```

### **Approach 2: Helm Charts** (Recommended for Complex Apps)

Best for: Complex applications with many configurable parameters

```
myapp/
├── Chart.yaml
├── values.yaml              # Default values
├── values-tenant-a.yaml     # Tenant A overrides
├── values-tenant-b.yaml     # Tenant B overrides
└── templates/
    ├── deployment.yaml      # Uses {{ .Values.replicas }}
    ├── service.yaml
    └── configmap.yaml
```

### **Approach 3: ConfigMap + Kustomize** (Simple Multi-Tenant)

Best for: Simple multi-tenant where only a few values change

```
├── base/
│   ├── deployment.yaml
│   └── kustomization.yaml
└── tenants/
    ├── tenant-a/
    │   ├── config.yaml      # Tenant A values
    │   └── kustomization.yaml
    └── tenant-b/
        ├── config.yaml      # Tenant B values
        └── kustomization.yaml
```

---

## 📊 Let me show you practical examples...


