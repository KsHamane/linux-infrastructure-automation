#!/bin/bash

#=============================Harden Every Server============================================
sudo groupadd -f admins ; sudo groupadd -f devs
sudo usermod -aG admins $(whoami)
#groups $(whoami)


sudo sed -i 's/^#\?Port .*/Port 6546/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
#cat /etc/ssh/sshd_config

sudo ufw allow 6546/tcp
sudo ufw allow 22/tcp
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
sudo ufw reload
#sudo ufw status



if sudo sshd -t; then
        sudo systemctl enable --now ssh
        sudo systemctl restart ssh
else
        echo "SSH configuration is invalid!"
        exit 1
fi
#sudo systemctl status ssh


#=====================================NFS Shared Storage Cleint Setup===============================================


sudo apt update -q ; sudo apt install -y nfs-common


if ! mountpoint -q /mnt/shared ; then
sudo mkdir -p /mnt/shared
sudo mount $(grep "nfs-server" ~/all-ips.txt | awk '{print $1}' ):/srv/shared /mnt/shared
echo "$(grep "nfs-server" ~/all-ips.txt | awk '{print $1}' ):/srv/shared /mnt/shared nfs defaults 0 0" | sudo tee -a /etc/fstab

fi

echo -e "\nShared Storage On /mnt/shared\n"



#==========================================Jump host==================================================

#CREATING SSH KEY
mkdir -p ~/.ssh
if [ ! -f ~/.ssh/id_ed25519 ]; then
        ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -C "Jump-Host-Server"
fi


#MAKING SSH COMMAND SHORTER
if [ ! -f ~/.ssh/config ]; then
touch ~/.ssh/config

cat > ~/.ssh/config <<EOF
Host nfs-server
    HostName $( grep "nfs-server" ~/all-ips.txt | awk '{print $1}' )
    User ubuntu
    Port 6546
    IdentityFile ~/.ssh/id_ed25519

Host web-server
    HostName $( grep "web-server" ~/all-ips.txt | awk '{print $1}' )
    User ubuntu
    Port 6546
    IdentityFile ~/.ssh/id_ed25519

EOF

fi


#TAKING THE USER'S KEY
if [ ! -f ~/.ssh/authorized_keys ]; then
touch ~/.ssh/authorized_keys
fi

if ! grep -q "ssh-ed25519" ~/.ssh/authorized_keys ; then
cat ~/user_key.pub >> ~/.ssh/authorized_keys
fi


#=============================================BACKUP============================================
(crontab -l 2>/dev/null; echo '0 12 * * * mkdir -p ~/backup/$(date +\%Y-\%m-\%d) && tar -czf ~/backup/$(date +\%Y-\%m-\%d)/shared.tar.gz -C /mnt/shared .') | crontab -
