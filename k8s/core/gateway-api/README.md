# Gateway API (not deployed)

Leftover of an experiment with Cilium's Gateway API implementation. The folder is **not referenced** by `k8s/core/kustomization.yaml`, so Flux does not apply it; ingress is handled by [Traefik](../traefik/README.md).

Kept for reference; it can be removed or re-enabled by adding it to the layer kustomization (together with [`infra/gateway-api`](../../infra/gateway-api/README.md)).
