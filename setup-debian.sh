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

tee /etc/ssh/ssh_config.d/9999-NoPassAuth.conf <<EOF
PasswordAuthentication no
ChallengeResponseAuthentication no
EOF

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
apt install -y curl vim htop ufw

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
usermod -aG zahar quest2you
usermod -aG sudo quest2you

# ==================================
echo "Done. Note that ssh keys and password for zahar is NOT set up"
