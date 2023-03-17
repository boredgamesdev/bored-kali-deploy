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

# Change transparency of qterminal
sed -i 's/ApplicationTransparency=5/ApplicationTransparency=0/g' /home/kali/.config/qterminal.org/qterminal.ini


# Change default password
# Password hash generated with openssl passwd
touch kali-config/common/includes.chroot/usr/lib/live/config/0031-root-password && chmod +x $_
cat > kali-config/common/includes.chroot/usr/lib/live/config/0031-root-password << 'EOF'
#!/bin/sh

usermod -p 'RGGDUNbXi72Co' root
EOF

# Change hostname
hostnamectl set-hostname kalibored-${

# Blacklist pcspkr module
mkdir -p kali-config/common/includes.chroot/etc/modprobe.d && \
cat > kali-config/common/includes.chroot/etc/modprobe.d/nobeep.conf << 'EOF'
blacklist pcspkr
EOF

# Create directory to host profile.d scripts
mkdir -p kali-config/common/includes.chroot/etc/profile.d

# Configure console font
cat > kali-config/common/includes.chroot/etc/profile.d/set_font.sh << 'EOF'
setfont /usr/share/consolefonts/Uni3-TerminusBold20x10.psf.gz
EOF

# Configure environment
cat > kali-config/common/includes.chroot/etc/profile.d/set_environment.sh << 'EOF'
export PATH="$PATH:$HOME/.scripts"
export EDITOR='vim'
export VISUAL='vim'
EOF

# Configure timezone
cat > kali-config/common/includes.chroot/etc/profile.d/set_timezone.sh << 'EOF'
timedatectl set-timezone US/Mountain
EOF

# Configure tty colors
# https://github.com/joepvd/tty-solarized
cat > kali-config/common/includes.chroot/etc/profile.d/set_tty_colors.sh << 'EOF'
if [ "$TERM" = "linux" ]; then
    echo -en "\e]PB657b83" # S_base00
    echo -en "\e]PA586e75" # S_base01
    echo -en "\e]P0073642" # S_base02
    echo -en "\e]P62aa198" # S_cyan
    echo -en "\e]P8002b36" # S_base03
    echo -en "\e]P2859900" # S_green
    echo -en "\e]P5d33682" # S_magenta
    echo -en "\e]P1dc322f" # S_red
    echo -en "\e]PC839496" # S_base0
    echo -en "\e]PE93a1a1" # S_base1
    echo -en "\e]P9cb4b16" # S_orange
    echo -en "\e]P7eee8d5" # S_base2
    echo -en "\e]P4268bd2" # S_blue
    echo -en "\e]P3b58900" # S_yellow
    echo -en "\e]PFfdf6e3" # S_base3
    echo -en "\e]PD6c71c4" # S_violet
    clear # against bg artifacts
fi
EOF

################################################################################
# User configuration
################################################################################

# Set up slide
git clone https://github.com/csebesta/slide \
kali-config/common/includes.chroot/root/.slide \
&& cd kali-config/common/includes.chroot/root/.slide

# Remove files such that slide will stow correctly
rm ../.bashrc

# Stow directories
# Bash will fail to stow
for directory in */; do

	stow -t .. $directory > /dev/null 2>&1 \
	&& echo "Stowed $directory" \
	|| echo "Failed to stow $directory"

done

# Return to previous directory
cd - > /dev/null 2>&1

# Overwrite default xinitrc
cat > kali-config/common/includes.chroot/root/.xinitrc << 'EOF'
export PATH="$PATH:$HOME/.scripts"
xrdb ~/.Xresources
xsetroot -cursor_name left_ptr
backinfo
exec xmonad
EOF

################################################################################
# Software configuration
################################################################################

# Modify firefox preferences
# https://developer.mozilla.org/en-US/docs/Mozilla/Preferences/A_brief_guide_to_Mozilla_preferences
mkdir -p kali-config/common/includes.chroot/etc/firefox-esr && \
cat > kali-config/common/includes.chroot/etc/firefox-esr/kaliburn.js << 'EOF'
/* Kaliburn default settings */
lockPref("browser.startup.homepage", "https://google.com");
lockPref("browser.startup.homepage_override.mstone", "ignore");
EOF

################################################################################
# Isolinux configuration
################################################################################

# Modify splash screen
gm convert \
	-size 640x480 xc:#002b36 \
	kali-config/common/includes.binary/isolinux/splash.png

# Change color of background highlight (Base02)
# Color format is #AARRGGBB
sed -i 's/76a1d0ff/ff073642/g' kali-config/common/includes.binary/isolinux/stdmenu.cfg

# Remove menu entries
rm kali-config/common/hooks/live/persistence-menu.binary
rm kali-config/common/hooks/live/accessibility-menu.binary

# Add hook to remove other menu entries
touch kali-config/common/hooks/live/remove-menu.binary && chmod +x $_
cat > kali-config/common/hooks/live/remove-menu.binary << 'EOF'
#!/bin/bash
# Script to remove unwanted menu entries

if [ ! -d isolinux ]; then
	cd binary
fi

rm isolinux/install.cfg
EOF

################################################################################
# Build image
################################################################################

## Exit for testing purposes
#exit && echo "Exiting..."

## Build image for older hardware
#sed -i 's/686-pae/686/g' auto/config
#./build.sh --distribution kali-rolling --arch i386 --verbose

# Build image
./build.sh -v
