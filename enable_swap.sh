#!/bin/bash
APPROOT_DIR="`pwd`/../"
fallocate -l 32G $APPROOT_DIR/swapfile
chmod 0600 $APPROOT_DIR/swapfile 
mkswap $APPROOT_DIR/swapfile 
swapoff -a
swapon $APPROOT_DIR/swapfile 
swapon -s 
