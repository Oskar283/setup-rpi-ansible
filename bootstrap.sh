#!/bin/bash -uxe
# A bash script that prepares the OS
# before running the Ansible playbook

# Discard stdin. Needed when running from an one-liner which includes a newline
read -N 999999 -t 0.001

# Quit on error
set -e

# Detect OS
if grep -qs "Debian GNU/Linux" /etc/os-release; then
  os="Debian GNU/Linux"
  os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
else
  echo "This installer seems to be running on an unsupported distribution."
  echo "Supported distros are Ubuntu 20.04 and 22.04"
  exit
fi

# Check if the Ubuntu version is too old
if [[ "$os" == "Debian GNU/Linux" && "$os_version" -lt 11 ]]; then
  echo "raspi os version 11 bulleye is required for this installer"
  echo "This version of raspi is too old and unsupported."
  exit
fi


check_root() {
# Check if the user is root or not
if [[ $EUID -ne 0 ]]; then
  if [[ ! -z "$1" ]]; then
    SUDO='sudo -E -H'
  else
    SUDO='sudo -E'
  fi
else
  SUDO=''
fi
}

check_root
# Disable interactive apt functionality
export DEBIAN_FRONTEND=noninteractive

# Update apt database, update all packages and install Ansible + dependencies
$SUDO apt update -y;
$SUDO apt install -y ansible

# Open up port 80
port_open=$($SUDO firewall-cmd --list-all | grep ports);
if [[ "$port_open" != *"80/tcp" ]]; then
    $SUDO firewall-cmd --permanent --zone=public --add-port=80/tcp
    $SUDO firewall-cmd --reload
else
    echo "Port 80 already open";
fi

check_root "-H"

export DEBIAN_FRONTEND=

check_root
# Clone the Ansible playbook
[ -d "$HOME/setup-rpi-ansible" ] || git clone https://github.com/Oskar283/setup-rpi-ansible $HOME/setup-rpi-ansible

cd $HOME/setup-rpi-ansible && ansible-galaxy install -r requirements.yml



clear
echo "Welcome to setup-rpi-ansible!"
echo

echo
echo "Enter your user password"
echo "This password will be used for Authelia login, administrative access and SSH login"
read -s -p "Password: " user_password
until [[ "${#user_password}" -lt 60 ]]; do
  echo
  echo "The password is too long"
  echo "OpenSSH does not support passwords longer than 72 characters"
  read -s -p "Password: " user_password
done
echo
read -s -p "Repeat password: " user_password2
echo
until [[ "$user_password" == "$user_password2" ]]; do
  echo
  echo "The passwords don't match"
  read -s -p "Password: " user_password
  echo
  read -s -p "Repeat password: " user_password2
done

# Set secure permissions for the Vault file
touch $HOME/setup-rpi-ansible/secret.yml
chmod 600 $HOME/setup-rpi-ansible/secret.yml

echo "user_password: \"${user_password}\"" >> $HOME/setup-rpi-ansible/secret.yml

jwt_secret=$(openssl rand -hex 23)
session_secret=$(openssl rand -hex 23)
storage_encryption_key=$(openssl rand -hex 23)

echo "jwt_secret: ${jwt_secret}" >> $HOME/setup-rpi-ansible/secret.yml
echo "session_secret: ${session_secret}" >> $HOME/setup-rpi-ansible/secret.yml
echo "storage_encryption_key: ${storage_encryption_key}" >> $HOME/setup-rpi-ansible/secret.yml

echo
echo "Encrypting the variables"
ansible-vault encrypt $HOME/setup-rpi-ansible/secret.yml

echo
echo "Success!"
read -p "Would you like to run the playbook now? [y/N]: " launch_playbook
until [[ "$launch_playbook" =~ ^[yYnN]*$ ]]; do
				echo "$launch_playbook: invalid selection."
				read -p "[y/N]: " launch_playbook
done

if [[ "$launch_playbook" =~ ^[yY]$ ]]; then
    cd $HOME/setup-rpi-ansible && ansible-playbook run.yml
else
  echo "You can run the playbook by executing the following command"
  echo "cd ${HOME}/setup-rpi-ansible && ansible-playbook run.yml"
  exit
fi
