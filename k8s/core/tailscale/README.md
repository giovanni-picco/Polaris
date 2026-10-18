# Tailscale

Remote access to the lab without exposing anything to the Internet. The Tailscale operator runs a subnet router that advertises the LAN addresses the services need.

| | |
| --- | --- |
| **Namespace** | `tailscale` |
| **Chart** | `tailscale-operator` |
| **Credentials** | OAuth client from Bitwarden (`tailscale-oauth`) |
| **Depends on** | `core-external-secrets-bitwarden` |

## Structure

| Folder | Flux Kustomization | Content |
| --- | --- | --- |
| `app/` | `core-tailscale-app` | Operator, with the API server proxy enabled (`kubectl` over the tailnet) |
| `connector/` | `core-tailscale-connector` | `Connector/polaris-subnet-router` |

The subnet router (`polaris-subnet-router`) advertises:

| Route | Why |
| --- | --- |
| `10.10.5.1/32` | UniFi gateway, i.e. the DNS server holding the `*.${CLUSTER_DOMAIN}` records |
| `10.10.5.192/26` | Cilium LoadBalancer pool (Traefik and other LoadBalancer Services) |

Routes must be approved in the Tailscale admin console (or by an auto-approver in the ACL policy), and tailnet DNS should use `10.10.5.1` for `${CLUSTER_DOMAIN}` (split DNS).
