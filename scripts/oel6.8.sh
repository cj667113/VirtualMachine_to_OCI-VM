#!/bin/bash
echo "Developed by Christopher M Johnston"
echo "05/23/2020"
echo "Configures RHEL 6.8 to be moved to OCI Bare Metal Infrastructure"
sudo ln -sf /etc/systemd/system/multi-user.target /etc/systemd/system/default.target
sudo yum install dracut-network iscsi-initiator-utils xe-guest-utilities -y
sudo service xe-linux-distribution start
sudo chkconfig xe-linux-distribution on
echo "Dependencies Installed"
echo 'add_dracutmodules+="iscsi"' >> /etc/dracut.conf
echo "ISCSI Modules Added to Dracut"
sudo sed -i '/^timeout=/ s/=.*/=5/' /boot/grub/grub.conf
sudo sed -i '/^splashimage/ s/^/#/' /boot/grub/grub.conf
sudo sed -i '1i serial --unit=0 --speed=9600 --word=8 --parity=no --stop=1\nterminal --timeout=5 serial console' /boot/grub/grub.conf
sudo sed -i '/^kernel/ s/$/ console=ttyS0,9600/' /boot/grub/grub.conf
echo "Grub Config Updated"
sudo stty -F /dev/ttyS0 speed 9600
dmesg | grep console
sudo chkconfig --level 2345 serial on
sudo service serial start
echo "Executing Dracut"
for file in $(find /boot -name "vmlinuz-*" -and -not -name "vmlinuz-*rescue*") ; do
    sudo dracut --force --no-hostonly /boot/initramfs-${file:14}.img ${file:14}
done
echo "Dracut Executed"
echo "Shutting Down"
sudo halt -p
