# Planka

> [!NOTE]
> **Disabled.** Not listed in `k8s/apps/kustomization.yaml`; its volumes have been deleted. Kept as a starting point.

Kanban boards.

| | |
| --- | --- |
| **Namespace** | `planka` |
| **Image** | `ghcr.io/plankanban/planka` |
| **URL** | `https://planka.${CLUSTER_DOMAIN}` |
| **Auth** | OIDC with authentik (`sso-client`), SMTP for notifications |
| **Database** | CNPG `planka-pg` (`database/`, Flux Kustomization `apps-planka-db`) |
| **Volume** | `planka-data` (10 Gi, `longhorn-default`) — attachments |

## Re-enabling

1. Add `./planka` to `k8s/apps/kustomization.yaml`.
2. Bring the database in line with the other clusters: storage class `longhorn-database`, `enablePDB: false`, the [`cnpg-backup`](../../components/README.md#cnpg-backup) component and a dependency on `core-cnpg-barman` (see [cnpg](../../core/cnpg/README.md)).
3. Move `planka-data` to the [`volsync` component](../../components/README.md#volsync).
