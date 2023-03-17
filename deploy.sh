#!/bin/bash

pen_f="/home/kali/pentest"

################################################################################
# linux
################################################################################
echo "Installing apt packages"

# Update and install dependencies
apt-get update > /dev/null

apt-get -y install ca-certificates curl gnupg lsb-release seclists curl dnsrecon enum4linux feroxbuster gobuster \
impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g \
whatweb wkhtmltopdf python3-pip evil-winrm chromium jq tmux python3-venv python3-pip terminator > /dev/null


################################################################################
# Install Docker 
################################################################################
echo "Installing Docker"

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

# Change transparency of qterminal to 0

sed -i 's/ApplicationTransparency=5/ApplicationTransparency=0/g' /home/kali/.config/qterminal.org/qterminal.ini 

# Change hostname
host_name="kalibored-$RANDOM"
echo "Setting hostname to ${host_name}"
hostnamectl set-hostname ${host_name}

echo "127.0.0.1	$(hostname)" >> /etc/hosts 

# Create directory to host profile.d scripts
echo "Creating ${pen_f} folders"
run_kali "mkdir ${pen_f} \
    ${pen_f}/configs \
    ${pen_f}/exploits \
    ${pen_f}/scans \
    ${pen_f}/scripts \
    ${pen_f}/trash \
    ${pen_f}/venv \
    ${pen_f}/vpn \
    ${pen_f}/webshells"

# Configure timezone

timedatectl set-timezone America/New_York

# Configure tmux
echo "Configuring tmux and zsh"

run_kali "cat <<EOT >> /home/kali/.tmux.conf
set -g mouse on 
set -g history-limit 10000
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

echo "Installing Autorecon in ${pen_f}/venv/autorecon"

run_kali "python3 -m venv ${pen_f}/venv/autorecon > /dev/null;
source ${pen_f}/venv/autorecon/bin/activate > /dev/null;
python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git > /dev/null;
deactivate > /dev/null; " 

# foxproxy
echo "Installing FoxyProxy in Firefox"

cat /usr/share/firefox-esr/distribution/policies.json |\
jq '.policies += {"Extensions"}' |\
jq '.policies.Extensions += {"Install":["https://addons.mozilla.org/firefox/downloads/file/3616827/foxyproxy_basic-7.5.1.xpi"]}' |\
jq '.policies += {"ExtensionUpdate":"true"}' |\
jq --unbuffered  > ${pen_f}/trash/policies.json
cp ${pen_f}/trash/policies.json /usr/share/firefox-esr/distribution/policies.json
rm ${pen_f}/trash/policies.json

echo "Done"
