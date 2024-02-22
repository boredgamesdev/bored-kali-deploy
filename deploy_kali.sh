#!/bin/bash

C=$(printf '\033')
RED="${C}[1;31m"
GREEN="${C}[1;32m"
BLUE="${C}[1;34m"
NC="${C}[0m"
UNDERLINED="${C}[5m"
ITALIC="${C}[3m"

SCRIPT_VERSION="1.0"

if [ "$EUID" -ne 0 ]
  then echo "${RED}Please run as sudo"
  exit
fi

show_help() {
    echo "Usage: $(basename "$0") [options]"
    echo "Options:"
    echo "  -d, --default   Run for default Kali install"
    echo "  -r, --root      Run if root is the only user"
    echo "  -l, --logging   Run for logging config"

   
    echo ""
    echo "Before running the script, make sure to update and upgrade your system by running:"
    echo "  sudo apt update && sudo apt upgrade"
}

prompt_yes_no() {
    while true; do
        read -p "$1 [y/n]: " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) ;;
        esac
    done
}

run_kali() { runuser -l $(whoami) -c "$@" ;} 



install_packages() {
    printf "${GREEN}\nInstalling apt packages\n${NC}"
    apt-get -y install ca-certificates curl gnupg lsb-release seclists curl dnsrecon enum4linux feroxbuster gobuster \
    impacket-scripts nbtscan nikto nmap onesixtyone oscanner redis-tools smbclient smbmap snmp sslscan sipvicious tnscmd10g \
    whatweb wkhtmltopdf python3-pip evil-winrm chromium jq tmux python3-venv python3-pip terminator zaproxy sliver rlwrap jython \
    bloodhound xorg xrdp > /dev/null
}

install_docker() {
    printf "${GREEN}\nInstalling Docker\n${NC}"
    apt-get -y install docker.io docker-compose > /dev/null
    systemctl enable docker --now > /dev/null
    usermod -aG docker kali 
}


configure_logging() {
	# Configure zsh
	sed -i 's/HISTSIZE=1000/HISTSIZE=1000000000/g' ${home_folder}.zshrc
	sed -i 's/SAVEHIST=2000/SAVEHIST=1000000000/g' ${home_folder}.zshrc
	sed -i 's/setopt hist_ignore_dups//g' ${home_folder}.zshrc
	sed -i 's/setopt hist_ignore_space//g' ${home_folder}.zshrc

cat <<EOT >> ${home_folder}.zshrc
# Custom

setopt share_history         
setopt INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS
setopt EXTENDED_HISTORY
EOT

	printf "${RED}\nLoad the burp config at /home/$(whoami)/pentest/configs/burplogging.json\n${NC}"

	curl -o - https://raw.githubusercontent.com/boredgamesdev/bored-kali-deploy/main/configs/burplogging.json > ${home_folder}pentest/configs/burplogging.json

	printf "${RED}\nRUN THIS IN NESSUS TO ENABLE VERBOSE LOGGING\n${NC}"
	printf "${GREEN}\n/opt/nessus/sbin/nessuscli fix --set log_details=true; /opt/nessus/sbin/nessuscli fix --set log_whole_attack=true\n${NC}"


}

configure_default() {
   # Configure zsh
    sed -i 's/HISTSIZE=1000/HISTSIZE=1000000000/g' ${home_folder}.zshrc
    sed -i 's/SAVEHIST=2000/SAVEHIST=1000000000/g' ${home_folder}.zshrc

    run_kali "curl -o - https://raw.githubusercontent.com/boredgamesdev/bored-kali-deploy/main/configs/history.txt >> ${home_folder}.zsh_history"
    run_kali "curl -o - https://raw.githubusercontent.com/boredgamesdev/bored-kali-deploy/main/configs/history.txt >> ${home_folder}.bash_history"

    run_kali cat <<EOT >> ${home_folder}.zshrc
# Custom
setopt share_history         
setopt INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
EOT
}

configure_system() {
    # Change transparency of qterminal to 0
    #sed -i 's/ApplicationTransparency=5/ApplicationTransparency=0/g' /home/kali/.config/qterminal.org/qterminal.ini 

    # Create directory to host scripts
    printf "${GREEN}\nCreating ${home_folder} folders\n${NC}"
    run_kali "mkdir ${home_folder}pentest \
        ${home_folder}pentest/configs \
        ${home_folder}pentest/exploits \
        ${home_folder}pentest/scans \
        ${home_folder}pentest/scripts \
        ${home_folder}pentest/trash \
        ${home_folder}pentest/venv \
        ${home_folder}pentest/vpn \
        ${home_folder}pentest/webshells"

    # Configure timezone
    timedatectl set-timezone America/New_York

    # Configure tmux
    printf "${GREEN}\nConfiguring tmux and zsh\n${NC}"
    run_kali "cat <<EOT >> ${home_folder}.tmux.conf
    set -g mouse on 
    set -g history-limit 10000
    EOT"

    # autorecon
    printf "${GREEN}\nInstalling Autorecon in ${home_folder}venv/autorecon\n${NC}"
    run_kali "python3 -m venv ${home_folder}venv/autorecon > /dev/null;
    source ${home_folder}venv/autorecon/bin/activate > /dev/null;
    python3 -m pip install git+https://github.com/Tib3rius/AutoRecon.git > /dev/null;
    deactivate > /dev/null; " 

    # foxproxy
    printf "${GREEN}\nInstalling FoxyProxy in Firefox\n${NC}"
    cat /usr/share/firefox-esr/distribution/policies.json |\
    jq '.policies += {"Extensions"}' |\
    jq '.policies.Extensions += {"Install":["https://addons.mozilla.org/firefox/downloads/file/3616827/foxyproxy_basic-7.5.1.xpi"]}' |\
    jq '.policies += {"ExtensionUpdate":"true"}' |\
    jq --unbuffered  > ${home_folder}pentest/trash/policies.json
    cp ${home_folder}pentest/trash/policies.json /usr/share/firefox-esr/distribution/policies.json
    rm ${home_folder}pentest/trash/policies.json

    # Rockyou
    printf "${GREEN}\nUnzipping Rockyou\n${NC}"
    gunzip /usr/share/wordlists/rockyou.txt.gz 

    # Configure socks proxy
    printf "${GREEN}\nLower socks proxy timeout, helps with nmap scanning though socks\n${RED}WARNING YOU MAY NEED TO CHANGE THIS ON A SLOWER NETWORK\n${NC}"
    sed -i 's/tcp_read_time_out 15000/tcp_read_time_out 1500/g' /etc/proxychains4.conf
    sed -i 's/tcp_connect_time_out 8000/tcp_connect_time_out 800/g' /etc/proxychains4.conf
}

download_scripts() {
    printf "${GREEN}\nDownloading popular scripts\n${NC}"
    run_kali "\
    wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh -O ${home_folder}pentest/scripts/linpeas.sh -q; \
    wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany.exe -O ${home_folder}pentest/scripts/winpeasany.exe -q; \
    wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEAS.bat -O ${home_folder}pentest/scripts/winpeas.bat -q; \
    wget https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany_ofs.exe -O ${home_folder}pentest/scripts/winpeasany_ofs.exe -q; \
    wget https://github.com/diego-treitos/linux-smart-enumeration/releases/latest/download/lse.sh -O ${home_folder}pentest/scripts/lse.sh -q; \
    wget https://raw.githubusercontent.com/WhiteWinterWolf/wwwolf-php-webshell/master/webshell.php -O ${home_folder}pentest/webshells/wolf.php -q; \
    wget https://github.com/DominicBreuker/pspy/releases/latest/download/pspy64 -O ${home_folder}pentest/scripts/pspy64 -q; \
    wget https://github.com/DominicBreuker/pspy/releases/latest/download/pspy32 -O ${home_folder}pentest/scripts/pspy32 -q; \
    wget https://github.com/jpillora/chisel/releases/download/v1.8.1/chisel_1.8.1_windows_amd64.gz -O ${home_folder}pentest/scripts/chisel_1.8.1_windows_amd64.gz -q; \
    wget https://github.com/jpillora/chisel/releases/download/v1.8.1/chisel_1.8.1_windows_386.gz -O ${home_folder}pentest/scripts/chisel_1.8.1_windows_386.gz -q; \
    wget https://github.com/jpillora/chisel/releases/download/v1.8.1/chisel_1.8.1_linux_386.gz -O ${home_folder}pentest/scripts/chisel_1.8.1_linux_386.gz -q; \
    wget https://github.com/jpillora/chisel/releases/download/v1.8.1/chisel_1.8.1_linux_amd64.gz -O ${home_folder}pentest/scripts/chisel_1.8.1_linux_amd64.gz -q ;"
}


case "$1" in
     -r|--root)
     home_folder="/root/"
        if prompt_yes_no "Do you want to continue running the script as for the root user?";    then
        install_packages
	install_docker
	configure_system
	configure_default
	download_scripts
        # Proceed with running the script as root
           else
              echo "Exiting..."
              exit 0
        fi
        ;;
    -l|--logging)
       home_folder="/home/kali/"
       if prompt_yes_no "Do you want to continue running the script for logging?";    then
        install_packages
	install_docker
	configure_system
	configure_logging
	download_scripts
           else
              echo "Exiting..."
              exit 0
        fi
        ;;
    -d|--default)
       home_folder="/home/kali/"
       if prompt_yes_no "Do you want to continue running the script default for the kali user?";    then
        install_packages
	install_docker
	configure_system
	configure_default
	download_scripts
           else
              echo "Exiting..."
              exit 0
        fi
        ;;
    *)
        echo "Error: Invalid option '$1'"
        show_help
        exit 1
        ;;
esac



# Rest of your script goes here...
