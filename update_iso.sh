#!/bin/bash
# repo url : https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/
# mirror url : https://ftp.kaist.ac.kr/gentoo/releases/amd64/autobuilds/
REPO_URL="https://ftp.kaist.ac.kr/gentoo/releases/"
ARCH="amd64"
FARCH=${ARCH}
VARIANT="hardened-openrc"

BUILD_SRCDIR_BASE="`pwd`/catalyst"
BUILD_SRCDIR="${BUILD_SRCDIR_BASE}/builds/default/"

# install nessasary apps
if ! command -v catalyst &> /dev/null
then
    emerge catalyst eselect 
fi

# add new hardened profile
# https://wiki.gentoo.org/wiki/Profile_%28Portage%29#Creating_custom_profiles
PROFILE_PATH="/var/db/repos/gentoo/profiles/"
#cp -rf hardened-desktop ${PROFILE_PATH}
#echo `portageq envvar ARCH` hardened-desktop dev >> ${PROFILE_PATH}profiles.desc

# update catalyst static config files
sed -i "s|storedir = .*|storedir = \"${BUILD_SRCDIR_BASE}\"|g" catalyst.conf
cp catalyst.conf /etc/catalyst/catalyst.conf

# update releng repository
if [[ ! -d ./releng ]]; then
    echo "cloning releng git repository..."
    git clone https://gitweb.gentoo.org/proj/releng.git releng
else
    echo "updating releng git repository..."
    pushd "./releng" >/dev/null
    git checkout .
    git pull

    # patch catalyst-auto shellscript
    echo "patching catalyst-auto script file..."
    git apply ../make-catalyst-auto-precompiled.patch
    popd >/dev/null
fi

# virtualbox-modules kernel patch
sed -i "s/# CONFIG_JUMP_LABEL is not set/CONFIG_JUMP_LABEL=y/" ./releng/releases/kconfig/amd64/amd64-6.1.38.config

# update stage3 from gentoo repo
FILERELPATH=$(curl --location "$REPO_URL$ARCH/autobuilds/latest-stage3-$FARCH-$VARIANT.txt" | sed '/^#/d' | cut -f1 -d" " )
FILENAME=$(echo ${FILERELPATH}|cut -f2 -d"/") # stage3-amd64-desktop-openrc-20230711T174853Z.tar.xz
FILENAME_TEMPLATE=$(echo "$FILENAME"|cut -d"-" -f1,2,3)
PREBUILT_TIMESTAMP=$(echo ${FILERELPATH}|cut -f1 -d"/"|cut -f1 -d".") # 20230711T174853Z
# echo "timestamp : ${PREBUILT_TIMESTAMP}"
FILEABSPATH="$REPO_URL$ARCH/autobuilds/$FILERELPATH"

# check if the stage3 file already downloaded
mkdir -p $BUILD_SRCDIR
if [[ ! -f $BUILD_SRCDIR$FILENAME ]]; then
    echo "downloading stage3 file..."
    # remove old file and download new file
    rm -rf "$BUILD_SRCDIR$FILENAME_TEMPLATE"*
    # echo "$BUILD_SRCDIR$FILENAME_TEMPLATE*"
    # echo "$FILEABSPATH"
    wget -O "$BUILD_SRCDIR$FILENAME" "$FILEABSPATH"
fi

# update package overlys to ./overlys dir
mkdir -p ./overlays
pushd "./overlays" >/dev/null
folder="guru"
if ! git clone "https://github.com/gentoo-mirror/guru.git" "${folder}" 2>/dev/null && [ -d "${folder}" ] ; then
    pushd "$folder" >/dev/null
    git fetch -q
    popd >/dev/null
fi 
folder="mschiff"
if ! git clone "https://cgit.gentoo.org/dev/mschiff.git" "${folder}" 2>/dev/null && [ -d "${folder}" ] ; then
    pushd "$folder" >/dev/null
    git fetch -q
    popd >/dev/null
fi 
folder="zugaina"
if ! [ -d "${folder}" ] ; then
    pushd "$folder" >/dev/null
    rsync -a rsync://gentoo.zugaina.org/zugaina-portage .
    popd >/dev/null
fi
popd >/dev/null

mkdir -p ./catalyst/builds/default
# run build
echo "running catalyst-auto..."
eval ./releng/tools/catalyst-auto --config ./catalyst-auto-custom.conf --prebuilt ${PREBUILT_TIMESTAMP} --verbose

# print iso path
ls $BUILD_SRCDIR