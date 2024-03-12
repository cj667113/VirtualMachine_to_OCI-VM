#!/bin/bash
echo "This is currently in BETA"
echo "Developed by Christopher M Johnston"
echo "03/11/2024"
echo "Configures RHEL 6.8 to be moved to OCI Bare Metal Infrastructure"
sudo ln -sf /etc/systemd/system/multi-user.target /etc/systemd/system/default.target
sudo yum install dracut-network iscsi-initiator-utils -y
echo "Dependencies Installed"
echo 'add_dracutmodules+="iscsi"' >> /etc/dracut.conf
echo "ISCSI Modules Added to Dracut"
cat /boot/grub/grub.conf | grep -v 'console=ttyS0' > /tmp/grub
echo 'serial --unit=0 --speed=9600 --word=8 --parity=no --stop=1' >> /tmp/grub
echo 'terminal --timeout=5 serial console' >> /tmp/grub
sed -i 's/^timeout=.*/timeout=5/' /tmp/grub
cp /tmp/grub /boot/grub/grub.conf
echo "Grub Config Made"
sudo stty -F /dev/ttyS0 speed 9600
dmesg | grep console
sudo chkconfig --level 2345 serial on
sudo service serial start
echo "Executing Dracut"
for file in $(find /boot -name "vmlinuz-*" -and -not -name "vmlinuz-*rescue*") ; do
    dracut --force --no-hostonly /boot/initramfs-${file:14}.img ${file:14}
done
echo "Dracut Executed"
echo "Shutting Down"
sudo halt -p
