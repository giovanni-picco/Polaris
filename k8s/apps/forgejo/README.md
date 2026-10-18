# Forgejo

> [!NOTE]
> **Disabled.** Not listed in `k8s/apps/kustomization.yaml`; its volumes have been deleted. Kept as a starting point.

Self-hosted Git forge.

| | |
| --- | --- |
| **Namespace** | `forgejo` |
| **Image** | `data.forgejo.org/forgejo/forgejo` (rootless) |
| **URL** | `https://git.${CLUSTER_DOMAIN}`, SSH on port 22 through the Traefik `git-ssh` entrypoint (`IngressRouteTCP`) |
| **Database** | SQLite (WAL mode) on the data volume |
| **Volumes** | `forgejo-config` (4 Gi), `forgejo-data` (20 Gi), `longhorn-critical` |

Configuration is passed as `FORGEJO__section__KEY` environment variables from the `forgejo-config` ConfigMap (server/SSH, database, security, service settings).

## Re-enabling

1. Add `./forgejo` to `k8s/apps/kustomization.yaml`.
2. Consider switching the two PVCs to the [`volsync` component](../../components/README.md#volsync) (one Flux Kustomization per volume, as done for [paperless](../paperless/README.md)).
