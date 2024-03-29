#!/bin/bash
echo "Developed by Christopher M Johnston"
echo "03/11/2024"
echo "Currently in BETA"
echo "Configures OEL 6.8 to be moved to OCI VM Infrastructure"
sudo chkconfig --level 3 multiuser
sudo yum install dracut-network iscsi-initiator-utils -y
echo "Dependencies Installed"
echo 'add_dracutmodules+="iscsi"' >> /etc/dracut.conf
echo "ISCSI Modules Added to Dracut"
sudo sed -i '/^timeout=/ s/=.*/=2/' /boot/grub/grub.conf
sudo sed -i '/^splashimage/ s/^/#/' /boot/grub/grub.conf
sudo sed -i 's/\(kernel.*\)/\1 console=ttyS0,9600/' /boot/grub/grub.conf
echo "Grub Config Updated"
echo "Scrubbing Hard Coded MAC"
for file in /etc/sysconfig/network-scripts/ifcfg-*; do
    # Check if the file exists and is a regular file
    if [ -f "$file" ]; then
        # Remove or comment out the HWADDR line
        sudo sed -i '/^HWADDR=/ s/^/#/' "$file"
        echo "Hardcoded MAC removed from $file"
    fi
done
echo "Scrubbed Hard Coded MAC"

sudo tee /etc/sysconfig/network-scripts/ifcfg-eth0 >/dev/null <<EOF
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=dhcp
EOF

sudo tee /etc/sysconfig/network-scripts/ifcfg-eth1 >/dev/null <<EOF
DEVICE=eth1
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=dhcp
EOF

generate_ssh_host_key() {
    local key_type="$1"
    local key_file="/etc/ssh/ssh_host_${key_type}_key"

    if [ ! -f "$key_file" ]; then
        sudo ssh-keygen -t "$key_type" -f "$key_file" -N '' -q
    fi
}

generate_ssh_host_key "rsa"
generate_ssh_host_key "dsa"
generate_ssh_host_key "ecdsa"

#Uncomment
sudo sed -i 's/#HostKey/HostKey/' /etc/ssh/sshd_config
sudo sed -i '/^HostKey.*rsa/d' /etc/ssh/sshd_config
sudo sed -i '/^HostKey.*dsa/d' /etc/ssh/sshd_config
#Append
echo "HostKey /etc/ssh/ssh_host_ecdsa_key" | sudo tee -a /etc/ssh/sshd_config

sudo stty -F /dev/ttyS0 speed 9600
dmesg | grep console
echo "Executing Dracut"
for file in $(find /boot -name "vmlinuz-*" -and -not -name "vmlinuz-*rescue*") ; do
    sudo dracut --force /boot/initramfs-${file:14}.img ${file:14}
done
echo "Dracut Executed"
echo "Shutting Down"
sudo halt -p
