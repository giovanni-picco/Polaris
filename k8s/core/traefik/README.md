# Traefik

Ingress controller and the single entry point for HTTP(S) traffic. Exposed as a `LoadBalancer` Service on `10.10.5.192` (Cilium L2).

| | |
| --- | --- |
| **Namespace** | `traefik` |
| **Chart** | `traefik` |
| **Dashboard** | `https://traefik.${CLUSTER_DOMAIN}` |
| **Metrics** | see [prometheus/monitors](../prometheus/README.md) |

## Structure

| Folder | Flux Kustomization | Content |
| --- | --- | --- |
| `app/` | `core-traefik-app` | HelmRelease, dashboard IngressRoute and its certificate |
| `ingresses/` | `core-traefik-ingresses` | Ingresses for the UIs of components deployed before Traefik |

### How apps are exposed

Apps use standard `Ingress` objects with `ingressClassName: traefik` and three annotations:

```yaml
external-dns.alpha.kubernetes.io/hostname: <app>.${CLUSTER_DOMAIN}   # DNS record on UniFi
cert-manager.io/cluster-issuer: letsencrypt                           # TLS certificate
traefik.ingress.kubernetes.io/router.entrypoints: websecure           # HTTPS only
```

Apps without their own login add authentik forward-auth with a `Middleware` in their namespace and:

```yaml
traefik.ingress.kubernetes.io/router.middlewares: <namespace>-authentik@kubernetescrd
```

### `ingresses/` — UIs of lower layers

Components in `infra` cannot depend on Traefik (its CRDs, like `Middleware`, do not exist yet when they deploy). Their Ingresses and middlewares live here instead, one file per component, prefixed with the layer:

| File | Host | Auth |
| --- | --- | --- |
| `infra-longhorn.yaml` | `longhorn.${CLUSTER_DOMAIN}` | authentik forward-auth (proxy provider `longhorn` on the `ak-outpost-traefik` outpost) |

To add one: create `infra-<component>.yaml` with the Ingress (and Middleware if needed) in the component namespace, list it in `ingresses/kustomization.yaml`, and create the matching provider/application in authentik when using forward-auth. Until the provider exists the outpost answers 404, so the page stays closed.

## Configuration highlights

- `web` (80) permanently redirects to `websecure` (443).
- `providers.kubernetesCRD.safeNaming`: collision-safe router names for CRD objects.
- `aliasHeadersStrategy: delete` on every entrypoint.
- A `git-ssh` entrypoint (2222, NodePort 22) is still defined for the disabled [Forgejo](../../apps/forgejo/README.md).

> [!WARNING]
> The dashboard IngressRoute has no authentication middleware: it is reachable by anyone on the LAN or tailnet.
