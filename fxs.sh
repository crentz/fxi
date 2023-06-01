#!/bin/bash

#       @(#)Copyright (c) 2023 Petre C. Crentz
#
#       This file is provided in the hope that it will
#       be of use.  There is absolutely NO WARRANTY.
#       Permission to copy, redistribute or otherwise
#       use this file is hereby granted provided that
#       the above copyright notice and this notice are
#       left intact.
#
#		Fluxuan Linux Snapshot Tool
#	
#		https://fluxuan.org - https://forums.fluxuan.org
#		Thank you for your interest in Fluxuan Linux !!

conf=${disk_conf:="/tmp/disk.conf"}
d_conf() {
# writing to disk.txt
	local _conf=$1 _value=$2
	printf '%s\n' "${_conf}=${_value}" >> "$conf"
	
}
d_read() {
# reading from disk.txt
	local _conf=$1
	grep "${_conf}" "$conf" | cut -d '=' -f2
}
check_root (){
# check if running as root
[[ $(id -u) -eq 0 ]] || { echo -e "\t You need to be root!\n" ; exit 1 ; }
}


welcome_msg () {
whiptail --title "Fluxuan-Snapshot" --msgbox "Welcome to Fluxuan-Snapshot utility.
Fluxuan-Snapshot will create a bootable ISO Snapshot.
Fluxuan-Installer is included so you can restore.
Thank you for your interest in Fluxuan Linux. 

https://fluxuan.org   -   https://Forums.Fluxuan.org" 15 65

}

ask_part () {

hostname=$(whiptail --inputbox "Input your desired hostname" 8 78 fluxuan --title "Configuration..." 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    d_conf HOSTNAME "$hostname"
else
    rm "$conf" ;
    exit 1 ;
fi


ISONAME=$(whiptail --inputbox "Input your desired ISONAME" 8 78 Fluxuan-Linux --title "Configuration..." 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    d_conf ISONAME "$ISONAME"
else
    rm "$conf" ;
     exit 1 ;
fi



LABEL=$(whiptail --inputbox "Input your desired disk LABEL" 8 78 Fluxuan-Linux --title "Configuration..." 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
    d_conf LABEL "$LABEL"
else
    rm "$conf" ;
     exit 1 ;
fi
}

install_dep () {
 {
apt-get update && apt-get install rsync live-boot debootstrap squashfs-tools xorriso isolinux syslinux-efi grub-pc-bin grub-efi-amd64-bin grub-efi-ia32-bin mtools dosfstools resolvconf arch-install-scripts -y -qq &

for ((i=0; i<=100; i+=1)); do
        proc=$(pgrep -w "apt-get")
            if [[ "$proc" == "" ]]; then break; fi
            # Sleep for a longer period if the database is really big 
            # as dumping will take longer.
            sleep 1
            echo "$i"
           
        i=(expr "$i" + 1)
        done
        # If it is done then display 100%
        echo 100
        # Give it some time to display the progress to the user.
        sleep 2
} | whiptail --gauge "Installing Dependencies..." 6 60 0
}

create_folders () {
{
mkdir -p /home/fxs /home/fxs/chroot
mkdir -p /home/fxs/{staging/{EFI/BOOT,boot/grub/x86_64-efi,isolinux,live},tmp} 
for ((i=0; i<=100; i+=1)); do
        sleep 0.1
        echo "$i"
    done
} | whiptail --gauge "Creating Folders..." 6 60 0
}

get_system () {
{
rsync -av --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","/home/fxs","/home/snapshot"} /* /home/fxs/chroot
for ((i=0; i<=100; i+=1)); do
        proc=$(pgrep -w "rsync")
            if [[ "$proc" == "" ]]; then break; fi
            # Sleep for a longer period if the database is really big 
            # as dumping will take longer.
            sleep 10
            echo "$i"
           
        i=(expr "$i" + 1)
        done
        # If it is done then display 100%
        echo 100
        # Give it some time to display the progress to the user.
        sleep 2
} | whiptail --gauge "Preparing Filesystems...." 6 60 0
}
touch_boot () {
 {
touch /home/fxs/staging/isolinux/isolinux.cfg
touch /home/fxs/staging/boot/grub/grub.cfg
touch /home/fxs/tmp/grub-embed.cfg
 for ((i=0; i<=100; i+=1)); do
        sleep 0.1
        echo "$i"
    done
} | whiptail --gauge "Preparing Boot Files...." 6 60 0
}
copy_boot () {
{
printf "" > /home/fxs/chroot/etc/fstab
cp /etc/resolv.conf /home/fxs/chroot/etc/
cp /home/fxs/chroot/boot/vmlinuz-* /home/fxs/staging/live/vmlinuz
cp /home/fxs/chroot/boot/initrd.img-* /home/fxs/staging/live/initrd
cp /home/fxs/staging/boot/grub/grub.cfg /home/fxs/staging/EFI/BOOT/
cp /usr/lib/ISOLINUX/isolinux.bin /home/fxs/staging/isolinux/
cp /usr/lib/syslinux/modules/bios/* /home/fxs/staging/isolinux/
cp -r /usr/lib/grub/x86_64-efi/* /home/fxs/staging/boot/grub/x86_64-efi/
for ((i=0; i<=100; i+=1)); do
        sleep 0.1
        echo "$i"
    done
} | whiptail --gauge "Copying Boot Files...." 6 60 0
}

set_hostname() {
{
local _hostname
	_hostname=$(d_read HOSTNAME)
	echo "$_hostname" > /home/fxs/chroot/etc/hostname
	cat <<EOF > /home/fxs/chroot/hosts
127.0.0.1	localhost
127.0.1.1	$_hostname
# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
for ((i=0; i<=100; i+=1)); do
        sleep 0.1
        echo "$i"
    done
} | whiptail --gauge "Setting your hostname...." 6 60 0
}
print_menu () {
{
local _ISONAME _LABEL
	_ISONAME=$(d_read ISONAME)
	_LABEL=$(d_read LABEL)
printf "UI vesamenu.c32\n
\n
MENU TITLE $_ISONAME\n
DEFAULT linux\n
TIMEOUT 600\n
MENU RESOLUTION 640 480\n
MENU COLOR border       30;44   #40ffffff #a0000000 std\n
MENU COLOR title        1;36;44 #9033ccff #a0000000 std\n
MENU COLOR sel          7;37;40 #e0ffffff #20ffffff all\n
MENU COLOR unsel        37;44   #50ffffff #a0000000 std\n
MENU COLOR help         37;40   #c0ffffff #a0000000 std\n
MENU COLOR timeout_msg  37;40   #80ffffff #00000000 std\n
MENU COLOR timeout      1;37;40 #c0ffffff #00000000 std\n
MENU COLOR msg07        37;40   #90ffffff #a0000000 std\n
MENU COLOR tabmsg       31;40   #30ffffff #00000000 std\n
MENU BACKGROUND /boot/splash.png\n
\n
LABEL linux\n   
MENU LABEL $_ISONAME\n
MENU DEFAULT\n  
KERNEL /live/vmlinuz\n   
APPEND initrd=/live/initrd boot=live\n\n   
$_LABEL\n   
MENU LABEL $_ISONAME\n   
MENU DEFAULT\n
KERNEL /live/vmlinuz\n
APPEND initrd=/live/initrd boot=live nomodeset\n
EOF" > /home/fxs/staging/isolinux/isolinux.cfg

printf "insmod part_gpt\n
insmod part_msdos\n
insmod fat\n
insmod iso9660\n
\n
insmod all_video\n
insmod font\n
background_image /boot/splash.png\n
\n
set default=\"0\"\nset timeout=30\n
\n
# If X has issues finding screens, experiment with/without nomodeset.\n
\nmenuentry \$_ISONAME\ {\n    
search --no-floppy --set=root --label '$_LABEL'\n
linux (\$root)/live/vmlinuz boot=live\n    
initrd (\$root)/live/initrd\n}\n
\nmenuentry \$_ISONAME\ {\n    
search --no-floppy --set=root --label '$_LABEL'\n    
linux (\$root)/live/vmlinuz boot=live nomodeset\n    
initrd (\$root)/live/initrd\n}\n
EOF" > /home/fxs/staging/boot/grub/grub.cfg

printf "if ! [ -d \"\$cmdpath\" ]; then\n    
# On some firmware, GRUB has a wrong cmdpath when booted from an optical disc.\n    
# https://gitlab.archlinux.org/archlinux/archiso/-/issues/183\n    
if regexp --set=1:isodevice '^(\([^)]+\))\/?[Ee][Ff][Ii]\/[Bb][Oo][Oo][Tt]\/?$' \"\$cmdpath\"; then\n        
cmdpath=\"\${isodevice}/EFI/BOOT\"\n    
fi\nfi\nconfigfile \"\${cmdpath}/grub.cfg\"\n
EOF" > /home/fxs/tmp/grub-embed.cfg

for ((i=0; i<=100; i+=1)); do
        sleep 0.1
        echo "$i"
    done
} | whiptail --gauge "Creating Boot Menus...." 6 60 0

}

make_change () {
whiptail --title "Make Changes" --msgbox "Your Operating System is ready for changes.
If you want to make any changes head to: 
-> /home/fxs/chroot <-
If you want a boot splash just add one to 
-> /home/fxs/staging/boot/splash.png <-

https://fluxuan.org   -   https://Forums.Fluxuan.org" 15 65 ;

}

chroot_OS () {
if (whiptail --title "Chroot System" --yesno "Do you want to chroot into your system and install remove programs?" 8 78); then
mount --bind /proc /home/fxs/chroot/proc
mount --bind /sys /home/fxs/chroot/sys
mount --bind /dev /home/fxs/chroot/dev
export HOME=/root
export LC_ALL=C
chroot /home/fxs/chroot /bin/bash
else
return 0;
fi
}



squashing_filesystem () {
{
umount /home/fxs/chroot/proc
umount /home/fxs/chroot/sys
umount /home/fxs/chroot/dev
export HISTSIZE=0
mksquashfs /home/fxs/chroot /home/fxs/staging/boot/filesystem.squashfs -b 1048576 -comp xz -e boot &
for ((i=0; i<=100; i+=1)); do   
            sleep 20
            echo "$i"
        # If it is done then display 100%
        echo 100
        # Give it some time to display the progress to the user.
        sleep 2
        done
} | whiptail --gauge "Squashing Filesystems, it might take some time...." 6 60 0
}

write_grub () {
{
grub-mkstandalone -O i386-efi --modules="part_gpt part_msdos fat iso9660" --locales="" --themes="" --fonts="" --output="/home/fxs/staging/EFI/BOOT/BOOTIA32.EFI" "boot/grub/grub.cfg=/home/fxs/tmp/grub-embed.cfg" &&
grub-mkstandalone -O x86_64-efi --modules="part_gpt part_msdos fat iso9660" --locales="" --themes="" --fonts="" --output="/home/fxs/staging/EFI/BOOT/BOOTx64.EFI" "boot/grub/grub.cfg=/home/fxs/tmp/grub-embed.cfg"
for ((i=0; i<=100; i+=1)); do
        sleep 0.1
        echo "$i"
     echo 100
        # Give it some time to display the progress to the user.
        sleep 2
        done
} | whiptail --gauge "Creating EFI files...." 6 60 0
}

build_iso () {
{
cd /home/fxs/staging &&
dd if=/dev/zero of=efiboot.img bs=1M count=20 &&
mkfs.vfat efiboot.img &&
mmd -i efiboot.img ::/EFI ::/EFI/BOOT &&
mcopy -vi efiboot.img /home/fxs/staging/EFI/BOOT/BOOTIA32.EFI /home/fxs/staging/EFI/BOOT/BOOTx64.EFI /home/fxs/staging/boot/grub/grub.cfg ::/EFI/BOOT/ &&
xorriso -as mkisofs -iso-level 3 -o "/home/fxs/$ISONAME.iso" -full-iso9660-filenames -volid "$LABEL" --mbr-force-bootable -partition_offset 16 -joliet -joliet-long -rational-rock -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin -eltorito-boot isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table --eltorito-catalog isolinux/isolinux.cat -eltorito-alt-boot -e --interval:appended_partition_2:all:: -no-emul-boot -isohybrid-gpt-basdat -append_partition 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B /home/fxs/staging/efiboot.img "/home/fxs/staging" &&
chmod 755 /home/fxs/"$ISONAME".iso
for ((i=0; i<=100; i+=1)); do
        sleep 0.1
        echo "$i"
    done
} | whiptail --gauge "Creating your .ISO...." 6 60 0
}

finish () {
rm "$conf"
whiptail --title "Fluxuan-Snapshot" --msgbox "Thank you for using Fluxuan-Snapshot.
And for your interest in Fluxuan Linux.

For any help please join out Forums.

Your Bootable ISO file is in:
-> /home/fxs/

https://fluxuan.org   -   https://Forums.Fluxuan.org" 15 65
}

do_install () {
	welcome_msg
	ask_part
	install_dep
	create_folders
	get_system
	touch_boot
	copy_boot
	set_hostname
	print_menu
	make_change
	chroot_OS
	squashing_filesystem
	write_grub
	build_iso
	finish
	}
	
do_install
