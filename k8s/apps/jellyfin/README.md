# Jellyfin

Media server for the library managed by the [arr-stack](../arr-stack/README.md), with hardware transcoding on the Intel iGPU.

| | |
| --- | --- |
| **Namespace** | `jellyfin` |
| **Image** | `jellyfin/jellyfin` |
| **URL** | `https://jellyfin.${CLUSTER_DOMAIN}` |
| **Auth** | Jellyfin accounts |
| **Config** | `jellyfin-config` (5 Gi), backed up with [`volsync`](../../components/README.md#volsync) daily at 04:30 |
| **Media** | NFS `${NAS_DOMAIN}:/volume1/media/media`, read by the pod |
| **GPU** | `gpu.intel.com/i915: 1` from the [Intel GPU plugin](../../infra/intel-gpu-plugin/README.md) |

- An init container waits for `system.xml` and switches `EnableMetrics` on, so `/metrics` is available on port 8096 (not scraped yet).
- The NetworkPolicy admits Traefik, Prometheus and [Seerr](../seerr/README.md).
- Prefers the worker node (`node-role/worker`), where the media network and the GPU are.
- `/cache` (transcodes) is an `emptyDir`.
