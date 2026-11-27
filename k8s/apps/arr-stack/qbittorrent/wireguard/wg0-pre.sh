#!/bin/bash
# hotio hook: runs before the WireGuard setup (and before the PIA config download).
set -euo pipefail

POD_ROUTE_MTU="${POD_ROUTE_MTU:-1450}"

# A container restart keeps the pod's network namespace, so the previous run's
# wg0, firewall table, endpoint rules and default route are still there and
# hotio's setup (ip link add, ip route add, ...) would fail on them.
ip link del wg0 2>/dev/null || true
nft delete table inet hotio 2>/dev/null || true
for pref in $(ip -4 rule show | awk -F: '/ipproto udp/ {print $1}'); do
  table=$(ip -4 rule show pref "${pref}" | awk '{for (i = 1; i < NF; i++) if ($i == "lookup") print $(i + 1)}')
  ip -4 rule del pref "${pref}" || true
  [[ -n "${table}" ]] && ip -4 route flush table "${table}" 2>/dev/null || true
done

# hotio caches PIA's server list for a day and always takes the first
# WireGuard server of the region: if that server breaks, every restart picks
# it again. Fetch a fresh list (PIA reorders it by load) on each start.
rm -f "${CONFIG_DIR:-/config}/wireguard/pia-regions.json"

# Cilium gives the pod a /32 and a link-scope route to its gateway on eth0.
gw=$(ip -4 route show dev eth0 scope link | awk 'NR == 1 {print $1}')
ip -4 route replace default via "${gw}" dev eth0 mtu "${POD_ROUTE_MTU}"

# The config migrated from the gluetun setup binds qBittorrent to tun0.
conf="${CONFIG_DIR:-/config}/config/qBittorrent.conf"
if [[ -f "${conf}" ]] && grep -q '^Session\\Interface\(Name\)\?=tun0$' "${conf}"; then
  sed -i -e 's/^Session\\Interface=tun0$/Session\\Interface=wg0/' \
         -e 's/^Session\\InterfaceName=tun0$/Session\\InterfaceName=wg0/' "${conf}"
  chown "${PUID:-1000}:${PGID:-1000}" "${conf}"
  echo "[wg0-pre] qBittorrent network interface switched from tun0 to wg0"
fi
