#!/bin/bash

pen_f="/home/kali/pentest"
to_null="> /dev/null"

################################################################################
# linux
################################################################################

# Update and install dependencies
apt-get update ${to_null}

apt-get -y install ca-certificates curl gnupg lsb-release seclists curl dnsrecon enum4linux feroxbuster gobuster \
impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g \
whatweb wkhtmltopdf python3-pip evil-winrm chromium jq tmux python3-venv python3-pip terminator ${to_null}


################################################################################
# Install Docker 
################################################################################

apt install -y docker.io docker-compose ${to_null}

systemctl enable docker --now ${to_null}

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

run_kali "python3 -m venv ${pen_f}/venv/autorecon ;
source ${pen_f}/venv/autorecon/bin/activate ;
python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git ;
deactivate ; " ${to_null}

# foxproxy

cat /usr/share/firefox-esr/distribution/policies.json |\
jq '.policies += {"Extensions"}' |\
jq '.policies.Extensions += {"Install":["https://addons.mozilla.org/firefox/downloads/file/3616827/foxyproxy_basic-7.5.1.xpi"]}' |\
jq '.policies += {"ExtensionUpdate":"true"}' |\
jq --unbuffered  > ${pen_f}/trash/policies.json
cp ${pen_f}/trash/policies.json /usr/share/firefox-esr/distribution/policies.json
rm ${pen_f}/trash/policies.json
