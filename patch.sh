#!/bin/bash

################################################################################
# Copyright (c) [2024] [Ravindu Deshan]
#
# Unauthorized publication is prohibited. Forks and personal use are allowed.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
################################################################################

WDIR=$(pwd)
MAGISKBOOT=$WDIR/bin/magiskboot
AVBTOOL=$WDIR/bin/avbtool
KPTOOLS=$WDIR/bin/kptools-linux
KPIMG=$WDIR/bin/kpimg-android

RED="\e[1;31m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
GREEN="\e[1;32m"
RESET="\e[0m"
LEMON="\e[1;92m"
clear

banner(){
    echo -e "${GREEN} - APatch Installer for Samsung - ${RESET}"
    echo -e "${RED}       by @ravindu644 ${RESET}\n"
}

dependencies() {
    echo -e "${RED}[+] Installing requirements...${RESET}\n"
	sudo apt update -y > /dev/null 2>&1
	sudo apt install lz4 openssl python3 python-is-python3 -y > /dev/null 2>&1
    chmod +x $WDIR/bin/*	
	echo -e "\n${GREEN}[i] Requirements Installation Finished..!${RESET}\n"
}

checks(){
    if [ ! -d "workspace" ]; then
        mkdir workspace > /dev/null 2>&1
    fi
    rm -rf $WDIR/workspace/*
	if [ -f boot.img.lz4 ];then
		lz4 -B6 --content-size -f boot.img.lz4 boot.img
	fi    
    
    if [ ! -f "boot.img" ]; then
        echo -e "${RED}[!] Please put your boot.img inside the folder..! ${RESET}"
        echo -e "${RED}[i] Aborting... ${RESET}"
        exit 1
    fi

}

hexpatch(){
    cd $WDIR
    cp boot.img workspace; cd workspace

    echo " "
    echo -e "${GREEN}[+] Generating a signing key...${RESET}"

	if [ ! -f sign.pem ];then
	    openssl genrsa -f4 -out sign.pem 4096 > /dev/null 2>&1
	fi
    
    echo -e "${GREEN}[+] Unpacking boot image...${RESET}\n"
    $MAGISKBOOT unpack boot.img

    # Remove Samsung RKP    
    echo " "
    echo -e "${RED}[+] Patching Samsung Real-time Kernel Protection...${RESET}"

    $MAGISKBOOT hexpatch kernel 49010054011440B93FA00F71E9000054010840B93FA00F7189000054001840B91FA00F7188010054 A1020054011440B93FA00F7140020054010840B93FA00F71E0010054001840B91FA00F7181010054
    $MAGISKBOOT hexpatch kernel 290E0054011440B93FA00F71C90D0054010840B93FA00F71690D0054001840B91FA00F71090D0054 41030054011440B93FA00F71E0020054010840B93FA00F7180020054001840B91FA00F7120020054

    # Remove Samsung defex
    echo -e "${RED}[+] Patching Samsung DEFEX...${RESET}\n"      
    $MAGISKBOOT hexpatch kernel 821B8012 E2FF8F12
    $MAGISKBOOT hexpatch kernel 736B69705F696E697472616D667300 77616E745F696E697472616D667300
   
}

kpatch(){

    echo -e "\n${BLUE}- APatch Boot Image Patcher -${RESET}\n"
    read -p "Enter your Superkey : " SUPERKEY

    if [ ! -d "$WDIR/kpatch" ]; then
        cd $WDIR; mkdir kpatch
    fi

    mv $WDIR/workspace/kernel $WDIR/kpatch ; cd $WDIR/kpatch
    $KPTOOLS -p -i kernel -k $KPIMG -s "$SUPERKEY" -o image-patched

    if [ ! -f "image-patched" ]; then
        echo -e "\n${RED}[!] Patch failed..!${RESET}"
        echo -e "\n${RED}[!] Aborting..${RESET}"
        exit 1
    else
        mv image-patched $WDIR/workspace/kernel
        rm -rf $WDIR/kpatch
    fi

    # Repacking boot image
    cd $WDIR/workspace  
    echo -e "\n${GREEN}[+] Repacking boot image...${RESET}\n"    
    $MAGISKBOOT repack boot.img    

    #Signing boot image
    python3 "$AVBTOOL" extract_public_key --key sign.pem --output sign.pub.bin 
    python3 "$AVBTOOL" add_hash_footer --partition_name boot --partition_size $(wc -c new-boot.img |cut -f 1 -d ' ') --image new-boot.img --key sign.pem --algorithm SHA256_RSA4096
    mv new-boot.img $WDIR/boot-patched.img
    rm -rf $WDIR/workspace/*    
    echo -e "\n${BLUE}[+] Done...${RESET}"     
    
}

banner
dependencies
checks
hexpatch
kpatch