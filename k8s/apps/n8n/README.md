# n8n

> [!NOTE]
> **Disabled.** Not listed in `k8s/apps/kustomization.yaml`; its volumes have been deleted. Kept as a starting point.

Workflow automation.

| | |
| --- | --- |
| **Namespace** | `n8n` |
| **Image** | `docker.n8n.io/n8nio/n8n` |
| **URL** | `https://n8n.${CLUSTER_DOMAIN}` |
| **Auth** | OIDC with authentik (`sso-client` from Bitwarden) |
| **Database** | CNPG `n8n-pg` (`database/`, Flux Kustomization `apps-n8n-db`) |
| **Volume** | `n8n-config` (20 Gi, `longhorn-default`) |

## Re-enabling

1. Add `./n8n` to `k8s/apps/kustomization.yaml`.
2. Bring the database in line with the other clusters: storage class `longhorn-database`, `enablePDB: false`, the [`cnpg-backup`](../../components/README.md#cnpg-backup) component and a dependency on `core-cnpg-barman` (see [cnpg](../../core/cnpg/README.md)).
3. Move `n8n-config` to the [`volsync` component](../../components/README.md#volsync).
