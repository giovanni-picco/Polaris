# Talos

Node configuration for the Polaris cluster, generated with [talhelper](https://budimanjojo.github.io/talhelper/) from [`talconfig.yaml`](talconfig.yaml). This folder also holds the one-off Cilium values used at bootstrap.

| | |
| --- | --- |
| **Cluster** | `POLARIS` |
| **Talos / Kubernetes** | v1.14.4 / v1.36.5 |
| **API endpoint** | `https://kube.polarislab.dev:6443` → Talos shared VIP `10.10.5.10` |
| **CNI** | none from Talos: Cilium, installed once by hand then managed by Flux |
| **Image** | Image Factory, secure boot, extensions `siderolabs/i915` (Intel GPU) and `siderolabs/iscsi-tools` (Longhorn) |

## Nodes

| Node | Role | Hardware | IP | Install disk | NIC |
| --- | --- | --- | --- | --- | --- |
| PCP-01 | control plane | HP ProDesk 400 G2 | 10.10.5.11 | `/dev/sdb` | `enp1s0` |
| PCP-02 | control plane | HP ProDesk 400 G2 | 10.10.5.12 | `/dev/sdb` | `enp1s0` |
| PCP-03 | control plane | HP ProDesk 400 G2 | 10.10.5.13 | `/dev/sdb` | `enp1s0` |
| PWR-01 | worker | Minisforum MS-01 | 10.10.5.14 | `/dev/nvme0n1` | `bond0` (LACP `enp87s0` + `enp89s0`) |
| PWR-02 | worker | Minisforum MS-01 | 10.10.5.15 | `/dev/nvme0n1` | `bond0` — *planned, not installed* |

All IPs are DHCP reservations on the UniFi gateway, VLAN 5 (`10.10.5.0/24`). Cilium hands out LoadBalancer IPs from `10.10.5.192/26` on the same VLAN.

## Patches

### Control plane

| Setting | Why |
| --- | --- |
| `cluster.allowSchedulingOnControlPlanes: true` | Only one worker: workloads also run on the control plane nodes |
| `cluster.proxy.disabled: true` | Cilium replaces kube-proxy |
| `controllerManager` / `scheduler` `bind-address: 0.0.0.0` | Let Prometheus scrape them (Talos binds to localhost) |
| `etcd` `listen-metrics-urls: http://0.0.0.0:2381` | etcd metrics for Prometheus |

### Workers

Label `node-role/worker: "true"`, used by apps to prefer the worker node.

> [!NOTE]
> Changing etcd arguments does not restart etcd: the new flags apply after `talosctl service etcd restart` or a reboot, one node at a time.

---

## Maintenance

All commands from this folder, with `SOPS_AGE_KEY_FILE` pointing to the age key (talhelper decrypts `talsecret.sops.yaml`).

### Apply a configuration change

```sh
talhelper genconfig
talosctl -n <ip> apply-config -f clusterconfig/POLARIS-<NODE>.yaml --dry-run
talosctl -n <ip> apply-config -f clusterconfig/POLARIS-<NODE>.yaml
```

`clusterconfig/` is git-ignored: it contains plaintext secrets.

### Upgrade Talos

1. Bump `talosVersion` in `talconfig.yaml`, check the [release notes](https://github.com/siderolabs/talos/releases) and that the installer exists for our schematic:

   ```sh
   talhelper gencommand upgrade        # prints one talosctl upgrade per node
   ```

2. Snapshot etcd, **outside the repo**:

   ```sh
   talosctl -n 10.10.5.11 etcd snapshot ~/polaris-etcd-$(date +%F).db
   ```

3. Upgrade **one node at a time**, control planes first, worker last. Before moving to the next node, wait for: node `Ready`, etcd healthy on all members, Longhorn volumes no longer `degraded`.

   ```sh
   talosctl -n <ip> upgrade --image=<installer from step 1>
   talosctl -n 10.10.5.11 etcd status
   kubectl -n longhorn-system get volumes.longhorn.io | grep -c degraded
   ```

<details>
<summary><b>Known issues during node upgrades</b></summary>

| Symptom | Cause | Fix |
| --- | --- | --- |
| Drain loops on a Postgres pod | CNPG PodDisruptionBudget on a single instance | `enablePDB: false` on every cluster (already set) |
| Drain loops on a Longhorn `instance-manager` | Last replica of a volume on that node | Longhorn `nodeDrainPolicy: allow-if-replica-is-stopped` (already set); for attached volumes wait for the pod to move |
| Control plane pods missing on a node, etcd `HEALTH Fail` | Longhorn rebuilds saturating the disk shared with etcd | Wait for the rebuilds to finish; etcd recovers and Talos restarts the static pods |
| Static pods not starting, kubelet logs *"CRI violation"* | Old containers still registered after static pods were regenerated | `talosctl -n <ip> service kubelet restart` |

</details>

### Upgrade Kubernetes

1. Check that **Cilium** supports the target version ([requirements](https://docs.cilium.io/en/stable/network/kubernetes/requirements/)), as well as CloudNativePG and Longhorn.
2. Bump `kubernetesVersion` in `talconfig.yaml`, then:

   ```sh
   talosctl -n 10.10.5.11 upgrade-k8s --to=<version> --dry-run
   talosctl -n 10.10.5.11 upgrade-k8s --to=<version>
   ```

`upgrade-k8s` updates the control plane components and kubelets node by node without rebooting. The dry run lists deprecated APIs still in use.

---

## Bootstrap from scratch

<details>
<summary><b>Full procedure</b></summary>

### 1. Secrets

```sh
age-keygen -o age.agekey                    # keep it safe, never commit it
export SOPS_AGE_KEY_FILE=$(pwd)/age.agekey
talhelper gensecret > talsecret.sops.yaml
sops -e -i talsecret.sops.yaml
```

The public key must match the recipient in [`.sops.yaml`](../.sops.yaml). The same key decrypts the SOPS files under `k8s/`.

### 2. Node configs

The schematic in `talconfig.yaml` (extensions + secure boot) is resolved by talhelper through the Image Factory.

```sh
talhelper genconfig
```

### 3. Install the nodes

Boot each node from the Talos secure boot ISO, then:

```sh
talosctl -n <ip> get disks --insecure        # check the install disk
talosctl -n <ip> get links --insecure        # check the NICs
talosctl apply-config -n <ip> -f clusterconfig/POLARIS-<NODE>.yaml --insecure
```

### 4. Bootstrap etcd and get access

```sh
talosctl config merge ./clusterconfig/talosconfig
talosctl config endpoint 10.10.5.11 10.10.5.12 10.10.5.13
talosctl config node 10.10.5.11
talosctl bootstrap -n 10.10.5.11              # once, on one node only
talosctl health
talosctl kubeconfig -n 10.10.5.11
```

Nodes stay `NotReady` until a CNI is installed.

### 5. Cilium (the only manual install)

```sh
helm install cilium oci://quay.io/cilium/charts/cilium \
  --version <version of k8s/infra/cilium/app/helmrelease.yaml> \
  --namespace kube-system \
  --values cilium/values.yaml
kubectl get nodes -w
```

Flux adopts the release afterwards. [`cilium/values.yaml`](cilium/values.yaml) must contain whatever is needed to boot (kube-proxy replacement, API endpoint, cgroup and capabilities for Talos).

### 6. Flux

```sh
kubectl create namespace flux-system
kubectl -n flux-system create secret generic sops-age --from-file=age.agekey=$SOPS_AGE_KEY_FILE
flux bootstrap github --token-auth --personal \
  --owner=giovanni-picco --repository=Polaris --branch=main --path=k8s/flux
```

Flux then reconciles `config → infra → core → apps`. Application volumes restore themselves from VolSync backups; databases need the [CloudNativePG recovery](../k8s/core/cnpg/README.md#recovery). Restore authentik first: every app logs in through it.

### 7. Verify

```sh
kubectl get nodes -o wide
kubectl -n kube-system exec ds/cilium -- cilium status --brief
flux get ks -A
```

</details>
