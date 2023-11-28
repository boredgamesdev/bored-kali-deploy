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

pen_f="/root/pentest"

################################################################################
# linux
################################################################################
printf "${GREEN}\nInstalling apt packages\n${NC}"

apt-get -y install ca-certificates curl gnupg lsb-release seclists curl dnsrecon enum4linux feroxbuster gobuster \
impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g \
whatweb wkhtmltopdf python3-pip evil-winrm chromium jq tmux python3-venv python3-pip terminator zaproxy sliver rlwrap jython \
bloodhound xorg xrdp > /dev/null


################################################################################
# System configuration
################################################################################

# Create directory to host profile.d scripts
printf "${GREEN}\nCreating ${pen_f} folders\n${NC}"
mkdir ${pen_f} \
    ${pen_f}/configs \
    ${pen_f}/exploits \
    ${pen_f}/scans \
    ${pen_f}/scripts \
    ${pen_f}/trash \
    ${pen_f}/venv \
    ${pen_f}/vpn \
    ${pen_f}/webshells

# Configure timezone

timedatectl set-timezone America/New_York

# Configure tmux
printf "${GREEN}\nConfiguring tmux and zsh\n${NC}"

cat <<EOT >> /root/.tmux.conf
set -g mouse on 
set -g history-limit 10000
EOT

# Configure zsh
sed -i 's/HISTSIZE=1000/HISTSIZE=1000000000/g' /root/.zshrc
sed -i 's/SAVEHIST=2000/SAVEHIST=1000000000/g' /root/.zshrc

curl -o - https://raw.githubusercontent.com/boredgamesdev/bored-kali-deploy/main/configs/history.txt >> /root/.zsh_history

cat <<EOT >> /root/.zshrc
# Custom

setopt share_history         
setopt INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
EOT

# autorecon

printf "${GREEN}\nInstalling Autorecon in ${pen_f}/venv/autorecon\n${NC}"

python3 -m venv ${pen_f}/venv/autorecon > /dev/null;
source ${pen_f}/venv/autorecon/bin/activate > /dev/null;
python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git > /dev/null;
deactivate > /dev/null; 

# Rockyou
printf "${GREEN}\nUnzipping Rockyou\n${NC}"
gunzip /usr/share/wordlists/rockyou.txt.gz 

# Configure socks proxy
printf "${GREEN}\nLower socks proxy timeout, helps with nmap scanning though socks\n${RED}WARNING YOU MAY NEED TO CHANGE THIS ON A SLOWER NETWORK\n${NC}"
sed -i 's/tcp_read_time_out 15000/tcp_read_time_out 1500/g' /etc/proxychains4.conf
sed -i 's/tcp_connect_time_out 8000/tcp_connect_time_out 800/g' /etc/proxychains4.conf

# Downloading common scripts
printf "${GREEN}\nDownloading popular scripts\n${NC}"

wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh -O ${pen_f}/scripts/linpeas.sh -q; \
wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany.exe -O ${pen_f}/scripts/winpeasany.exe -q; \
wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEAS.bat -O ${pen_f}/scripts/winpeas.bat -q; \
wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany_ofs.exe -O ${pen_f}/scripts/winpeasany_ofs.exe -q; \
wget https://github.com/diego-treitos/linux-smart-enumeration/releases/latest/download/lse.sh -O ${pen_f}/scripts/lse.sh -q; \
wget https://raw.githubusercontent.com/WhiteWinterWolf/wwwolf-php-webshell/master/webshell.php -O ${pen_f}/webshells/wolf.php -q; \
wget https://github.com/DominicBreuker/pspy/releases/latest/download/pspy64 -O ${pen_f}/scripts/pspy64 -q; \
wget https://github.com/DominicBreuker/pspy/releases/latest/download/pspy32 -O ${pen_f}/scripts/pspy32 -q; \
wget https://github.com/jpillora/chisel/releases/download/v1.8.1/chisel_1.8.1_windows_amd64.gz -O ${pen_f}/scripts/chisel_1.8.1_windows_amd64.gz -q; \
wget https://github.com/jpillora/chisel/releases/download/v1.8.1/chisel_1.8.1_windows_386.gz -O ${pen_f}/scripts/chisel_1.8.1_windows_386.gz -q; \
wget https://github.com/jpillora/chisel/releases/download/v1.8.1/chisel_1.8.1_linux_386.gz -O ${pen_f}/scripts/chisel_1.8.1_linux_386.gz -q; \
wget https://github.com/jpillora/chisel/releases/download/v1.8.1/chisel_1.8.1_linux_amd64.gz -O ${pen_f}/scripts/chisel_1.8.1_linux_amd64.gz -q ;

printf "${GREEN}\nDone, please reboot\n${NC}"

