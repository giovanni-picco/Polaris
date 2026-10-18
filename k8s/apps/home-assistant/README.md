# Home Assistant

Home automation hub.

| | |
| --- | --- |
| **Namespace** | `home-assistant` |
| **Chart** | `home-assistant` ([pajikos](https://github.com/pajikos/home-assistant-helm-chart)) |
| **URL** | `https://home.${CLUSTER_DOMAIN}` |
| **Auth** | OIDC with authentik through [hass-oidc-auth](https://github.com/christiaangoossens/hass-oidc-auth) |
| **Config** | `home-assistant-config` (5 Gi), backed up with [`volsync`](../../components/README.md#volsync) daily at 04:45 |

- The chart runs as a **Deployment** with `existingClaim` (not the default StatefulSet) so the config PVC is created by VolSync. With this mode the chart names the volume `home-assistant-pvc`: extra containers mounting `/config` must use that name.
- An init container installs the `auth_oidc` custom component from a pinned release into `/config/custom_components` on every start.
- `configuration.yaml` is templated by the chart; `trusted_proxies` covers the pod network so Traefik's `X-Forwarded-For` is honoured.
- The VolSync mover runs as root: Home Assistant writes its files as `0:0`.
