#!/bin/bash


################################################################################
# linux
################################################################################

# Update and install dependencies
apt-get update

apt-get -y install ca-certificates curl gnupg lsb-release seclists curl dnsrecon enum4linux feroxbuster gobuster \
impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g \
whatweb wkhtmltopdf python3-pip evil-winrm chromium jq tmux python3-venv python3-pip


################################################################################
# Install Docker 
################################################################################
apt-get remove docker docker-engine docker.io containerd runc

apt install -y docker.io docker-compose

systemctl enable docker --now

usermod -aG docker kali

################################################################################
# Setup Runuser
################################################################################

run_kali() { runuser -l kali -c "$@" ;}

################################################################################
# System configuration
################################################################################

# Change transparency of qterminal to 0

sed -i 's/ApplicationTransparency=5/ApplicationTransparency=0/g' /home/kali/.config/qterminal.org/qterminal.ini

# Change hostname
hostnamectl set-hostname kalibored-$RANDOM

echo "127.0.0.1	$(hostname)" >> /etc/hosts

# Create directory to host profile.d scripts
run_kali "mkdir /home/kali/pentesting \
    /home/kali/pentesting/configs \
    /home/kali/pentesting/exploits \
    /home/kali/pentesting/scans \
    /home/kali/pentesting/scripts \
    /home/kali/pentesting/trash \
    /home/kali/pentesting/venv \
    /home/kali/pentesting/vpn \
    /home/kali/pentesting/webshells"

# Configure timezone

timedatectl set-timezone America/New_York

# Configure tmux

run_kali "cat <<EOT >> /home/kali/.tmux.conf
set -g mouse on 
set -g history-limit 5000
EOT"

# Configure zsh
sed -i 's/HISTSIZE=1000/HISTSIZE=1000000000/g' /home/kali/.zshrc
sed -i 's/SAVEHIST=2000/SAVEHIST=1000000000/g' /home/kali/.zshrc

run_kali "cat <<EOT >> /home/kali/.zshrc
# Custom

setopt share_history         
setopt INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
EOT"

# autorecon

run_kali "python3 -m venv /home/kali/pentesting/venv/autorecon ;
source /home/kali/pentesting/venv/autorecon/bin/activate ;
python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git ;
deactivate ; "
