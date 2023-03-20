#!/bin/bash

C=$(printf '\033')
RED="${C}[1;31m"
SED_RED="${C}[1;31m&${C}[0m"
GREEN="${C}[1;32m"
SED_GREEN="${C}[1;32m&${C}[0m"
YELLOW="${C}[1;33m"
SED_YELLOW="${C}[1;33m&${C}[0m"
SED_RED_YELLOW="${C}[1;31;103m&${C}[0m"
BLUE="${C}[1;34m"
SED_BLUE="${C}[1;34m&${C}[0m"
ITALIC_BLUE="${C}[1;34m${C}[3m"
LIGHT_MAGENTA="${C}[1;95m"
SED_LIGHT_MAGENTA="${C}[1;95m&${C}[0m"
LIGHT_CYAN="${C}[1;96m"
SED_LIGHT_CYAN="${C}[1;96m&${C}[0m"
LG="${C}[1;37m" #LightGray
SED_LG="${C}[1;37m&${C}[0m"
DG="${C}[1;90m" #DarkGray
SED_DG="${C}[1;90m&${C}[0m"
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
whatweb wkhtmltopdf python3-pip evil-winrm chromium jq tmux python3-venv python3-pip terminator zaproxy sliver rlwrap \
bloodhound > /dev/null


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

# Change transparency of qterminal to 0

sed -i 's/ApplicationTransparency=5/ApplicationTransparency=0/g' /home/kali/.config/qterminal.org/qterminal.ini 

# Change hostname
host_name="kaliplus-$RANDOM"
printf "\n${GREEN}Setting hostname to ${BLUE}${host_name}${NC}\n"
hostnamectl set-hostname ${host_name}

echo -e "127.0.0.1	$(hostname)" >> /etc/hosts 

# Create directory to host profile.d scripts
printf "${GREEN}\nCreating ${pen_f} folders\n${NC}"
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
printf "${GREEN}\nConfiguring tmux and zsh\n${NC}"

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

printf "${GREEN}\nInstalling Autorecon in ${pen_f}/venv/autorecon\n${NC}"

run_kali "python3 -m venv ${pen_f}/venv/autorecon > /dev/null;
source ${pen_f}/venv/autorecon/bin/activate > /dev/null;
python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git > /dev/null;
deactivate > /dev/null; " 

# foxproxy
printf "${GREEN}\nInstalling FoxyProxy in Firefox\n${NC}"

cat /usr/share/firefox-esr/distribution/policies.json |\
jq '.policies += {"Extensions"}' |\
jq '.policies.Extensions += {"Install":["https://addons.mozilla.org/firefox/downloads/file/3616827/foxyproxy_basic-7.5.1.xpi"]}' |\
jq '.policies += {"ExtensionUpdate":"true"}' |\
jq --unbuffered  > ${pen_f}/trash/policies.json
cp ${pen_f}/trash/policies.json /usr/share/firefox-esr/distribution/policies.json
rm ${pen_f}/trash/policies.json


# Rockyou
printf "${GREEN}\nUnzipping Rockyou\n${NC}"
gunzip /usr/share/wordlists/rockyou.txt.gz 

# Configure socks proxy
printf "${GREEN}\nLower socks proxy timeout, helps with nmap scanning though socks\n${RED}WARNING YOU MAY NEED TO CHANGE THIS ON A SLOWER NETWORK\n${NC}"
sed -i 's/tcp_read_time_out 15000/tcp_read_time_out 1500/g' /etc/proxychains4.conf
sed -i 's/tcp_connect_time_out 8000/tcp_connect_time_out 800/g' /etc/proxychains4.conf

# Downloading common scripts
printf "${GREEN}\nDownloading popular scripts\n${NC}"
run_kali "\
wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh -O ${pen_f}/scripts/linpeas.sh 2>&1 > /dev/null; \
wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany.exe -O ${pen_f}/scripts/winPEASany.exe 2>&1 > /dev/null; \
wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEAS.bat -O ${pen_f}/scripts/winPEAS.bat 2>&1 > /dev/null; \
wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany_ofs.exe -O ${pen_f}/scripts/winPEASany_ofs.exe 2>&1 > /dev/null; \
wget https://github.com/diego-treitos/linux-smart-enumeration/releases/latest/download/lse.sh -O ${pen_f}/scripts/lse.sh 2>&1 > /dev/null; \
wget https://raw.githubusercontent.com/WhiteWinterWolf/wwwolf-php-webshell/master/webshell.php -O ${pen_f}/webshells/wolf.php 2>&1 > /dev/null;"

# Final apt update
printf "${GREEN}\nFinal apt update and upgrade\n${NC}"

apt-get -y update > /dev/null
NEEDRESTART_MODE=a apt-get full-upgrade --yes > /dev/null

printf "${GREEN}\nDone, please reboot\n${NC}"

