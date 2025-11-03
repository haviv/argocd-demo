# Kustomize Multi-Tenant Example

This example shows how to manage multiple tenants with centralized base configuration.

## Structure

```
kustomize-example/
├── base/                       # ← Common configuration for ALL tenants
│   ├── deployment.yaml         # Base deployment
│   ├── service.yaml           # Base service
│   └── kustomization.yaml     # Kustomize config
└── overlays/                   # ← Tenant-specific overrides
    ├── tenant-a/
    │   └── kustomization.yaml  # Tenant A: 3 replicas, 128Mi memory
    └── tenant-b/
        └── kustomization.yaml  # Tenant B: 5 replicas, 256Mi memory
```

## How It Works

1. **Base**: Contains common configs that all tenants share
2. **Overlays**: Override specific values per tenant

## Test It Locally

```bash
cd examples/kustomize-example

# See what Tenant A gets
kubectl kustomize overlays/tenant-a

# See what Tenant B gets
kubectl kustomize overlays/tenant-b

# Compare them side-by-side
diff <(kubectl kustomize overlays/tenant-a) <(kubectl kustomize overlays/tenant-b)
```

## What Each Tenant Gets

### Tenant A
- **Namespace**: tenant-a
- **Name**: tenant-a-myapp
- **Replicas**: 3
- **Memory**: 128Mi request, 256Mi limit
- **Env vars**: ENVIRONMENT=production, TENANT=tenant-a

### Tenant B
- **Namespace**: tenant-b
- **Name**: tenant-b-myapp
- **Replicas**: 5
- **Memory**: 256Mi request, 512Mi limit
- **Env vars**: ENVIRONMENT=production, TENANT=tenant-b

## Deploy with ArgoCD

Create one Application per tenant:

```bash
# Tenant A
argocd app create tenant-a-app \
  --repo https://github.com/haviv/argocd-demo \
  --path examples/kustomize-example/overlays/tenant-a \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace tenant-a \
  --sync-policy automated

# Tenant B
argocd app create tenant-b-app \
  --repo https://github.com/haviv/argocd-demo \
  --path examples/kustomize-example/overlays/tenant-b \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace tenant-b \
  --sync-policy automated
```

## Adding a New Tenant

```bash
# 1. Copy an existing overlay
cp -r overlays/tenant-a overlays/tenant-c

# 2. Edit overlays/tenant-c/kustomization.yaml
# Change namespace, namePrefix, labels, and values

# 3. Commit and push
git add overlays/tenant-c
git commit -m "Add tenant-c"
git push

# 4. Create ArgoCD application
argocd app create tenant-c-app \
  --repo https://github.com/haviv/argocd-demo \
  --path examples/kustomize-example/overlays/tenant-c \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace tenant-c \
  --sync-policy automated
```

## Benefits

✅ **DRY**: One base config, many tenants
✅ **Easy updates**: Change base, all tenants get it
✅ **Customizable**: Each tenant can override what they need
✅ **GitOps**: All changes tracked in Git
✅ **Scalable**: Add new tenants by copying a directory

## Alternative: Central Values File

For simpler cases, you can use a ConfigMap-based approach:

```yaml
# central-config.yaml
tenant-a:
  replicas: 3
  memory: 128Mi
  
tenant-b:
  replicas: 5
  memory: 256Mi
```

Then use Kustomize's `replacements` feature to inject these values.

