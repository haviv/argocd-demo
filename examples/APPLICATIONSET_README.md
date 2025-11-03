# ApplicationSet Examples

These examples show how to manage multiple tenants with ONE ApplicationSet instead of creating individual Applications.

## Files

- `applicationset-example.yaml` - Manual list of tenants
- `applicationset-git-discovery.yaml` - Auto-discover tenants from Git

## Quick Start

```bash
# View the examples
cat applicationset-example.yaml
cat applicationset-git-discovery.yaml

# Apply one (when you have ArgoCD running)
kubectl apply -f applicationset-example.yaml

# Watch Applications being created
argocd app list

# See the ApplicationSet
kubectl get applicationset -n argocd
```

## When to Use

✅ Use ApplicationSet when you have:
- Multiple similar tenants/customers
- Multiple environments (dev/staging/prod)
- 3+ Applications with similar config
- Need to scale to many tenants

❌ Don't use ApplicationSet for:
- Single application
- Completely different apps
- Learning basics (start with regular Applications first)

See APPLICATIONSET_GUIDE.md for full documentation!
