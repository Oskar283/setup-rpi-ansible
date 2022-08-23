# setup-rpi-ansible

A simple script/Ansible playbook that sets up an Rpi4 for server use

## Usage

```
wget https://raw.githubusercontent.com/Oskar283/setup-rpi-ansible/master/bootstrap.sh -O bootstrap.sh && bash bootstrap.sh
```

## Features

## Requirements
* Rpi running Raspberry Pi OS Lite, 64 bit

## FAQ
### Q: I've run the playbook succesfully, but now I want to change the domain name/username/password. How can I do that?

Edit the variable files, install dependencies for the new user and re-run the playbook:

```
cd $HOME/ansible-easy-vpn
ansible-galaxy install -r requirements.yml
nano custom.yml
ansible-vault edit secret.yml
ansible-playbook run.yml
```


### Q: I'd like to completely automate the process of setting up the VPN on my machines. How can I do that?
1. Fork this repository
2. Fill out the `custom.yml` and `secret.yml` files, either by running the `bootstrap.sh` script, or editing the files manually
3. Remove `secret.yml` from .gitignore
4. Commit and push the changes
