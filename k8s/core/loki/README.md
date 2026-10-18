# Loki

Log storage for every pod in the cluster. Grafana Alloy runs on each node, tails the container logs through the Kubernetes API and pushes them to Loki.

| | |
| --- | --- |
| **Namespace** | `loki` |
| **Charts** | `loki` (single binary), `alloy` (DaemonSet) |
| **Storage** | filesystem on a 50 Gi `longhorn-default` volume, no Longhorn backups (regenerable) |
| **Retention** | 30 days |
| **Endpoint** | `http://loki.loki.svc:3100` |
| **Metrics** | Loki and Alloy, see [prometheus/monitors](../prometheus/README.md) |

## Structure

| Folder | Flux Kustomization | Content |
| --- | --- | --- |
| `app/` | `core-loki-app` | Loki in `SingleBinary` mode, TSDB schema v13, all scalable targets and caches disabled |
| `alloy/` | `core-loki-alloy` | Alloy pipeline: discover pods → relabel → ship to Loki |

Each log line carries `namespace`, `pod`, `container`, `node` and `job` (`<namespace>/<pod>`) labels:

```logql
{namespace="paperless", container="paperless"} |= "error"
```

> [!NOTE]
> The Loki datasource is not provisioned from Git: add it in Grafana (URL above) or through the kube-prometheus-stack `additionalDataSources` values.
