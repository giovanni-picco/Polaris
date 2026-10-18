# Gateway API (not deployed)

Gateway API CRDs from an earlier experiment with Cilium's Gateway API implementation. The folder is **not referenced** by `k8s/infra/kustomization.yaml`, so Flux does not apply it: ingress is handled by [Traefik](../../core/traefik/README.md) with standard `Ingress` objects.

Kept for reference; it can be removed or re-enabled by adding it to the layer kustomization.
