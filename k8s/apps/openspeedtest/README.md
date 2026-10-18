# OpenSpeedTest

Network speed test against the cluster, useful to check LAN, Wi-Fi and Tailscale throughput.

| | |
| --- | --- |
| **Namespace** | `openspeedtest` |
| **Chart** | `openspeedtest` |
| **URL** | `https://speedtest.${CLUSTER_DOMAIN}` (through Traefik) |
| **Direct** | LoadBalancer `10.10.5.193`, to measure without the ingress in the path |
| **Auth** | none |
| **State** | none |
