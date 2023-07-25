#!/bin/bash

echo Running LiveGUI stage2 fsscript ...

source /etc/profile
env-update
source /tmp/envscript

# No we don't want to run xdm...
sed -e '/^DISPLAYMANAGER=/s/.*/DISPLAYMANAGER="sddm"/' -i /etc/conf.d/display-manager
sed -e '/^CHECKVT=7/s/.*/CHECKVT=1/' -i /etc/conf.d/display-manager

# Don't let NM change hostname (this breaks xauth)
echo "[main]
plugins=keyfile 
hostname-mode=none" > /etc/NetworkManager/NetworkManager.conf

# start emerge sync
echo "[DEFAULT]
main-repo = gentoo

[gentoo]
location = /var/db/repos/gentoo
sync-type = rsync
sync-uri = rsync://rsync.kr.gentoo.org/gentoo-portage
auto-sync = yes
sync-rsync-verify-jobs = 1
sync-rsync-verify-metamanifest = yes
sync-rsync-verify-max-age = 24
sync-openpgp-key-path = /usr/share/openpgp-keys/gentoo-release.asc
sync-openpgp-key-refresh-retry-count = 40
sync-openpgp-key-refresh-retry-overall-timeout = 1200
sync-openpgp-key-refresh-retry-delay-exp-base = 2
sync-openpgp-key-refresh-retry-delay-max = 60
sync-openpgp-key-refresh-retry-delay-mult = 4" > /etc/portage/repos.conf/gentoo.conf
emerge --sync

# Autologin via sddm to plasma
echo "[Autologin]
User=gentoo
Session=plasma.desktop
Relogin=true" > /etc/sddm.conf

# Set Default Password
sed -i "s/enforce=everyone/enforce=none/" /etc/security/passwdqc.conf
#echo "root:\$rootpassword" | chpasswd
yes root | passwd root
# useradd gentoo
# yes gentoo  | passwd gentoo

# set group for run jwm X11
gpasswd -a gentoo wheel
gpasswd -a gentoo weston-launch
gpasswd -a gentoo vboxusers
gpasswd -a gentoo docker
gpasswd -a gentoo vboxguest
gpasswd -a gentoo vboxsf
gpasswd -a gentoo video
gpasswd -a gentoo input

# Set up gentoo user
pushd /home/gentoo
mkdir -pv .config Desktop

# Disable screen lock
echo "[Daemon]
Autolock=false" > .config/kscreenlockerrc

# install cappucchin theme for various apps
# vscode -  https://github.com/catppuccin/vscode
codium --no-sandbox --install-extension Catppuccin.catppuccin-vsc 
# jetbrain - https://github.com/catppuccin/jetbrains/blob/main/gradle.properties
# pycharm installPlugins org.rust.lang https://github.com/catppuccin/jetbrains/releases/download/v2.2.0/Catppuccin.Theme-2.2.0.jar
# sddm
git clone https://github.com/catppuccin/sddm.git .config/repo/sddm_theme
cp -rf .config/repo/sddm_theme/src/catppuccin-frappe /usr/share/sddm/themes
echo "[Theme]
Current=catppuccin-frappe" >> /etc/sddm.conf
# alarcritty - https://github.com/catppuccin/alacritty
git clone https://github.com/catppuccin/alacritty.git .config/alacritty/catppuccin 
cp -rf .config/alacritty/catppuccin/catppuccin-frappe.yml .config/alacritty.yml
# echo "set -g default-terminal \"xterm-256color\"
# set-option -ga terminal-overrides \",xterm-256color:Tc\"" > .bashrc
sed -i 's/TERM: .*/TERM: xterm-256color/g' .config/alacritty.yml

# conky theme installation - not working
git clone https://github.com/jxai/lean-conky-config .config/conky

# startx
mkdir -p .local/bin
echo "TTY=\`tty\`
xinit /usr/bin/jwm -- vt\${TTY:8}" > .local/bin/startx
chmod +x .local/bin/startx
echo "export PATH=\$HOME/.local/bin:\$PATH" >> .bashrc

# owl files
git clone https://github.com/owl4ce/dotfiles.git .config/repo/owl4ce_dotfiles
# cp -rf .config/repo/owl4ce_dotfiles/.config/tint2/* .config/tint2/

# jwm settings manager
git clone https://github.com/ZwerG-MaX/jwm-settings-manager.git .config/repo/jsm
mkdir -p .config/repo/jsm/bin/Release
# jwm settings manager compilation
pushd ".config/repo/jsm/bin/Release" >/dev/null
cmake ../..
popd >/dev/null

# fonts install
mkdir -pv .fonts/{Cantarell,Comfortaa,IcoMoon-Custom,Nerd-Patched,Unifont}
wget --no-hsts -cNP .fonts/Comfortaa/ https://raw.githubusercontent.com/googlefonts/comfortaa/main/fonts/OTF/Comfortaa-{Bold,Regular}.otf
wget --no-hsts -cNP .fonts/IcoMoon-Custom/ https://github.com/owl4ce/dotfiles/releases/download/ng/{Feather,Material}.ttf
wget --no-hsts -cNP .fonts/Nerd-Patched/ https://github.com/owl4ce/dotfiles/releases/download/ng/M+.1mn.Nerd.Font.Complete.ttf
wget --no-hsts -cNP .fonts/Nerd-Patched/ https://github.com/owl4ce/dotfiles/releases/download/ng/{M+.1mn,Iosevka}.Nerd.Font.Complete.Mono.ttf
wget --no-hsts -cNP .fonts/Unifont/ https://unifoundry.com/pub/unifont/unifont-14.0.02/font-builds/unifont-14.0.02.ttf
wget --no-hsts -cN https://download-fallback.gnome.org/sources/cantarell-fonts/0.303/cantarell-fonts-0.303.1.tar.xz
tar -xvf cantarell*.tar.xz --strip-components 2 --wildcards -C .fonts/Cantarell/ \*/\*/Cantarell-VF.otf
rm -rf cantarell*.tar.xz

# icons install
wget -q -O - "https://github.com/owl4ce/dotfiles/releases/download/ng/Gladient_JfD.tar.xz" | tar Jxvf - -C /usr/share/icons/
wget -q -O - "https://github.com/owl4ce/dotfiles/releases/download/ng/Papirus-Custom.tar.xz" | tar Jxvf - -C /usr/share/icons/
wget -q -O - "https://github.com/owl4ce/dotfiles/releases/download/ng/Papirus-Dark-Custom.tar.xz" | tar Jxvf - -C /usr/share/icons/

# Vivaldi as default browser
echo \
"[Added Associations]
inode/directory=org.kde.dolphin.desktop;
x-scheme-handler/http=vivaldi-snapshot.desktop;
x-scheme-handler/https=vivaldi-snapshot.desktop;

[Default Applications]
inode/directory=org.kde.dolphin.desktop;
x-scheme-handler/http=vivaldi-snapshot.desktop;
x-scheme-handler/https=vivaldi-snapshot.desktop;" \
 > .config/mimeapps.list

# Customize taskbar pinned apps
# wget "https://dev.gentoo.org/~bkohler/livegui/plasma-org.kde.plasma.desktop-appletsrc" -O \
# 	.config/plasma-org.kde.plasma.desktop-appletsrc

# User face image
wget "https://dev.gentoo.org/~bkohler/livegui/face.icon.png" -O .face.icon

# Desktop icon setups
DESKTOP_APPS=( org.kde.konsole firefox org.kde.dolphin )
for i in "${APPS[@]}"; do
	ln -sv /usr/share/applications/${i}.desktop Desktop/
done

# generate JWM menu
mmaker -t Alacritty JWM -c > .jwmrc

# font change
sed -i 's/<Font>Sans-9/<Font>NanumGothic/' .jwmrc

# jwmrc start
sed -i 's/<JWM>/<JWM><StartupCommand>Alacritty<\/StartupCommand><StartupCommand>vivaldi-snapshot<\/StartupCommand><StartupCommand>scim<\/StartupCommand><StartupCommand>.config\/conky\/start-lcc.sh<\/StartupCommand>/g' .jwmrc

# Autostart keyboard layout module
# mkdir -p .config/autostart
# echo "[Desktop Entry]
# Version=1.0
# Name=Keyboard settings
# Icon=preferences-system
# Type=Application
# SingleMainWindow=true
# Exec=systemsettings5 kcm_keyboard
# Terminal=false
# " > .config/autostart/systemsettings-keyboard.desktop

popd # /home/gentoo pop

# Clean up perms
chown -R gentoo:users /home/gentoo

# Let some tools run as root
mkdir -p /etc/polkit-1/rules.d/
echo 'polkit.addRule(function(action, subject) {
    if (action.id == "org.gnome.gparted") {
        return polkit.Result.YES;
    }
});

polkit.addRule(function(action, subject) {
    if (action.id == "org.kde.kpmcore.externalcommand.init") {
        return polkit.Result.YES;
    }
});

polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.udisks2.filesystem-mount-system") {
        return polkit.Result.YES;
    }
});' > /etc/polkit-1/rules.d/livegui-root-tools.rules
