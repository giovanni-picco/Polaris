# cert-manager

Issues and renews TLS certificates. Every Ingress annotated with `cert-manager.io/cluster-issuer: letsencrypt` gets a Let's Encrypt certificate for its host.

| | |
| --- | --- |
| **Namespace** | `cert-manager` |
| **Chart** | `cert-manager` (CRDs installed by the chart) |
| **Issuer** | `ClusterIssuer/letsencrypt`, ACME DNS-01 on Cloudflare for `${CLUSTER_DOMAIN}` |
| **Metrics** | controller, cainjector, webhook, see [prometheus/monitors](../../core/prometheus/README.md) |

## Structure

| Folder | Flux Kustomization | Content |
| --- | --- | --- |
| `app/` | `infra-cert-manager-app` | HelmRelease |
| `letsencrypt/` | `infra-cert-manager-letsencrypt` | `ClusterIssuer` and the Cloudflare API token (SOPS-encrypted, since External Secrets is not running yet at this layer) |

DNS-01 is used because the services are not reachable from the Internet: the public `polarislab.dev` zone on Cloudflare is only used for the ACME challenges, while the records that clients resolve live on the UniFi gateway (see [external-dns](../../core/external-dns/README.md)).

Other issuers in the cluster are created by the components that need them: the Bitwarden SDK server CA ([external-secrets](../../core/external-secrets/README.md)) and the Barman Cloud plugin certificates ([cnpg](../../core/cnpg/README.md)).

## Maintenance

```sh
kubectl get certificates -A          # READY should be True everywhere
kubectl describe certificate -n <ns> <name>
```

To rotate the Cloudflare token: `sops k8s/infra/cert-manager/letsencrypt/secret.sops.yaml` (with `SOPS_AGE_KEY_FILE` set), commit, push.
