# Intel GPU Plugin

Exposes the Intel iGPU of the nodes as the `gpu.intel.com/i915` resource, used by [Jellyfin](../../apps/jellyfin/README.md) for hardware transcoding (Quick Sync).

| | |
| --- | --- |
| **Namespace** | `intel-gpu-plugin` |
| **Source** | upstream [intel-device-plugins-for-kubernetes](https://github.com/intel/intel-device-plugins-for-kubernetes), pinned tag |
| **Requirement** | Talos `siderolabs/i915` system extension (see [talos/](../../../talos/README.md)) |

No Helm chart: Flux pulls the upstream repository directly (`GitRepository`, only `deployments/gpu_plugin` is fetched) and applies its kustomization into this namespace, patching the DaemonSet with `-shared-dev-num=5` so up to five pods can share one GPU.

```sh
kubectl get nodes -o custom-columns=NODE:.metadata.name,GPU:.status.allocatable.gpu\\.intel\\.com/i915
```

To upgrade, bump `spec.ref.tag` in `ks.yaml`.
