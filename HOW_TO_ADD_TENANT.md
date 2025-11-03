# How to Add a New Tenant

## 🎯 Quick Answer

**For Helm (you're looking at this):**
1. Copy a values file: `cp values-tenant-a.yaml values-tenant-c.yaml`
2. Edit the new file with tenant-specific values
3. Commit and push to Git
4. Create ArgoCD Application pointing to the new values file

**For Kustomize:**
1. Copy an overlay directory: `cp -r overlays/tenant-a overlays/tenant-c`
2. Edit the kustomization.yaml with tenant-specific values
3. Commit and push to Git
4. Create ArgoCD Application pointing to the new overlay

Let me show you both in detail...

---

## 📋 Method 1: Helm (Recommended for Complex Apps)

### Step 1: Create Tenant Values File

```bash
cd examples/helm-example

# Copy an existing tenant as a template
cp values-tenant-a.yaml values-tenant-c.yaml

# Edit it
nano values-tenant-c.yaml
```

### Step 2: Configure Tenant C Values

Edit `values-tenant-c.yaml`:

```yaml
# Tenant C specific values
replicaCount: 2                    # ← Change as needed

resources:
  requests:
    memory: "64Mi"                 # ← Adjust for tenant needs
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "200m"

env:
  ENVIRONMENT: "production"
  TENANT_NAME: "tenant-c"          # ← Important: unique name!
  LOG_LEVEL: "info"
  DATABASE_URL: "postgres://tenant-c-db:5432"  # ← Tenant-specific DB
  API_KEY: "tenant-c-secret-key"   # ← Tenant-specific secrets

tenant:
  name: "tenant-c"                 # ← Must be unique!
  namespace: "tenant-c"            # ← Will be created
```

### Step 3: Test Locally (Optional but Recommended)

```bash
# See what will be deployed
helm template tenant-c . -f values-tenant-c.yaml

# Validate it
helm template tenant-c . -f values-tenant-c.yaml | kubectl apply --dry-run=client -f -
```

### Step 4: Commit and Push to Git

```bash
git add values-tenant-c.yaml
git commit -m "Add tenant-c configuration"
git push
```

### Step 5: Create ArgoCD Application

**Option A: Using ArgoCD CLI**

```bash
argocd app create tenant-c-app \
  --repo https://github.com/haviv/argocd-demo \
  --path examples/helm-example \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace tenant-c \
  --helm-set-file values=values-tenant-c.yaml \
  --sync-policy automated \
  --sync-option CreateNamespace=true

# Sync it
argocd app sync tenant-c-app
```

**Option B: Using ArgoCD UI**

1. Open: https://localhost:8080
2. Click **"+ NEW APP"**
3. Fill in:
   - **Application Name**: `tenant-c-app`
   - **Project**: `default`
   - **Sync Policy**: `Automatic`
   - **Repository URL**: `https://github.com/haviv/argocd-demo`
   - **Path**: `examples/helm-example`
   - **Cluster URL**: `https://kubernetes.default.svc`
   - **Namespace**: `tenant-c`
   - **Helm Values Files**: `values-tenant-c.yaml`
4. Click **CREATE**

### Step 6: Verify Deployment

```bash
# Check ArgoCD status
argocd app get tenant-c-app

# Check Kubernetes resources
kubectl get all -n tenant-c

# Check pods are running
kubectl get pods -n tenant-c
```

**Done! Tenant C is deployed! 🎉**

---

## 📋 Method 2: Kustomize (Simpler, No Templating)

### Step 1: Copy Existing Overlay

```bash
cd examples/kustomize-example

# Copy tenant-a as template
cp -r overlays/tenant-a overlays/tenant-c
```

### Step 2: Edit Tenant C Configuration

Edit `overlays/tenant-c/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: tenant-c              # ← Change namespace

bases:
  - ../../base

namePrefix: tenant-c-            # ← Change prefix

commonLabels:
  tenant: tenant-c               # ← Change label

replicas:
  - name: myapp
    count: 4                     # ← Set replica count

patches:
  - patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/env/0/value
        value: "production"
      - op: replace
        path: /spec/template/spec/containers/0/env/1/value
        value: "tenant-c"        # ← Tenant name
      - op: replace
        path: /spec/template/spec/containers/0/resources/requests/memory
        value: "96Mi"            # ← Memory size
      - op: replace
        path: /spec/template/spec/containers/0/resources/limits/memory
        value: "192Mi"
    target:
      kind: Deployment
      name: myapp
```

### Step 3: Test Locally

```bash
# See what will be deployed
kubectl kustomize overlays/tenant-c

# Validate
kubectl kustomize overlays/tenant-c | kubectl apply --dry-run=client -f -
```

### Step 4: Commit and Push

```bash
git add overlays/tenant-c
git commit -m "Add tenant-c overlay"
git push
```

### Step 5: Create ArgoCD Application

```bash
argocd app create tenant-c-kustomize \
  --repo https://github.com/haviv/argocd-demo \
  --path examples/kustomize-example/overlays/tenant-c \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace tenant-c \
  --sync-policy automated \
  --sync-option CreateNamespace=true

# Sync it
argocd app sync tenant-c-kustomize
```

### Step 6: Verify

```bash
argocd app get tenant-c-kustomize
kubectl get all -n tenant-c
```

**Done! 🎉**

---

## 🚀 Automated Script (Do It All At Once)

I'll create a script that does this automatically...


