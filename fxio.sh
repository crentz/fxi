#!/bin/bash

#       @(#)Copyright (c) 2023 Petre C. Crentz
#		( crentzc@gmail.com )
#       This file is provided in the hope that it will
#       be of use.  There is absolutely NO WARRANTY.
#       Permission to copy, redistribute or otherwise
#       use this file is hereby granted provided that
#       the this notice is to be left intact.
#       You may modify in any way but you have to mention
#
#		Fluxuan Linux 
#		in the begining thank you, for any help, 
#		https://fluxuan.org - https://forums.fluxuan.org
#		Thank you for your interest in Fluxuan Linux !!


CONF=${disk_conf:="/tmp/disk.conf"}
d_conf () {
	local _conf=$1 _value=$2
	printf '%s\n' "${_conf}=${_value}" >> "$CONF"
}
d_conf
d_read () {
	local _conf=$1
	grep "${_conf}" "$CONF" | cut -d '=' -f2
}
d_read

check_root () {if [ "$(id -u)" -ne 0 ]; then 
whiptail --title "Fluxuan-Installer" --msgbox "It appears that you are running this installer as user.

Please run as ROOT (e. g.:  sudo bash fluxuan-installer) 
-------------------------------------------------------
Thank you for your interest in Fluxuan Linux.

https://Fluxuan.org - https://Forums.Fluxuan.org" 20 70 ;
exit 1; 
else
	return 1;
fi

}
check_root
welcome_msg () {
whiptail --title "Fluxuan-Installer" --msgbox "Welcome to Fluxuan Linux Installer.

This installer will guide you to the rest of the setup process.
--------------------------------------------------------------
Thank you for your interest in Fluxuan Linux.

https://Fluxuan.org - https://Forums.Fluxuan.org" 20 70

}
welcome_msg

mode=$(whiptail --inputbox "Will you boot in bios or EFI mode (-- bios or EFI --)?
------------------------------------------------------" 20 70 bios --title "Fluxuan-Installer" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    d_conf MODE "$mode"
else
	rm "$CONF"
	clear ;
    exit 1 ;
fi
}
select_drive
create_swap() {
if (whiptail --title "Fluxuan-Installer" --yesno "Would you like to use SWAP?" 20 70); then
	d_conf SWAP "YES"
	else
  	return 0;
	fi
}
create_swap
partitioning() {
local _disk _mode
	_disk=$(d_read DISK)
	_mode=$(d_read MODE)
CHOICE=$(whiptail --title Fluxuan-Installer --menu "Choose one of the following options." 20 70 5 \
	1 "Guided - use entire disk ( recomended for new users )" 3>&2 2>&1 1>&3  \
	2 "Guided - separate boot partition" 3>&2 2>&1 1>&3  \
	3 "Guided - separate boot and home partitions" 3>&2 2>&1 1>&3  \
)
	case $CHOICE in

	1)
	function one {
	{
	if [ "$_mode" == "bios" ]; then
		parted -s /dev/"$_disk" mklabel msdos
		parted -s /dev/"$_disk" mkpart primary ext2 1 100%
		parted -s /dev/"$_disk" set 1 boot on 
	else
		parted -s /dev/"$_disk" mklabel msdos
		parted -s /dev/"$_disk" mkpart primary ext2 1 100%
		parted -s /dev/"$_disk" set 1 boot on
	fi	
	if [ "$_mode" == "bios" ]; then
		mkfs.ext4 /dev/"$_disk"1 >> /dev/null 2>&1
	else
		mkfs.ext4 /dev/"$_disk"1 >> /dev/null 2>&1
	fi
		partx -u /dev/"$_disk"
		mount /dev/"$_disk"1 /mnt
	if [ "$_mode" == "bios" ]; then
		mkdir -p /mnt/boot
	else
		mkdir -p /mnt/boot/efi
	fi
	for ((i=0; i<=100; i+=1)); do
        sleep 0.1
        echo "$i"
    done
} | whiptail --gauge "Partitioning your drive please wait..." 10 70 0
	}
	one
	;;
	
	2)
	function two {
	{
	if [ "$_mode" == "bios" ]; then
		parted -s /dev/"$_disk" mklabel msdos
		parted -s /dev/"$_disk" mkpart primary ext2 1 100MB
		parted -s /dev/"$_disk" set 1 boot on 
	else
		parted -s /dev/"$_disk" mklabel gpt
		parted -s /dev/"$_disk" mkpart primary ext2 1 100MB
		parted -s /dev/"$_disk" set 1 ESP on
	fi	
	parted -s /dev/"$_disk" mkpart primary ext2 100MB 100%
	mkfs.ext4 /dev/"$_disk"2 >> /dev/null 2>&1
	if [ "$_mode" == "bios" ]; then
		mkfs.ext4 /dev/"$_disk"1 >> /dev/null 2>&1
	else
		mkfs.fat -F 32 /dev/"$_disk"1 >> /dev/null 2>&1
	fi
		partx -u /dev/"$_disk"
		mount /dev/"$_disk"2 /mnt
	if [ "$_mode" == "bios" ]; then
		mkdir -p /mnt/boot
		mount /dev/"$_disk"1 /mnt/boot
	else
		mkdir -p /mnt/boot/efi
		mount /dev/"$_disk"1 /mnt/boot/efi
	fi
	for ((i=0; i<=100; i+=1)); do
        sleep 0.1
        echo "$i"
    done
} | whiptail --gauge "Partitioning your drive please wait..." 10 70 0
	}
	two
	;;
	
	3)
	function three {
	{	
	if [ "$_mode" == "bios" ]; then
		parted -s /dev/"$_disk" mklabel msdos
		parted -s /dev/"$_disk" mkpart primary ext2 1 100MB
		parted -s /dev/"$_disk" set 1 boot on 
	else
		parted -s /dev/"$_disk" mklabel gpt
		parted -s /dev/"$_disk" mkpart primary ext2 1 100MB
		parted -s /dev/"$_disk" set 1 ESP on
	fi	
	rsize=$(whiptail --inputbox "Size of your ROOT Partition (ex. 40GB)?\nThe rest of the drive will be HOME Partition.\n
------------------------------------------------------" 20 70 30GB --title "Fluxuan-Installer" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    parted -s /dev/"$_disk" mkpart primary ext2 100MB "$rsize"
    parted -s /dev/"$_disk" mkpart primary ext2 "$rsize" 100%
else
	whiptail --title "Fluxuan-Installer" --msgbox "Thank you for using Fluxuan-Installer.
 
If I can help in any way please do not hesitate to ask on our Forums!

https://fluxuan.org     https://forums.fluxuan.org" 20 70
	rm "$CONF"
	clear ;
    exit 1 ;
fi
	
	if [ "$_mode" == "bios" ]; then
		mkfs.ext4 /dev/"$_disk"1 >> /dev/null 2>&1
	else
		mkfs.fat -F 32 /dev/"$_disk"1 >> /dev/null 2>&1
	fi
	mkfs.ext4 /dev/"$_disk"2 >> /dev/null 2>&1
	mkfs.ext4 /dev/"$_disk"3 >> /dev/null 2>&1
		partx -u /dev/"$_disk"
		mount /dev/"$_disk"2 /mnt
		if [ "$_mode" == "bios" ]; then
		mkdir -p /mnt/boot
		mount /dev/"$_disk"1 /mnt/boot
	else
		mkdir -p /mnt/boot/efi
		mount /dev/"$_disk"1 /mnt/boot/efi
	fi
	mkdir -p /mnt/home
	mount /dev/"$_disk"3 /mnt/home
	for ((i=0; i<=100; i+=1)); do
        sleep 0.1
        echo "$i"
    done
} | whiptail --gauge "Partitioning your drive please wait..." 10 70 0
	}
	three
	;;
esac

}
partitioning

offline_inst () {
{
rsync -av --exclude={"/dev/*","/proc/*","/sys/*","/run/*","/tmp/*","/swapfile","/cdrom/*","/target","/live","/boot/grub/grub.cfg","/boot/grub/menu.lst","/boot/grub/device.map","/etc/udev/rules.d/70-persisten-cd.rules","/etc/udev/rules.d/70-persistent-net.rules","/etc/fstab","/etc/mtab","/home/snapshot","/home/fxs","/home/*/.gvfs","/mnt/*","/media/*","/lost+found","/usr/bin/welcome","/var/swapfile"} / /mnt
	
	i="0"
        while (true)
        do
            proc=$(ps aux | grep -v grep | grep -e "rsync")
            if [[ "$proc" == "" ]]; then break; fi
            # Sleep for a longer period if the database is really big 
            # as dumping will take longer.
            sleep 1
            echo $i
            i=$(expr $i + 1)
        done
        # If it is done then display 100%
        echo 100
        # Give it some time to display the progress to the user.
        sleep 2
} | whiptail --gauge "Offline install it might take a while, please wait...." 10 70 0
}
offline_inst

mk_swap () {
{
	local _swap
	_swap=$(d_read SWAP)
	mount --bind /dev/ /mnt/dev/
	mount --bind /proc/ /mnt/proc/
	mount --bind /sys/ /mnt/sys/
	bash -c 'genfstab -t LABEL /mnt >> /mnt/etc/fstab'
	if [ "$_swap" == "YES" ]; then
	chroot /mnt apt-get update
	chroot /mnt apt-get install dphys-swapfile -y -qq
	else
	return 0;
	fi
	i="0"
        while (true)
        do
            proc=$(ps aux | grep -v grep | grep -e "apt-get")
            if [[ "$proc" == "" ]]; then break; fi
            # Sleep for a longer period if the database is really big 
            # as dumping will take longer.
            sleep 1
            echo $i
            i=$(expr $i + 1)
        done
        # If it is done then display 100%
        echo 100
        # Give it some time to display the progress to the user.
        sleep 2
} | whiptail --gauge "Creating SWAP, it might take a while..." 10 70 0
}
mk_swap

choose_init () {
	CHOICE=$(whiptail --title Fluxuan-Installer --menu "Choose INIT system." 20 70 5 \
	1 "Sysvinit" 3>&2 2>&1 1>&3  \
	2 "OpenRC" 3>&2 2>&1 1>&3  \
	3 "Runit" 3>&2 2>&1 1>&3 \

)
case $CHOICE in
	1)
	function sysvinit {
	{
	chroot /mnt apt-get install sysvinit-core elogind libpam-elogind orphan-sysvinit-scripts systemctl -y
	  
	i="0"
        while (true)
        do
            proc=$(ps aux | grep -v grep | grep -e "apt-get")
            if [[ "$proc" == "" ]]; then break; fi
            # Sleep for a longer period if the database is really big 
            # as dumping will take longer.
            sleep 1
            echo $i
            i=$(expr $i + 1)
        done
        # If it is done then display 100%
        echo 100
        # Give it some time to display the progress to the user.
        sleep 2

} | whiptail --gauge "Installing init System, please be patient..." 10 70 0
	}
	sysvinit
	;;
	
	2)
	function openrc {
	{

	  chroot /mnt apt-get install sysvinit-core openrc elogind libpam-elogind orphan-sysvinit-scripts systemctl procps -y

	i="0"
        while (true)
        do
            proc=$(ps aux | grep -v grep | grep -e "apt-get")
            if [[ "$proc" == "" ]]; then break; fi
            # Sleep for a longer period if the database is really big 
            # as dumping will take longer.
            sleep 1
            echo $i
            i=$(expr $i + 1)
        done
        # If it is done then display 100%
        echo 100
        # Give it some time to display the progress to the user.
        sleep 2
} | whiptail --gauge "Installing init System, please be patient..." 10 70 0
	}
	openrc
	;;
	
	3)
	function runit {
	{

	  chroot /mnt apt-get install sysvinit-core runit elogind libpam-elogind orphan-sysvinit-scripts systemctl procps -y

	i="0"
        while (true)
        do
            proc=$(ps aux | grep -v grep | grep -e "apt-get")
            if [[ "$proc" == "" ]]; then break; fi
            # Sleep for a longer period if the database is really big 
            # as dumping will take longer.
            sleep 1
            echo $i
            i=$(expr $i + 1)
        done
        # If it is done then display 100%
        echo 100
        # Give it some time to display the progress to the user.
        sleep 2
} | whiptail --gauge "Installing init System, please be patient..." 10 70 0
	}
	runit
	esac
}
choose_init

set_hostname() {
hostname=$(whiptail --inputbox "Input your desired hostname" 10 70 fluxuan --title "Configuration..." 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    d_conf HOSTNAME "$hostname"
    echo "$hostname" > /mnt/etc/hostname
	cat <<EOF > /mnt/etc/hosts
127.0.0.1	localhost
127.0.1.1	$hostname
# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
else
whiptail --title "Fluxuan-Installer" --msgbox "Thank you for using Fluxuan-Installer.
 
If I can help in any way please do not hesitate to ask on our Forums!

https://fluxuan.org     https://forums.fluxuan.org" 20 70
	rm "$CONF"
	clear ;
    exit 1 ;
fi
}
set_hostname

timezone() {

	  chroot /mnt dpkg-reconfigure tzdata
	
}
timezone

locales() {

	  chroot /mnt dpkg-reconfigure locales

}
locales

xkb_cons() {

	  chroot /mnt dpkg-reconfigure keyboard-configuration
}
xkb_cons

set_pass() {
PASSWD=$(whiptail --title "Fluxuan-Installer" --passwordbox "Choose your ROOT Password." 10 70 3>&1 1>&2 2>&3)
PASSWD_CHECK=$(whiptail --title "Fluxuan-Installer" --passwordbox "Verify Root Password" 10 70 3>&1 1>&2 2>&3)

if [[ "$PASSWD" == "$PASSWD_CHECK" ]]; then
	chroot /mnt echo -e "$PASSWD\n$PASSWD" | passwd root
else
	whiptail --title "Fluxuan-Installer" --msgbox "Thank you for using Fluxuan-Installer.
 
If I can help in any way please do not hesitate to ask on our Forums!

https://fluxuan.org     https://forums.fluxuan.org" 20 70
	rm "$CONF"
	clear ;
    exit 1 ;
fi
}
set_pass

set_default_user() {
	oldname=$(awk -F: '/1000:1000/ { print $1 }' /mnt/etc/passwd)
	name=$(whiptail --inputbox "Create default USERNAME:" 10 70 fluxuan --title "Fluxuan-Installer" 3>&1 1>&2 2>&3)
	
	chroot /mnt usermod -l "$name" "$oldname"
	chroot /mnt usermod -d /home/"$name" -m "$name"
	sleep 1
	
    PASSWD_USER=$(whiptail --title "Fluxuan-Installer" --passwordbox "Choose USER Password." 10 70 3>&1 1>&2 2>&3)
	PASSWD_CHECK_USER=$(whiptail --title "Fluxuan-Installer" --passwordbox "Verify USER Password " 10 70 3>&1 1>&2 2>&3)
	if [[ "$PASSWD_USER" == "$PASSWD_CHECK_USER" ]]; then
	chroot /mnt echo -e "$PASSWD_USER\n$PASSWD_USER" | passwd "$name"
	else
	whiptail --title "Fluxuan-Installer" --msgbox "Thank you for using Fluxuan-Installer.
 
If I can help in any way please do not hesitate to ask on our Forums!

https://fluxuan.org     https://forums.fluxuan.org" 20 70
	rm "$CONF"
	clear ;
    exit 1 ;
    fi
}
set_default_user

setup_grub() {
{
	local _mode _disk
	_mode=$(d_read MODE)
	_disk=$(d_read DISK)
	if [ "$_mode" == "bios" ]; then
		  chroot /mnt apt-get install grub-pc -y 
		  chroot /mnt grub-install /dev/"$_disk" >> /dev/null 2>&1
		  chroot /mnt update-grub
	else
		  chroot /mnt apt-get install grub-efi-amd64 -y 
		  chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi >> /dev/null 2>&1
		  chroot /mnt update-grub
	fi
	i="0"
        while (true)
        do
            proc=$(ps aux | grep -v grep | grep -e "update-grub")
            if [[ "$proc" == "" ]]; then break; fi
            # Sleep for a longer period if the database is really big 
            # as dumping will take longer.
            sleep 1
            echo $i
            i=$(expr $i + 1)
        done
        # If it is done then display 100%
        echo 100
        # Give it some time to display the progress to the user.
        sleep 2
} | whiptail --gauge "Installing Grub please wait..." 6 70 0
}
setup_grub

finish() {
	oldn=$(awk -F: '/1000:1000/ { print $1 }' /mnt/etc/passwd)
	if (whiptail --title "Fluxuan-Installer" --yesno "Fluxuan is now installed. YES to reboot or NO to continue using live disk." 8 78); then
	rm "$CONF" ;
    reboot
	else
    rm "$CONF" ;
    exit 0 ;
	fi
}
finish
