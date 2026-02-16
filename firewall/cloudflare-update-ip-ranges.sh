#!/usr/bin/env bash

# ==================================
# Update cloudflare ip ranges for IPSet
#

sudo ipset flush cloudflare4
sudo ipset flush cloudflare6

for ip in $(curl -s https://www.cloudflare.com/ips-v4); do
  sudo ipset add cloudflare4 $ip
done

for ip in $(curl -s https://www.cloudflare.com/ips-v6); do
  sudo ipset add cloudflare6 $ip
done

echo "Ranges (IPv4):"
sudo ipset list cloudflare4
echo "Ranges (IPv6):"
sudo ipset list cloudflare6
