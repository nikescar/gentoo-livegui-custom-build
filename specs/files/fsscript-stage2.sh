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

# conv icons app
cat <<EOF >  /bin/convicon24.sh
#!/bin/bash
if [ -z "\${1}" ] || [ ! -d "\${1}" ];then
 echo "Please input correct source directy path."
 echo "Usage: convert all svg files from src dir to target dir"
 echo "convicon24.sh src_dir target_dir"
 exit 1
fi
if [ -z "\${2}" ] || [ ! -d "\${2}" ] ;then
 echo "Please input correct target directy path."
 echo "Usage: convert all svg files from src dir to target dir"
 echo "convicon24.sh src_dir target_dir"
 exit 1
fi
for filepath in \${1}/*; do
  filename="\$(basename -s .gz \$filepath)"
  if [[ \$filename == *.svg ]];then
    echo "\${1}/\${filename:-4}.svg -> \${2}/\${filename:-4}.png"
    rsvg-convert -w 24 -h 24 -o \${2}/\${filename::-3}png \${1}/\$filename
  fi
done
EOF
chmod 755 /bin/convicon24.sh

# icons install
ICONS_DIR="../../usr/share/icons"
mkdir -p $ICONS_DIR/jwm
wget -q -O - "https://github.com/owl4ce/dotfiles/releases/download/ng/Gladient_JfD.tar.xz" | tar Jxvf - -C $ICONS_DIR/
cp -rf $ICONS_DIR/Gladient/* $ICONS_DIR/jwm
wget -q -O - "https://github.com/numixproject/numix-icon-theme-circle/archive/refs/tags/23.07.21.tar.gz" | tar zxvf - -C $ICONS_DIR/
/bin/convicon24.sh $ICONS_DIR/numix-icon-theme-circle-23.07.21/Numix-Circle/48/apps $ICONS_DIR/jwm
wget -q -O - "https://github.com/vinceliuice/Qogir-icon-theme/archive/refs/tags/2023-06-05.tar.gz" | tar zxvf - -C $ICONS_DIR/
/bin/convicon24.sh $ICONS_DIR/Qogir-icon-theme-2023-06-05/src/scalable/actions $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/Qogir-icon-theme-2023-06-05/src/scalable/apps $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/Qogir-icon-theme-2023-06-05/src/scalable/devices $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/Qogir-icon-theme-2023-06-05/src/scalable/places $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/Qogir-icon-theme-2023-06-05/src/scalable/status $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/Qogir-icon-theme-2023-06-05/src/scalable/mimetypes $ICONS_DIR/jwm
wget -q -O - "https://github.com/vinceliuice/vimix-icon-theme/archive/refs/tags/2023-06-26.tar.gz" | tar zxvf - -C $ICONS_DIR/
/bin/convicon24.sh $ICONS_DIR/vimix-icon-theme-2023-06-26/src/scalable/apps $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/vimix-icon-theme-2023-06-26/src/scalable/categories $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/vimix-icon-theme-2023-06-26/src/scalable/devices $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/vimix-icon-theme-2023-06-26/src/scalable/mimetypes $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/vimix-icon-theme-2023-06-26/src/scalable/places $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/vimix-icon-theme-2023-06-26/src/scalable/preferences $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/vimix-icon-theme-2023-06-26/src/scalable/status $ICONS_DIR/jwm
wget -q -O - "https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/refs/tags/20230601.tar.gz" | tar zxvf - -C $ICONS_DIR/
/bin/convicon24.sh $ICONS_DIR/papirus-icon-theme-20230601/Papirus/64x64/apps $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/papirus-icon-theme-20230601/Papirus/64x64/devices $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/papirus-icon-theme-20230601/Papirus/64x64/mimetypes $ICONS_DIR/jwm
/bin/convicon24.sh $ICONS_DIR/papirus-icon-theme-20230601/Papirus/64x64/places $ICONS_DIR/jwm

# pcmanfm rightclick menu
mkdir -p .local/share/file-manager/actions
echo "[Desktop Entry]
Type=Action
Tooltip=Open Terminal
Name=Open Terminal
Profiles=profile-one;
Icon=utilities-terminal

[X-Action-Profile profile-one]
MimeTypes=inode/directory;
Exec=alacritty --working-directory %f
Name=Default profile" > .local/share/file-manager/actions/terminal.desktop

echo "[Desktop Entry]
Type=Action
Tooltip=Open VSCodium
Name=Open VSCodium
Profiles=profile-one;
Icon=utilities-terminal

[X-Action-Profile profile-one]
MimeTypes=inode/directory;
Exec=vscodium %f
Name=Default profile" > .local/share/file-manager/actions/vscodium.desktop

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
mkdir -p .jwm
mmaker -t Alacritty JWM -c > .jwm/mmaker.jwm

# font change
sed -i 's/<Font>Sans-9/<Font>NanumGothic/' .jwm/mmaker.jwm
# icon path change 
sed -i 's/\/usr\/share\/icons\/wm-icons\/32x32-aquafusion/\/usr\/share\/icons\/jwm\//' .jwm/mmaker.jwm

# generate .jwmrc
cat <<EOF > .jwmrc
<?xml version="1.0"?>
<JWM>
    <StartupCommand>nm-connection-editor</StartupCommand>
    <StartupCommand>alacritty</StartupCommand>
    <StartupCommand>vivaldi-snapshot</StartupCommand>
    <StartupCommand>scim</StartupCommand>
    <StartupCommand>.config/conky/start-lcc.sh</StartupCommand>

    <Include>.jwm/mmaker.jwm</Include>
    
    <!-- Tray at the bottom. -->
    <Tray x="0" y="-1" autohide="off">
        <TrayButton icon="appimagekit-stretchly.png" popup="start">root:1</TrayButton>
        <Spacer width="2"/>
        <TrayButton icon="folder-white-desktop.png">showdesktop</TrayButton>
        <TrayButton icon="networkmanager.png">exec:nm-connection-editor</TrayButton>
        <Spacer width="2"/>
        <TrayButton icon="Alacritty.png">exec:alacritty</TrayButton>
        <TrayButton icon="vivaldi-snapshot.png">exec:vivaldi-snapshot</TrayButton>
        <TrayButton icon="filemanager-actions.png">exec:pcmanfm</TrayButton>
        <TrayButton icon="vscodium.png">exec:vscodium</TrayButton>
        <TrayButton icon="telegram-desktop.png">exec:telegram-desktop</TrayButton>
        <TrayButton icon="logseq.png">exec:logseq</TrayButton>
        <TrayButton icon="meld.png">exec:meld</TrayButton>
        <TrayButton icon="pycharm-community.png">exec:pycharm-community</TrayButton>
        <Pager labeled="true"/>
        <TaskList maxwidth="256"/>
        <Dock/>
        <Clock format="%H:%M"><Button mask="123">exec:xclock</Button></Clock>
    </Tray>

    <!-- Options for program groups. -->
    <Group>
        <Option>tiled</Option>
        <Option>aerosnap</Option>
    </Group>
    <Group>
        <Class>telegram-desktop</Class>
        <Option>sticky</Option>
    </Group>
    <Group>
        <Name>Alacritty</Name>
        <Option>vmax</Option>
    </Group>
    <Group>
        <Name>xclock</Name>
        <Option>drag</Option>
        <Option>notitle</Option>
    </Group>

    <!-- Path where icons can be found.
         IconPath can be listed multiple times to allow searching
         for icons in multiple paths.
      -->
    <IconPath>
        /usr/share/icons/jwm/
    </IconPath>

    <!-- Alt + f -->
    <Key mask="A" key="f">exec:pcmanfm</Key>
    <Key mask="A" key="t">exec:alacritty</Key>
</JWM>
EOF

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
