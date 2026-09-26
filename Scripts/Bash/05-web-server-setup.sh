#!/bin/bash
#03-web-server-setup.sh
#=============================Harden Every Server============================================
mkdir -p ~/.ssh


sudo groupadd -f admins ; sudo groupadd -f devs
sudo usermod -aG admins $(whoami)
#groups $(whoami)


sudo sed -i 's/^#\?Port .*/Port 6546/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config


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


#TAKING THE USER'S KEY
if [ ! -f ~/.ssh/authorized_keys ]; then
touch ~/.ssh/authorized_keys
fi

if ! grep -q "ssh-ed25519" ~/.ssh/authorized_keys ; then
cat ~/user_key.pub >> ~/.ssh/authorized_keys
fi



#=====================================NFS Shared Storage Cleint Setup===============================================


sudo apt update -q ; sudo apt install -y nfs-common

if ! mountpoint -q /mnt/shared ; then
sudo mkdir -p /mnt/shared
sudo mount $(grep "nfs-server" ~/all-ips.txt | awk '{print $1}' ):/srv/shared /mnt/shared
echo "$(grep "nfs-server" ~/all-ips.txt | awk '{print $1}' ):/srv/shared /mnt/shared nfs defaults 0 0" | sudo tee -a /etc/fstab
fi


echo -e "\nShared Storage On /mnt/shared\n"



#=====================================Deploying The web page from /mnt/shared/apps==============================================================


if [ ! -d /etc/nginx ]; then
sudo apt install nginx -y
fi

sudo systemctl enable --now nginx

sudo mv /var/www/html/index.nginx-debian.html /var/www/html/index.html

#cat /mnt/shared/apps/test_site.html > /var/www/html/index.html
#sudo systemctl restart nginx
#echo "$(sudo cat /mnt/shared/apps/test_site.html)" | sudo tee /var/www/html/index.html

sudo cp /mnt/shared/apps/test_site.html /var/www/html/index.html




#=============================MAKING HTTPS SERVICE WITH SELF ASSIGNED CERTIFICATE==================================

if [ ! -f /etc/nginx/ssl/nginx.crt ] || [ ! -f /etc/nginx/ssl/nginx.key ] ; then
sudo mkdir -p /etc/nginx/ssl

sudo openssl req -x509 -nodes -days 365 \
-newkey rsa:2048 \
-keyout /etc/nginx/ssl/nginx.key \
-out /etc/nginx/ssl/nginx.crt \
-subj "/CN=web-server"

sudo tee /etc/nginx/sites-available/default > /dev/null <<'EOF'
server {
    listen 80;
    server_name _;

    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name _;

    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
fi


sudo nginx -t
sudo systemctl restart nginx


echo -e "\n\nLINK: https://$(hostname -I | awk '{print $1}') \n"
