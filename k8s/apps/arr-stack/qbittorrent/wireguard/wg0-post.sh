#!/bin/bash
# hotio hook: runs after wg0 and the firewall are set up, before the
# connectivity test. Adapts hotio's Docker-oriented setup to a Cilium pod.
set -euo pipefail

WG_MTU="${WG_MTU:-1380}"
POD_ROUTE_MTU="${POD_ROUTE_MTU:-1450}"
# Networks that reach the WebUI: pods (Traefik, *arr apps) and nodes (probes).
LAN_NETWORKS="${LAN_NETWORKS:-10.244.0.0/16,10.10.0.0/16}"
WEBUI_PORT="${WEBUI_PORTS%%/*}"

# hotio hardcodes MTU 1420 for the PIA config: WireGuard packets would be
# ~1480 bytes, above the pod MTU (1450, VXLAN), and fragments get dropped.
# 1380 + 60 bytes of WireGuard/UDP/IPv4 overhead = 1440.
ip link set dev wg0 mtu "${WG_MTU}"

gw=$(ip -4 route show dev eth0 scope link | awk 'NR == 1 {print $1}')

# hotio only replaced the default route: keep cluster traffic (WebUI replies,
# probes) on eth0. VPN_LAN_NETWORK can't do this: hotio rejects any network
# that contains the pod's own IP.
IFS=',' read -ra nets <<< "${LAN_NETWORKS}"
for net in "${nets[@]}"; do
  ip -4 route replace "${net}" via "${gw}" dev eth0 mtu "${POD_ROUTE_MTU}"
done

# hotio's firewall rules for the VPN endpoint and the LAN need the pod's
# address to be inside a subnet with the gateway, which a Cilium /32 never is,
# so it skipped them: without these the tunnel can't even handshake.
endpoint=$(wg show wg0 endpoints | awk 'NR == 1 {print $2}')
ep_ip="${endpoint%:*}"
ep_port="${endpoint##*:}"
nft add rule inet hotio output oifname eth0 ip daddr "${ep_ip}" udp dport "${ep_port}" counter accept
nft add rule inet hotio input iifname eth0 ip saddr "${ep_ip}" udp sport "${ep_port}" counter accept

nft add rule inet hotio input iifname eth0 ip saddr "{ ${LAN_NETWORKS} }" tcp dport "${WEBUI_PORT}" counter accept
nft add rule inet hotio output oifname eth0 ip daddr "{ ${LAN_NETWORKS} }" tcp sport "${WEBUI_PORT}" counter accept

echo "[wg0-post] wg0 mtu ${WG_MTU}, endpoint ${ep_ip}:${ep_port}, WebUI open to ${LAN_NETWORKS}"
