# Snapshot Controller

CSI external-snapshotter: the `VolumeSnapshot` CRDs and controller. Required by [VolSync](../volsync/README.md) to take point-in-time copies of volumes before backing them up.

| | |
| --- | --- |
| **Namespace** | `kube-system` |
| **Chart** | `snapshot-controller` (piraeus) |
| **VolumeSnapshotClass** | `longhorn-snapclass` — Longhorn in-cluster snapshots (`type: snap`) |

## Structure

| Folder | Flux Kustomization | Content |
| --- | --- | --- |
| `app/` | `infra-snapshot-controller-app` | HelmRelease (CRDs + controller); depends on Longhorn |
| `class/` | `infra-snapshot-controller-class` | `VolumeSnapshotClass` |

The class is a separate Kustomization because the chart ships its CRDs as regular templates: a `VolumeSnapshotClass` in the same release cannot be validated at install time.
