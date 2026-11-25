# Flux notifications

Forwards Flux reconcile errors to [Alertmanager](../prometheus/README.md#alerting), which sends them to Telegram together with the Prometheus alerts.

| | |
| --- | --- |
| **Namespace** | `flux-system` |
| **Provider** | `alertmanager`, type `alertmanager` → `kube-prometheus-stack-alertmanager.prometheus:9093` |
| **Alert** | `flux-errors`, `eventSeverity: error` |
| **Depends on** | `core-prometheus-stack-app` |

## Event sources

- `GitRepository`, `OCIRepository`, `HelmRepository`, `Kustomization`: all objects in `flux-system`.
- `HelmRelease`: one entry per namespace, because Alert sources have no namespace wildcard. **When an app adds a HelmRelease in a new namespace, add it to [alert.yaml](app/alert.yaml).**

The child Kustomizations do not use `wait`, so a failed HelmRelease does not fail its Kustomization: without the per-namespace entries those failures would go unnoticed.

`exclusionList` drops transient errors (`context deadline exceeded`, `connection refused`) that the next reconcile fixes.

## Behaviour in Alertmanager

Each event becomes an alert named `Flux<Kind><Reason>` (e.g. `FluxHelmReleaseUpgradeFailed`) with labels `kind`, `name`, `namespace`, `reportingcontroller` and the event metadata. Events have no `endsAt`, so the alert expires after `resolve_timeout` (1h) without new errors; it is routed to `telegram-flux`, which does not send "resolved" messages.

```sh
kubectl -n flux-system get alert,provider
kubectl -n flux-system logs deploy/notification-controller --tail=50
```
