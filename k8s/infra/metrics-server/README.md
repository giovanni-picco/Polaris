# metrics-server

Resource metrics API: powers `kubectl top` and HorizontalPodAutoscalers.

| | |
| --- | --- |
| **Namespace** | `kube-system` |
| **Chart** | `metrics-server` |

Runs with `--kubelet-insecure-tls`: Talos kubelets serve a self-signed certificate. The alternative is enabling kubelet serving-certificate rotation in Talos and approving the CSRs (e.g. with kubelet-csr-approver).

```sh
kubectl top nodes
kubectl top pods -A --sort-by=memory
```
