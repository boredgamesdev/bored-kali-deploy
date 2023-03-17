#!/bin/bash


################################################################################
# linux
################################################################################

# Update and install dependencies
apt-get update


################################################################################
# Install Docker 
################################################################################
apt-get remove docker docker-engine docker.io containerd runc

apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

mkdir -m 0755 -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  
apt-get update

apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker kali

################################################################################
# Package list
################################################################################

# Custom package list
cat > kali-config/variant-default/package-lists/kali.list.chroot << EOF
# ----------------------------------------------------------------------
# Defaults suggested by kali documentation
alsa-tools
alsa-utils
coreutils
console-setup
debian-installer-launcher
kali-archive-keyring
kali-debtags
locales-all
network-manager
pulseaudio
wireless-tools
xfonts-terminus
xorg

# ----------------------------------------------------------------------
# Desktop environment (slide dependencies)
feh
graphicsmagick
rxvt-unicode
suckless-tools
xmobar
xmonad

# ----------------------------------------------------------------------
# Utilities and tools
curl
firefox-esr
git
gparted
p7zip-full
parted
python3
ranger
redshift
stow
vim

# ----------------------------------------------------------------------
# Security and penetration testing
aircrack-ng
nmap
wireshark
EOF

################################################################################
# System configuration
################################################################################

# Change transparency of qterminal to 0

sed -i 's/ApplicationTransparency=5/ApplicationTransparency=0/g' /home/kali/.config/qterminal.org/qterminal.ini

# Change hostname
hostnamectl set-hostname kalibored-$RANDOM

echo "127.0.0.1	$(hostname)" >> /etc/hosts

# Create directory to host profile.d scripts
mkdir /home/kali/pentesting
mkdir /home/kali/pentesting/configs
mkdir /home/kali/pentesting/exploits
mkdir /home/kali/pentesting/scans
mkdir /home/kali/pentesting/scripts
mkdir /home/kali/pentesting/trash
mkdir /home/kali/pentesting/venv
mkdir /home/kali/pentesting/vpn
mkdir /home/kali/pentesting/webshells

chown -R kali:kali /home/kali/pentesting 

# Configure timezone

timedatectl set-timezone America/New_York


