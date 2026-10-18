# Config

Cluster-wide values, applied first by Flux and referenced by components through `postBuild.substituteFrom`.

| Object | File | Content |
| --- | --- | --- |
| `ConfigMap/cluster-config` | `cluster-config.yaml` | Non-secret variables |
| `Secret/cluster-secrets` | `cluster-secrets.sops.yaml` | Secret variables, encrypted with SOPS + age |

| Variable | Value | Used for |
| --- | --- | --- |
| `CLUSTER_NAME` | `polaris` | |
| `CLUSTER_DOMAIN` | `polarislab.dev` | Hostnames, certificates, DNS filters |
| `CLUSTER_IP_RANGE` | `10.10.5.192/26` | Cilium LoadBalancer pool |
| `NAS_DOMAIN` | `nas-01.aethernode.it` | NFS shares |

To edit the secrets (with `SOPS_AGE_KEY_FILE` pointing to the age key):

```sh
sops k8s/config/cluster-secrets.sops.yaml
```

Runtime application secrets do **not** belong here: they live in Bitwarden Secrets Manager and are pulled with [External Secrets](../core/external-secrets/README.md).
