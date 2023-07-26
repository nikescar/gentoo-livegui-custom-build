#!/bin/bash

# set upstream portage repository for later use
set -x \
&& mkdir -p /etc/portage/repos.conf \
&& echo "\
[DEFAULT] 
main-repo = gentoo 

[gentoo] 
location = /var/db/repos/gentoo 
sync-type = git 
sync-uri = https://github.com/gentoo/gentoo.git
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

cat /etc/portage/repos.conf/gentoo.conf
eval ./update_iso.sh