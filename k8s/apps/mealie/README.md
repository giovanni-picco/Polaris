# Mealie

> [!NOTE]
> **Disabled.** Not listed in `k8s/apps/kustomization.yaml`; its volume has been deleted. Kept as a starting point.

Recipe manager and meal planner.

| | |
| --- | --- |
| **Namespace** | `mealie` |
| **Image** | `ghcr.io/mealie-recipes/mealie` |
| **URL** | `https://mealie.${CLUSTER_DOMAIN}` |
| **Auth** | OIDC with authentik (`sso-client` from Bitwarden) |
| **Volume** | `mealie-config` (20 Gi, `longhorn-default`), SQLite inside |

## Re-enabling

Add `./mealie` to `k8s/apps/kustomization.yaml`, preferably after moving `mealie-config` to the [`volsync` component](../../components/README.md#volsync).
