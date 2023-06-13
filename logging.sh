#!/bin/bash

C=$(printf '\033')
RED="${C}[1;31m"
GREEN="${C}[1;32m"
BLUE="${C}[1;34m"
NC="${C}[0m"
UNDERLINED="${C}[5m"
ITALIC="${C}[3m"

if [ "$EUID" -ne 0 ]
  then echo "${RED}Please run as root"
  exit
fi

pen_f="/home/kali/pentest"

################################################################################
# linux
################################################################################
printf "${GREEN}\nInstalling apt packages\n${NC}"

# Update and install dependencies
apt-get update > /dev/null

apt-get -y install ca-certificates curl gnupg lsb-release seclists curl dnsrecon enum4linux feroxbuster gobuster \
impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g \
whatweb wkhtmltopdf python3-pip evil-winrm chromium jq tmux python3-venv python3-pip terminator zaproxy sliver rlwrap jython \
bloodhound xorg xrdp > /dev/null


################################################################################
# Install Docker 
################################################################################
printf "${GREEN}\nInstalling Docker\n${NC}"

apt-get -y install docker.io docker-compose > /dev/null

systemctl enable docker --now > /dev/null

usermod -aG docker kali 

################################################################################
# Setup Runuser
################################################################################

run_kali() { runuser -l kali -c "$@" ;} 

################################################################################
# System configuration
################################################################################

# Create directory to host profile.d scripts
printf "${GREEN}\nCreating ${pen_f} folders\n${NC}"
run_kali "mkdir ${pen_f} \
    ${pen_f}/configs \
    ${pen_f}/exploits \
    ${pen_f}/scans \
    ${pen_f}/scripts \
    ${pen_f}/payloads \
    ${pen_f}/trash \
    ${pen_f}/venv \
    ${pen_f}/vpn \
    ${pen_f}/logs \
    ${pen_f}/webshells"

# Configure timezone

timedatectl set-timezone Etc/GMT

# Configure tmux
printf "${GREEN}\nConfiguring tmux and zsh\n${NC}"

run_kali "cat <<EOT >> /home/kali/.tmux.conf
set -g mouse on 
set -g history-limit 10000
EOT"

# Configure zsh
sed -i 's/HISTSIZE=1000/HISTSIZE=1000000000/g' /home/kali/.zshrc
sed -i 's/SAVEHIST=2000/SAVEHIST=1000000000/g' /home/kali/.zshrc
sed -i 's/setopt hist_ignore_dups//g' /home/kali/.zshrc
sed -i 's/setopt hist_ignore_space//g' /home/kali/.zshrc


run_kali "cat <<EOT >> /home/kali/.zshrc
# Custom

setopt share_history         
setopt INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS
setopt EXTENDED_HISTORY
EOT"

# Final apt update
printf "${GREEN}\nFinal apt update and upgrade\n${NC}"

apt-get -y update > /dev/null
NEEDRESTART_MODE=a apt-get full-upgrade --yes > /dev/null

printf "${GREEN}\nDone, please reboot\n${NC}"
