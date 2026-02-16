#!/usr/bin/env bash

# ==================================
# Setup bare Debian server
# Must be run under root
# Server will be controlled by "zahar" user

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

set -euo pipefail

# ==================================
echo "Disabling password auth for ssh"
# ==================================

tee /etc/ssh/ssh_config.d/00-security.conf <<EOF
PasswordAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
EOF

# Clone it so it works despite files loading order
cp /etc/ssh/ssh_config.d/00-security.conf /etc/ssh/ssh_config.d/99-security.conf

systemctl reload ssh

# ==================================
echo "Setting up swapfile"
# ==================================

fallocate -l 8G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# ==================================
echo "Installing packages"
# ==================================

apt update
apt install -y curl vim htop

# ==================================
echo "Setting up docker repository"
# ==================================

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update

# ==================================
echo "Installing and enabling Docker"
# ==================================

apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable docker
systemctl start docker

# ==================================
echo "Creating admin user (zahar)"
# ==================================

useradd -m -d /home/zahar -s /bin/bash zahar
mkdir -p /home/zahar
chown -R zahar:zahar /home/zahar
usermod -aG docker zahar
usermod -aG sudo zahar

mkdir -p /home/zahar/.ssh
cp /root/.ssh/authorized_keys /home/zahar/.ssh/authorized_keys
chmod go+r /home/zahar/.ssh/authorized_keys

echo "Please setup the password for zahar"
passwd zahar

# ==================================
echo "Done. Now you should reconnect to ssh under zahar (ssh key is the same as for root)"
