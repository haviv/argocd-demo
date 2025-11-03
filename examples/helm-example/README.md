# Helm Multi-Tenant Example

This example shows how to use Helm charts for multi-tenant deployment with centralized configuration.

## Structure

```
helm-example/
├── Chart.yaml              # Helm chart metadata
├── values.yaml             # ← DEFAULT values (all tenants)
├── values-tenant-a.yaml    # ← Tenant A overrides
├── values-tenant-b.yaml    # ← Tenant B overrides
└── templates/
    ├── deployment.yaml     # Uses {{ .Values.* }}
    └── service.yaml        # Uses {{ .Values.* }}
```

## How It Works

1. **values.yaml**: Default values for all parameters
2. **values-tenant-X.yaml**: Override specific values per tenant
3. **templates/**: Use Go templating to inject values

## Test Locally

```bash
cd examples/helm-example

# See what Tenant A gets
helm template tenant-a . -f values-tenant-a.yaml

# See what Tenant B gets
helm template tenant-b . -f values-tenant-b.yaml

# Install locally (if you have a cluster)
helm install tenant-a . -f values-tenant-a.yaml --create-namespace -n tenant-a
```

## What Each Tenant Gets

### Tenant A (values-tenant-a.yaml)
```yaml
replicas: 3
memory: 128Mi → 256Mi
env:
  ENVIRONMENT: production
  TENANT_NAME: tenant-a
  DATABASE_URL: postgres://tenant-a-db:5432
```

### Tenant B (values-tenant-b.yaml)
```yaml
replicas: 5
memory: 256Mi → 512Mi
env:
  ENVIRONMENT: production
  TENANT_NAME: tenant-b
  DATABASE_URL: postgres://tenant-b-db:5432
  CACHE_SIZE: 1024  # Extra variable!
```

## Deploy with ArgoCD

### Method 1: Multiple Applications

```bash
# Tenant A
argocd app create tenant-a-helm \
  --repo https://github.com/haviv/argocd-demo \
  --path examples/helm-example \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace tenant-a \
  --helm-set-file values=values-tenant-a.yaml \
  --sync-policy automated

# Tenant B
argocd app create tenant-b-helm \
  --repo https://github.com/haviv/argocd-demo \
  --path examples/helm-example \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace tenant-b \
  --helm-set-file values=values-tenant-b.yaml \
  --sync-policy automated
```

### Method 2: ApplicationSet (Advanced)

Create one ApplicationSet that generates apps for all tenants:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: multi-tenant-apps
spec:
  generators:
  - list:
      elements:
      - tenant: tenant-a
        replicas: "3"
      - tenant: tenant-b
        replicas: "5"
  template:
    metadata:
      name: '{{tenant}}-helm'
    spec:
      project: default
      source:
        repoURL: https://github.com/haviv/argocd-demo
        path: examples/helm-example
        helm:
          valueFiles:
          - values-{{tenant}}.yaml
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{tenant}}'
      syncPolicy:
        automated: {}
```

## Adding a New Tenant

```bash
# 1. Copy an existing values file
cp values-tenant-a.yaml values-tenant-c.yaml

# 2. Edit values-tenant-c.yaml with new values
# Change tenant name, resources, env vars, etc.

# 3. Commit and push
git add values-tenant-c.yaml
git commit -m "Add tenant-c configuration"
git push

# 4. Create ArgoCD application
argocd app create tenant-c-helm \
  --repo https://github.com/haviv/argocd-demo \
  --path examples/helm-example \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace tenant-c \
  --helm-set-file values=values-tenant-c.yaml \
  --sync-policy automated
```

## Benefits

✅ **Powerful templating**: Go templates for complex logic
✅ **Centralized defaults**: One values.yaml for common config
✅ **Easy overrides**: Per-tenant values files
✅ **Helm ecosystem**: Use existing Helm charts
✅ **Type-safe**: Helm can validate values

## Comparison: Helm vs Kustomize

| Feature | Helm | Kustomize |
|---------|------|-----------|
| Templating | Full Go templates | Strategic merge patches |
| Learning curve | Steeper | Easier |
| Flexibility | Very high | Medium |
| Built into kubectl | No | Yes |
| Package management | Yes | No |
| Best for | Complex apps | Simple overlays |

## Real-World Pattern

Many companies use BOTH:
1. **Helm** for packaging and templating
2. **Kustomize** for environment-specific overlays

```
helm-charts/
  myapp/              # Helm chart
    templates/
    values.yaml
overlays/
  dev/
    kustomization.yaml    # Points to Helm chart
    values-dev.yaml
  prod/
    kustomization.yaml
    values-prod.yaml
```

This gives you the best of both worlds!

