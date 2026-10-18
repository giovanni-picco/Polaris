# VolSync

Operator that backs up PVCs with restic and acts as a volume populator to restore them. Apps use it through the [`volsync` component](../../components/README.md#volsync); that page also holds the backup and restore runbooks.

| | |
| --- | --- |
| **Namespace** | `volsync-system` |
| **Chart** | `volsync` (backube) |
| **Depends on** | `infra-snapshot-controller-app` |
| **Metrics** | controller (behind kube-rbac-proxy), see [prometheus/monitors](../../core/prometheus/README.md) |

The chart renders its own ServiceMonitor only if the Prometheus CRDs already exist at install time, which depends on ordering; a post-renderer removes it and the monitor is defined in `core/prometheus/monitors` instead.

```sh
kubectl get replicationsource,replicationdestination -A
```
