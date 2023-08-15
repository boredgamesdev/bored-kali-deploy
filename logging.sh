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

pen_f="/home/$(whoami)/pentest"

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

printf "${RED}\nLoad the burp config at /home/kali/pentest/configs/burplogging.json\n${NC}"

run_kali "curl -o - https://raw.githubusercontent.com/boredgamesdev/bored-kali-deploy/main/configs/burplogging.json > /home/kali/pentest/configs/burplogging.json"

printf "${RED}\nRUN THIS IN NESSUS TO ENABLE VERBOSE LOGGING\n${NC}"
printf "${GREEN}\n/opt/nessus/sbin/nessuscli fix --set log_details=true; /opt/nessus/sbin/nessuscli fix --set log_whole_attack=true\n${NC}"


printf "${GREEN}\nDone\n${NC}"
