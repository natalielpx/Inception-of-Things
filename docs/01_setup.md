# Part 0 - Provision Virtual Machine

## Create and Launch the Machine

The subject requires that the entire project be done in a virtual machine, so we can set that up first. Note that for this project, we will need to run multiple virtual machines within this virtual machine. If each running virtual machine requires 512MB and 1 CPU, make sure enough base memory and processors are being allocated to the host virtual machine.

Don’t do this project with virtualbox. Create your virtual machine via qemu and thank me later.

https://drewdevault.com/blog/Getting-started-with-qemu/

Launch Qemu Virtual Manager

```jsx
virt-manager --connect qemu:///session
```

```jsx
mkdir /home/$USER/sgoinfre/vms/
qemu-img create -f qcow2 /home/$USER/sgoinfre/vms/debian.qcow2 40G

```

```bash
qemu-system-x86_64 \
		-enable-kvm \
		-m 8192 \
		-smp 4 \
		-nic user,model=virtio \
		-drive file=/home/$USER/sgoinfre/vms/debian.qcow2,media=disk,if=virtio \
		-cdrom /home/$USER/Downloads/debian-13.6.0-amd64-netinst.iso \
		-display sdl
```

When booting after installation:

- drop `-cdrom` flag to prevent boot loops
- add `-cpu host` for kvm
the virtual machines will not be able to be created without this

```jsx
qemu-system-x86_64 \
    -enable-kvm \
    -m 8192 \
    -smp 4 \
    -cpu host \
    -nic user,model=virtio \
    -drive file=/home/$USER/sgoinfre/vms/debian.qcow2,media=disk,if=virtio \
    -display sdl
```

Here’s what I used:

- Folder: sgoinfre
- Distribution:
[https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.6.0-amd64-netinst.iso](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.6.0-amd64-netinst.iso)
- Base Memory: 8192MB
- Processors: 4 CPU
- Virtual Size: 40GB

If you will be doing the bonus, opt in for ssh.S

## Setup User Permissions

Add current user into sudo group

```
su -
usermod -aG sudo <user>
exit
newgrp sudo
groups
```

## Install Required Software

### Vagrant

https://developer.hashicorp.com/vagrant/downloads

1. Download and register key
    
    ```
    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    # You might be prompted to input password
    ```
    
    If gpg is missing, install following the below instructions
    
    https://www.cyberciti.biz/faq/installing-gnupg2-on-debian-linux-to-fix-bash-gpg-command-not-found-error/
    
2. Update sources list
    
    ```
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    ```
    
3. Install vagrant
    
    ```
    sudo apt-get update
    sudo apt-get install vagrant
    ```
    

### QEMU - Libvirt

https://www.qemu.org/download/#linux

https://www.server-world.info/en/note?os=Debian_13&p=kvm&f=1

1. Install QEMU
    
    ```jsx
    sudo apt-get -y install qemu-system
    ```
    
2. Install Libvirt
    
    ```jsx
    sudo apt-get -y install qemu-kvm libvirt-daemon-system libvirt-daemon virtinst bridge-utils libosinfo-bin libguestfs-tools 
    ```
    
3. Configure /etc/network/interfaces
    
    First look up info:
    
    ```bash
    # This file describes the network interfaces available on your system
    # and how to activate them. For more information, see interfaces(5).
    
    source /etc/network/interfaces.d/*
    
    # The loopback network interface
    auto lo
    iface lo inet loopback
    
    # The primary network interface
    allow-hotplug ens3
    # change existing setting like follows
    iface ens3 inet manual
    
    # add bridge interface setting
    auto br0
    iface br0 inet static
    address 10.0.2.15/24
    gateway 10.0.2.2
    dns-nameservers 10.0.2.3
    bridge_ports ens3
    bridge_stp off
    hwaddress ether 52:54:00:12:34:56
    
    ```
    
4. reboot
    
    <aside>
    
    sudo reboot
    
    </aside>
    
5. Install plugin
    
    ```jsx
    sudo apt-get update
    sudo apt-get -y install build-essential ruby-dev pkg-config libvirt-dev
    vagrant plugin install vagrant-libvirt
    ```
    

### Git

```
sudo apt-get update
sudo apt-get -y install git
```

## Access GitHub Project Files

Create and obtain ssh key in the VM

```
ssh-keygen -t ed25519 -C "iot"
cat /home/$USER/.ssh/id_ed25519.pub
```

Add public key to github

`Settings >> SSH and GPG keys >> New SSH Key`

Check connection

```
ssh -T git@github.com
```

## Provisioning with Ansible

### Authorisation

connection

sudo groups
