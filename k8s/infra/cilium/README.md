# Cilium

eBPF networking for the cluster: CNI, full kube-proxy replacement and LoadBalancer IPs announced on the LAN with L2 (ARP), so no MetalLB is needed.

| | |
| --- | --- |
| **Namespace** | `kube-system` |
| **Chart** | `cilium` |
| **LoadBalancer pool** | `${CLUSTER_IP_RANGE}` = `10.10.5.192/26` |
| **Metrics** | agent, operator, Envoy and Hubble, see [prometheus/monitors](../../core/prometheus/README.md) |

## Structure

| Folder | Flux Kustomization | Content |
| --- | --- | --- |
| `app/` | `infra-cilium-app` | HelmRelease |
| `config/` | `infra-cilium-config` | `CiliumLoadBalancerIPPool` and `CiliumL2AnnouncementPolicy` (need the Cilium CRDs) |

## Configuration highlights

- `kubeProxyReplacement: true`, with the API server reached through the Talos VIP `10.10.5.10:6443` (Talos runs with `cluster.proxy.disabled`).
- `bpf.masquerade`, `ipam.mode: kubernetes`.
- Talos specifics: cgroup v2 already mounted at `/sys/fs/cgroup`, and an explicit list of agent capabilities (Talos forbids `SYS_MODULE`).
- `l2announcements` + `externalIPs`: Services of type `LoadBalancer` get an IP from the pool and the owning node answers ARP for it. Traefik is `10.10.5.192`.
- Metrics endpoints for agent and operator, plus a small set of Hubble flow metrics (dns, drop, tcp, flow, port-distribution, icmp). The monitors live in `core` so this layer does not depend on Prometheus.

## Bootstrap

Cilium is the only component installed by hand: nodes need a CNI before Flux can run. The one-off install uses [`talos/cilium/values.yaml`](../../../talos/cilium/values.yaml), then Flux adopts the release. See [talos/README.md](../../../talos/README.md).

> [!WARNING]
> Keep `talos/cilium/values.yaml` in sync with the HelmRelease values for anything required to boot (kube-proxy replacement, API endpoint, cgroup, capabilities): it is what a rebuilt cluster starts with.

## Maintenance

```sh
kubectl -n kube-system exec ds/cilium -- cilium status --brief
kubectl -n kube-system exec ds/cilium -- cilium-health status
```

Upgrades come from Renovate. Before a Kubernetes minor upgrade, check that the Cilium version supports it ([compatibility](https://docs.cilium.io/en/stable/network/kubernetes/requirements/)): it is the component that gates Kubernetes upgrades here.
