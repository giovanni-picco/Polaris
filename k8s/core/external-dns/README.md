# ExternalDNS

Creates the DNS records for Ingresses and LoadBalancer Services on the UniFi gateway, so `*.${CLUSTER_DOMAIN}` resolves on the LAN (and over Tailscale) without touching the gateway by hand.

| | |
| --- | --- |
| **Namespace** | `external-dns` |
| **Chart** | `external-dns` with the [UniFi webhook provider](https://github.com/kashalls/external-dns-unifi-webhook) |
| **Gateway** | `https://10.10.5.1`, API key from Bitwarden (`external-dns-unifi-secret`) |
| **Depends on** | `core-external-secrets-bitwarden` |

## Behaviour

- **Sources**: `ingress`, `service`, `traefik-proxy`. Hostnames come from the `external-dns.alpha.kubernetes.io/hostname` annotation.
- **Policy `upsert-only`**: records are created and updated but never deleted. Remove stale records from the UniFi UI.
- **Ownership**: TXT records with prefix `k8s.` and owner `default`.
- `--ignore-ingress-tls-spec`: only the annotation/rules define the hostnames.
- Limited to `${CLUSTER_DOMAIN}`.

```sh
kubectl -n external-dns logs deploy/external-dns-unifi -c external-dns --tail=50
```
