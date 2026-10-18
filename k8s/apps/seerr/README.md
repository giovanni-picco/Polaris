# Seerr

Request portal for movies and series: Jellyfin users ask for something, Seerr sends it to Sonarr/Radarr in the [arr-stack](../arr-stack/README.md).

| | |
| --- | --- |
| **Namespace** | `seerr` |
| **Image** | `ghcr.io/seerr-team/seerr` |
| **URL** | `https://seerr.${CLUSTER_DOMAIN}` |
| **Auth** | Jellyfin accounts |
| **Config** | `seerr-config` (5 Gi), backed up with [`volsync`](../../components/README.md#volsync) daily at 04:00 |

- `Recreate` strategy: the config volume is `ReadWriteOnce`, a rolling update would leave the new pod waiting for the volume.
- The `seerr` namespace is allowed into `jellyfin` and into `arr-stack` on the Sonarr/Radarr ports.
