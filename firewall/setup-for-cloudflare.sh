#!/usr/bin/env bash

# ==================================
# Setup IPSet/IPTables to:
#  Allow ssh connection
#  Allow http(s) from Cloudflare
#  Forbid everything else
#
# Works on Debian, might work on Ubuntu
#

sudo apt update
sudo apt install -y ipset iptables curl

sudo ipset create cloudflare4 hash:net
sudo ipset create cloudflare6 hash:net family inet6

for ip in $(curl -s https://www.cloudflare.com/ips-v4); do
  sudo ipset add cloudflare4 $ip
done

for ip in $(curl -s https://www.cloudflare.com/ips-v6); do
  sudo ipset add cloudflare6 $ip
done

# ==================================

sudo iptables -F
sudo iptables -X
sudo ip6tables -F
sudo ip6tables -X
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT
sudo ip6tables -P INPUT DROP
sudo ip6tables -P FORWARD DROP
sudo ip6tables -P OUTPUT ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo ip6tables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -m set --match-set cloudflare4 src -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -m set --match-set cloudflare4 src -j ACCEPT
sudo ip6tables -A INPUT -p tcp --dport 80 -m set --match-set cloudflare6 src -j ACCEPT
sudo ip6tables -A INPUT -p tcp --dport 443 -m set --match-set cloudflare6 src -j ACCEPT

# intentionally no '-y'
sudo apt install ipset-persistent netfilter-persistent
sudo netfilter-persistent save
