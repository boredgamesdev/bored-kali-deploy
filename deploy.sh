#!/bin/bash


################################################################################
# linux
################################################################################

# Update and install dependencies
apt-get update

apt-get -y install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    seclists \
    curl \
    dnsrecon \
    enum4linux \
    feroxbuster \
    gobuster \
    impacket-scripts \
    nbtscan \
    nikto \
    nmap \
    onesixtyone \
    oscanner \
    redis-tools \
    smbclient \
    smbmap \
    snmp \
    sslscan \
    sipvicious \
    tnscmd10g \
    whatweb \
    wkhtmltopdf \
    python3-pip \
    evil-winrm \
    chromium \
    jq \
    tmux \
    python3-venv


################################################################################
# Install Docker 
################################################################################
apt-get remove docker docker-engine docker.io containerd runc

apt install -y docker.io docker-compose

systemctl enable docker --now

usermod -aG docker kali

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

# Configure tmux

cat <<EOT >> /home/kali/.tmux.conf
set -g mouse on 
set -g history-limit 5000
EOT

# Configure zsh
sed -i 's/HISTSIZE=1000/HISTSIZE=1000000000/g' /home/kali/.zshrc
sed -i 's/SAVEHIST=2000/SAVEHIST=1000000000/g' /home/kali/.zshrc

cat <<EOT >> /home/kali/.zshrc
# Custom

setopt share_history         
setopt INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
EOT

# autorecon

apt install -y seclists curl dnsrecon enum4linux feroxbuster gobuster impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g whatweb wkhtmltopdf python3-pip

python3 -m venv /home/kali/pentesting/venv/autorecon
source /home/kali/pentesting/venv/autorecon/bin/activate
python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git
deactivate
