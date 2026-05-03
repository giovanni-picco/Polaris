# POLARIS — Talos Kubernetes Cluster

## Overview

| Component         | Value                                      |
|-------------------|--------------------------------------------|
| Cluster name      | POLARIS                                    |
| Talos version     | v1.12.5                                    |
| Kubernetes version| v1.35.0                                    |
| API endpoint      | `https://kube.polarislab.dev:6443`         |
| VIP (kube-vip)    | `10.10.5.10`                               |
| CNI               | Cilium (kube-proxy disabled, eBPF mode)    |
| GitOps            | FluxCD                                     |
| Config tool       | talhelper                                  |

### Nodes

| Hostname | Role         | Hardware             | IP (VLAN 5)  | Install Disk   |
|----------|--------------|----------------------|--------------|----------------|
| PCP-01   | Controlplane | HP ProDesk 400 G2    | 10.10.5.11   | `/dev/sda`     |
| PCP-02   | Controlplane | HP ProDesk 400 G2    | 10.10.5.12   | `/dev/sda`     |
| PCP-03   | Controlplane | HP ProDesk 400 G2    | 10.10.5.13   | `/dev/sda`     |
| PWR-01   | Worker       | Minisforum MS-01     | 10.10.5.14   | `/dev/nvme0n1` |
| PWR-02   | Worker       | Minisforum MS-01     | 10.10.5.15   | `/dev/nvme0n1` |

### Network

| VLAN | Subnet          | Purpose                              |
|------|-----------------|--------------------------------------|
| 5    | 10.10.5.0/24    | Cluster network (node IPs, API)      |
| 6    | 10.10.6.0/24    | DMZ — LoadBalancer IPs via Cilium L2 |

All node IPs are assigned via DHCP reservation on the Unifi gateway (both VLAN 5 and VLAN 6).

---

## Prerequisites

- [talosctl](https://www.siderolabs.com/platform/talos-os-for-kubernetes/)
- [talhelper](https://budimanjojo.github.io/talhelper/)
- [helm](https://helm.sh/)
- [flux](https://fluxcd.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [sops](https://github.com/getsops/sops)
- [age](https://github.com/FiloSottile/age)

---

## Bootstrap Procedure

### 1. Generate Secrets

Cluster secrets (CA certs, tokens, encryption keys) are generated once and encrypted at rest with [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age), as recommended by talhelper.

#### 1a. Generate an age key

```sh
age-keygen -o age.agekey
```

This creates a file containing the private key and a comment with the public key (starts with `age1...`). **Keep this file safe and never commit it to Git.**

> The public key from this file is already configured in `.sops.yaml` as the encryption recipient.

#### 1b. Export the key for SOPS and talhelper

Both `sops` and `talhelper genconfig` need the age private key to encrypt/decrypt. Export it in the current shell:

```sh
export SOPS_AGE_KEY_FILE=$(pwd)/age.agekey
```

#### 1c. Generate and encrypt the secrets file

```sh
talhelper gensecret > talsecret.sops.yaml
sops -e -i talsecret.sops.yaml
```

After encryption, `talsecret.sops.yaml` is safe to commit — it contains only encrypted values. The plaintext is never stored on disk outside of this workflow.

### 2. Generate Schematic ID

Go to <https://factory.talos.dev/> and generate a schematic matching the required extensions:

```yaml
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/i915       # Intel GPU
      - siderolabs/iscsi-tools # Longhorn
```

Note the schematic ID — it is used by talhelper to build the installer image.

### 3. Generate Node Configs with talhelper

From the directory containing `talconfig.yaml` and `talsecret.sops.yaml`:

> `SOPS_AGE_KEY_FILE` must be set (see step 1b) — talhelper decrypts the secrets automatically during generation.

```sh
talhelper genconfig
```

This generates one config file per node in the `clusterconfig/` directory.

### 4. Boot Nodes from Talos ISO

Boot each node from the Talos ISO (USB or PXE). Once booted, the nodes are reachable via their DHCP-assigned IPs on VLAN 5.

### 5. Verify Interfaces and Disks

This step has already been completed for all nodes. For reference, the commands are:

```sh
# List network interfaces
talosctl -n <NODE_IP> get links --insecure

# List available disks
talosctl -n <NODE_IP> get disks --insecure
```

**Verified configuration:**

| Node   | Interface(s)                      | Disk           |
|--------|-----------------------------------|----------------|
| PCP-01 | `enp1s0`                          | `/dev/sda`     |
| PCP-02 | `enp1s0`                          | `/dev/sda`     |
| PCP-03 | `enp1s0`                          | `/dev/sda`     |
| PWR-01 | `enp87s0` + `enp89s0` (LACP bond) | `/dev/nvme0n1` |
| PWR-02 | `enp87s0` + `enp89s0` (LACP bond) | `/dev/nvme0n1` |

### 6. Apply Configs

Apply the generated config to each node:

```sh
talosctl apply-config --nodes 10.10.5.11 --file clusterconfig/POLARIS-PCP-01.yaml --insecure
talosctl apply-config --nodes 10.10.5.12 --file clusterconfig/POLARIS-PCP-02.yaml --insecure
talosctl apply-config --nodes 10.10.5.13 --file clusterconfig/POLARIS-PCP-03.yaml --insecure
talosctl apply-config --nodes 10.10.5.14 --file clusterconfig/POLARIS-PWR-01.yaml --insecure
talosctl apply-config --nodes 10.10.5.15 --file clusterconfig/POLARIS-PWR-02.yaml --insecure
```

> PWR-02 will be applied later when the hardware arrives.

### 7. Merge talosctl Config

```sh
talosctl config merge ./clusterconfig/talosconfig
```

Set endpoints and default node:

```sh
talosctl config endpoint 10.10.5.11 10.10.5.12 10.10.5.13
talosctl config node 10.10.5.11
```

### 8. Bootstrap the Cluster

Run bootstrap on **one** controlplane node only:

```sh
talosctl bootstrap --nodes 10.10.5.11
```

Wait for etcd and the API server to come up:

```sh
talosctl health
```

At this point the nodes will be in `NotReady` state — this is expected because no CNI is installed yet.

### 9. Get kubeconfig

```sh
talosctl kubeconfig --nodes 10.10.5.11
```

Verify access:

```sh
kubectl get nodes
```

All nodes should appear as `NotReady`.

### 10. Install Cilium (manual one-shot)

This is the only manual step outside of GitOps. Cilium must be installed before Flux can run, because nodes need a CNI to become `Ready`.

```sh
helm install cilium oci://quay.io/cilium/charts/cilium \
  --version 1.19.1 \
  --namespace kube-system \
  --values cilium/values.yaml
```

Wait for all nodes to become `Ready`:

```sh
kubectl get nodes -w
```

> After this step, Flux will take ownership of Cilium via a HelmRelease. This manual install is never repeated — upgrades and config changes are managed by Flux from this point forward.

### 11. Bootstrap Flux

```sh
flux bootstrap gitlab \
  --owner=<GROUP> \
  --repository=<CLUSTER_REPO> \
  --branch=main \
  --path=clusters/polaris
```

Once Flux is running, it will reconcile all components including:

- **Cilium HelmRelease** — takes over ownership from the manual install
- **CiliumLoadBalancerIPPool** — allocates `10.10.6.128/25` for LoadBalancer Services
- **CiliumL2AnnouncementPolicy** — enables L2 ARP replies on VLAN 6 interfaces

### 12. Verify

```sh
# Nodes
kubectl get nodes -o wide

# Cilium status
kubectl -n kube-system exec ds/cilium -- cilium status

# Flux
flux get all
```
