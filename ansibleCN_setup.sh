#! /bin/bash
# This is the script to run to setup an Ansible control node.

echo "##########################################################"
echo "# Update and Secure Linode Instance                      #"
echo "##########################################################"

apt update
apt upgrade -y

hostnamectl set-hostname CtlNode

# Secure ssh a bit with no root login and no x11 forwarding
# Need to remove host key checking for Ansible to run properly
sed -in 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -in 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
sed -in 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/' /etc/ssh/ssh_config

echo "##########################################################"
echo "# Installing Software                                    #"
echo "##########################################################"
# Install Software
# ==================================================================================================== 
apt install sshpass -y
apt install ansible -y
apt install fail2ban -y
apt install python3-pip -y
pip3 install passlib

# Configure Software
# ==================================================================================================== 
# fail2ban
# ========
systemctl enable fail2ban.service
systemctl start fail2ban.service
# ufw
# ========
ufw allow openssh
yes | ufw enable
ufw status

echo "##########################################################"
echo "# Creating limited user                                  #"
echo "##########################################################"
echo ""
echo "Please enter preferred username: "
read USERNAME
# Create limited user and give sudo privileges.
useradd -m -G sudo -s /bin/bash $USERNAME
passwd $USERNAME

mv ansibleMN_setup.sh myplaybook.yml /home/$USERNAME

# Create passwordless sudo for user $USERNAME
#+ and add file in /etc/sudoers.d/
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10-user-$USERNAME
chmod 440 /etc/sudoers.d/10-user-$USERNAME
visudo -c

# Create an ssh key for the user.
mkdir /home/$USERNAME/.ssh
ssh-keygen -t rsa -b 2048 -f /home/$USERNAME/.ssh/id_rsa -q -N ''

# Set file permissions for the user.
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
chown $USERNAME:$USERNAME /home/$USERNAME/myplaybook.yml

echo "##########################################################"
echo "# Dunzo. Poke around if you like.  I recommend a reboot. #"
echo "##########################################################"
