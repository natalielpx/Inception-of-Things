---
title: 42 Inception of Things - An Introductory Project to Kubernetes
---

# 42 Inception of Things - An Introductory Project to Kubernetes

⬇️ If you found this helpful, don’t hesitate to ⭐️ my project! ⬇️

[https://github.com/natalielpx/Inception-of-Things](https://github.com/natalielpx/Inception-of-Things)

> ⚠️ Disclaimer: I am still polishing up this tutorial, but for now, it should cover most, if not the entire project

# Part 0 - Provision Virtual Machine

---

## Create Virtual Machine

The subject requires that the entire project be done in a virtual machine, so we can set that up first. Note that for this project, we will need to run multiple virtual machines within this virtual machine. If each running virtual machine requires 1024MB and 1 CPU, make sure enough base memory and processors are being allocated to the host virtual machine. For the bonus, gitlab requires at least 12GB and 3 CPUs with a minimal configuration. Though I would highly recommend allocating more, we can only work with what is provided at 42. More on that later.

Don’t do this project with virtualbox, it is known throughout campus that it doesn’t work well with this project. Create your virtual machine via qemu and thank me later.

<https://drewdevault.com/blog/Getting-started-with-qemu/>

1. Launch Qemu Virtual Manager

    ```bash
    virt-manager --connect qemu:///session
    ```

2. Format storage for virtual machine:<br>
Note that running this command after booting your virtual machine will erase everything.

    ```bash
    mkdir -p /home/$USER/sgoinfre/vms/
    qemu-img create -f qcow2 /home/$USER/sgoinfre/vms/iot.qcow2 80G
    ```

    Now doesn’t 80G sound like a lot? Yes and no. Yes, that’s a lot to ask from 42. No, that’s not unreasonable for this project (including the bonus). After finishing the project, the amount of storage used can be checked as follows:

    ```bash
    # Check disk usage
    sudo du -h --max-depth=1 /var/lib | sort -hr
    sudo du -h --max-depth=1 ~/VirtualBox\ VMs/ | sort -hr
    ```

    p1:

    ~4G: Server machine

    ~4G: Agent machine

    p2:

    ~3G: Server machine

    p3:

    ~13G: Docker

    ~2G: Containerd

3. Boot in terminal mode

    To save up even more on resources, I set up my virtual machine without graphics.

    <details markdown="1">
    <summary>If you prefer with graphics, clicky here:</summary>


    ```bash
    # Boot virtual machine
    qemu-system-x86_64 \
      -enable-kvm \
      -m 12288 \
      -smp 10 \
      -nic user,model=virtio,hostfwd=tcp::2222-:22 \
      -drive file=/home/$USER/sgoinfre/vms/iot.qcow2,media=disk,if=virtio \
      -cdrom /home/$USER/Downloads/debian-13.6.0-amd64-netinst.iso \
      -display sdl
    ```

    </details>


    If working on a 42 station:

    ```bash
    osirrox \
    	-indev /home/$USER/Downloads/debian-13.6.0-amd64-netinst.iso \
    	-extract install.amd/vmlinuz /tmp/vmlinuz \
    	-extract install.amd/initrd.gz /tmp/initrd.gz
    ```

    - `osirrox` ISO file extraction
        - `-indev` Source ISO to read from
        - `-extract`
            - `install.amd/vmlinuz` Kernel binary in ISO
            - `install.amd/initrd.gz` Initial RAM disk in ISO

    ```bash
    # Boot virtual machine
    qemu-system-x86_64 \
      -enable-kvm \
      -m 12288 \
      -smp 10 \
      -nic user,model=virtio,hostfwd=tcp::2222-:22 \
      -drive file=/home/$USER/sgoinfre/vms/iot.qcow2,media=disk,if=virtio \
      -cdrom /home/$USER/Downloads/debian-13.6.0-amd64-netinst.iso \
      -kernel /tmp/vmlinuz \
      -initrd /tmp/initrd.gz \
      -append "console=ttyS0,115200n8 DEBIAN_FRONTEND=text" \
      -nographic
    ```

    - `-enable-kvm` Use Linux KVM for hardware-accelerated virtualisation

        KVM is needed for VirtualBox in regards to Vt-x

    - `-m 12288` Allocate 12 GB RAM (in MiB)

        Depending on the available resources on your host machine, try to aim for 10240~12288MB.

        ```bash
        # Check amount of resources on host machine
        free -h
        #               total        used        free      shared  buff/cache   available
        #Mem:            15Gi       4.1Gi       7.6Gi       516Mi       4.2Gi        11Gi
        #Swap:            9Gi        81Mi       9.9Gi
        ```

        In the above case, the host machine has a total of 15Gi, and we are allocating 12Gi to the virtual machine.

    - `-smp 10` Give virtual machine 10 virtual CPU cores

        Again, depending on the available resources, try to aim for 8~10.

        ```bash
        # Check amount of vCPUs on host machine
        nproc
        #20
        ```

    - `-nic` Network Interface Card

        Enables our machine to connect to a network

        - `user` User-mode NAT networking

            No root needed, VM gets internet via host NAT

        - `model=virtio`

            use virtio (a standard interface for paravirtualized devices) as the virtual machine's virtual network card

        - `hostfwd=tcp::2222-:22` Host port forwarding

            Forwards host port `2222` to guest port `22`

            (Allows SSH access via `ssh -p 2222 localhost`)

    - `-drive` Primary disk image
        - `file=/home/$USER/sgoinfre/vms/iot.qcow2`
        - `media=disk`
        - `if=virtio`
    - `-cdrom` Mount ISO as a virtual CD-ROM
    - `-kernel` Boot kernel directly, bypassing ISO's bootloader
    - `-initrd` Load target initramfs alongside the kernel
    - `-append` Kernel command-line arguments
        - `console=ttyS0,115200n8`

            Route kernel/installer output to serial port (ttyS0) at 115200 baud, 8-bit, no parity

        - `DEBIAN_FRONTEND=text`

            Use text-mode UI instead of graphical

    - `-nographic`

        Disable all graphical output

        QEMU's serial port, parallel port, and monitor is redirected to terminal stdout/stdin.

4. Setup

    Setting up a virtual machine without graphics was a little awkward, but manageable. The only tricky part was:

    ```text
    Choose software to install:
    1: Debian desktop environment [*],
    2: ... GNOME [*],
    3: ... Xfce,
    4: ... GNOME Flashback,
    5: ... KDE Plasma,
    6: ... Cinnamon,
    7: ... MATE,
    8: ... LXDE,
    9: ... LXQt,
    10: web server,
    11: SSH server,
    12: standard system utilities [*],
    13: Choose a Debian Blend for installation,
    Prompt: '?' for help, default=1 2 12>
    ```

5. *QUICKLY* stop virtual machine from rebooting

    `Ctrl+A`, then press `x`

6. If failed to stop virtual machine from rebooting

    > 🚧 in progress…


---

## Launch Virtual Machine

Rerun the virtual machine with :

```bash
qemu-system-x86_64 \
  -enable-kvm \
  -cpu host \
  -m 12288 \
  -smp 10 \
  -nic user,model=virtio,hostfwd=tcp::2222-:22,hostfwd=tcp::8000-:8443 \
  -drive file=/home/$USER/sgoinfre/vms/iot.qcow2,media=disk,if=virtio \
  -nographic
```

- drop `-cdrom` flag to prevent boot loops
- add `-cpu host` for kvm<br>
the virtual machines will not be able to be created without this
- add `hostfwd=tcp::8000-:8443` to connect port 8000 of the host machine to port 8443 of the virtual machine<br>
this will allow us to access our applications from a browser in the host machine, since the virtual machine is non-graphical

---

## Setup User Permissions

Add current user into sudo group

```bash
su -
apt update && apt install -y sudo
usermod -aG sudo <user>
exit
newgrp sudo
groups
```

---

## Install Required Software

1. Common packages

    ```bash
    su -
    apt update
    apt install -y \
    	curl \
      git \
      kubectl \
      sudo \
      wget
    ```

2. Vagrant

    <https://developer.hashicorp.com/vagrant/downloads>

3. VirtualBox

    <https://wiki.debian.org/VirtualBox?pow_referer=https%3A%2F%2Fsearch.brave.com%2F>

    Remember to add user to group

    ```bash
    sudo usermod -aG vboxusers $USER
    newgrp vboxusers
    groups
    ```

4. Docker

    Remember to add user to group

    ```bash
    sudo usermod -aG docker $USER
    newgrp docker
    groups
    ```

5. K3D

    <https://k3d.io/stable/#releases>

6. Helm (Bonus)

    [https://helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/)


---

## Access GitHub Project Files

1. Create and obtain ssh key in the VM

    ```bash
    ssh-keygen -t ed25519 -C "iot"
    cat /home/$USER/.ssh/id_ed25519.pub
    ```

2. Add public key to github

    `Settings >> SSH and GPG keys >> New SSH Key`

3. Check connection

    ```bash
    ssh -T git@github.com
    ```

4. Clone repository

    ```text
    You really shouldn't need sample code for this
    ```


---

# Part 1 - Vagrant x K3s

---

## Vagrant

Vagrant is a command-line tool that works with virtualization software (like **VirtualBox**, **VMware**, or **Libvirt**) to:

- Create lightweight, disposable development environments
- Share consistent setups across the team
- Automate provisioning (installing packages, configuring services, etc.)

### Vagrantfiles

Vagrantfiles are just Ruby scripts that Vagrant reads. It is used to describe, configure, and provision our desired machine(s).

You can create a Vagrantfile via `vagrant init`, or simply create a file named `Vagrantfile`.

```text
.
└── p1
    └── Vagrantfile
```

```ruby
Vagrant.configure("2") do |config|
	...
end
```

This is the top-level configuration block. Since Vagrantfiles are just Ruby scripts that Vagrant reads, this is actually pure Ruby syntax.

- `Vagrant` is a Ruby module.
- `.configure("2")` is a method call on the `Vagrant` module, with `"2"` as an argument. `"2"` represents the configuration for Vagrant 1.1+ leading up to Vagrant 2.0.x. This is the current latest version, and is the version that we will be using.
- `do ... end` in Ruby defines a block, and is essentially an anonymous chunk of code that can be passed to the `configure` method.
- `|config|` is the block’s parameter. Its value is the configuration object provided by `Vagrant.configure`. Inside the block, we will use `config` to define VM settings, assign resources, and configure provisioning steps.

### Global Configurations

These are configurations that will be applied across all the machines described in this Vagrantfile.

**Vagrant Boxes**

The first and foremost will be the vagrant `box` we will be using as a base for our machines.

We are choosing to use bento boxes, because it is one of the only two officially recommended sources. The other recommended box is by HashiCorp themselves, but is quite outdated.

```ruby
Vagrant.configure("2") do |config|

	# Vagrant box
	config.vm.box = "bento/debian-13"
	config.vm.box_version = "202510.26.0"

end
```

- In `.box`, the name before `/` is the creator, and the name after it is the distribution. It goes without saying that it is advised to use boxes from reputable owners.
- `.box_version` is useful to ensure that even if a newer version becomes available, the precise version that is requested will be use. This is helpful to avoid any compatibility issues that may arise from an unexpected update.

**Providers**

Vagrant itself doesn’t virtualise anything directly. It’s more like a universal controller that talks to other virtualisation tools. A provider in Vagrant is the backend system that actually *creates, runs, and manages* your virtual machines (VMs). Providers have to be installed on the host machine. In our case, we have installed virtualbox, and that is what we will be using.

```ruby
Vagrant.configure("2") do |config|

	# Vagrant box
	config.vm.box = "bento/debian-13"
	config.vm.box_version = "202510.26.0"
	# Provider
	config.vm.provider "virtualbox" do |vb|
		vb.cpus = 1
		vb.memory = 1024
	end

end
```

- `.provider "”` takes in its argument as the provider. Here, VirtualBox is our choice of provider.
- `.cpus` is the number of processors allocated to each machine. Here we are only allocating 1 per machine. Allocating more will quickly deplete the amount of CPUs we have allocated to our host machine.
- `.memory` is the base memory allocated to each machine. Here we are using 1024MB so as to not overload our host machine

### Machines

```ruby
Vagrant.configure("2") do |config|

	# Global configurations (applied across all machines)
	config.vm.box = "bento/debian-13"
	config.vm.box_version = "202510.26.0"
	config.vm.provider "virtualbox" do |vb|
		vb.cpus = 1
		vb.memory = 1024
	end


	# Machine 1: Server
	config.vm.define "nlamS" do |server|
		server.vm.hostname = "nlamS"
		server.vm.network "private_network", ip: "192.168.56.110"
	end

	# Machine 2: Server Worker
	config.vm.define "nlamSW" do |agent|
		agent.vm.hostname = "nlamSW"
		agent.vm.network "private_network", ip: "192.168.56.111"
	end

end
```

- `.define ""` defines a machine by the name of the argument it is passed to. This name will be used by Vagrant when we are using vagrant commands.
- `.hostname` declares the hostname of the OS of machine. Essentially, this is the name the machine recognises itself with.
- `.network "private_network"`  exposes the machine to the local network. This network is inaccessible to the internet. The machines can be accessed via their designated IP.

### Vagrant Commands

Here is a non exhaustive collection of useful vagrant commands:

- `vagrant init` Creates an initial Vagrantfile
- `vagrant up` Creates and configures machines according to Vagrantfile
- `vagrant up --no-parallel` Creates and configures machines one after another
- `vagrant provision` Provision machines without recreating them
- `vagrant halt` Stops (shuts down) Vagrant machines
- `vagrant destroy -f` Destroys all resources that were created without asking for confirmation
- `vagrant ssh [name|id]` SSHs into a running Vagrant machine
- `vagrant status` Shows state of Vagrant machines

---

## K3s Server & Server Worker (Agent) Installation

Now that we have two machines, one of these machines will be provisioned as a K3s server, and the other will its server worker (agent). We will be installing K3s on the machines with scripts.

```text
.
└── p1
    ├── scripts
    │   ├── agent.sh
    │   └── server.sh
    └── Vagrantfile
```

```ruby
Vagrant.configure("2") do |config|

	# Global configurations (applied across all machines)
	config.vm.box = "bento/debian-13"
	config.vm.box_version = "202510.26.0"
	config.vm.provider "virtualbox" do |vb|
		vb.cpus = 1
		vb.memory = 1024
	end

	# Machine 1: Server
	config.vm.define "nlamS" do |server|
		server.vm.hostname = "nlamS"
		server.vm.network "private_network", ip: "192.168.56.110"
		server.vm.provision "shell", path: "./scripts/server.sh"
	end

	# Machine 2: Server Worker
	config.vm.define "nlamSW" do |agent|
		agent.vm.hostname = "nlamSW"
		agent.vm.network "private_network", ip: "192.168.56.111"
		agent.vm.provision "file",
			source: ".vagrant/machines/nlamS/virtualbox/private_key",
			destination: "/home/vagrant/key.txt"
		agent.vm.provision "shell", path: "./scripts/agent.sh"
	end

end
```

`.provision` provides variable options to provisioning our machine

`”shell”` allows us to provision our machines with a shell script. There is an option of including our scripts inline with `inline:`, but here we are choosing to use `path:` as I find it is cleaner.

`“file”` allows us to copy files or folders from a specific `source:` path into the `destination:` path on our machines. Here we are copying the private key of our server machine into our agent machine. We will be using this key to obtain the token needed to register the agent with the server.

**K3s Server Installation Script**

```bash
#!/usr/bin/env bash

# K3s Server

# Install dependencies
apt-get update && apt-get install -y curl

# Install K3s (as server)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --flannel-iface=eth1" sh -
```

**K3s Agent Installation Script**

```bash
#!/usr/bin/env bash

# K3s Agent

# Install dependencies
apt-get update && apt-get install -y curl openssh-client

# Export values (essential to install K3s as agent)
export K3S_URL=https://192.168.56.110:6443
export K3S_TOKEN=$(ssh -o StrictHostKeyChecking=no \
			-o ConnectTimeout=5 \
			-i "/home/vagrant/key.txt" \
			"vagrant@192.168.56.110" \
			"sudo cat /var/lib/rancher/k3s/server/node-token")

# Install K3s (as agent)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.111" sh -
```

---

## Launch

1. Launch the machines with `vagrant up` and wait for the machines to be ready.
2. Check the status of the machines with `vagrant status` to ensure both machines are up and running.
3. Check that the server machine is running correctly.
    1. Access server with `vagrant ssh [server]` where `[server]` is the name of the server machine.
    2. Run `sudo kubectl get node -o wide` and compare results with that in the subject.
4. Check that the agent machine is running correctly.
    1. Access agent with `vagrant ssh [agent]` where `[agent]` is the name of the agent machine.
    2. Run `ip -s addr show eth1` to check that the ip is correct and compare results with that in the subject.
    3. If something is wrong, run `sudo journalctl -u k3s-agent -f` to view agent logs in real-time.
5. Other checks:
    1. `free -h` shows us the memory of the machine
    2. `nproc` shows us the number of processors
    3. `sudo kubectl version` will show us that we are indeed using `k3s`

---

## Troubleshooting

If something goes wrong with vagrant and you are unable to create nor destroy the vms:

1. The current Vagrantfile no longer matches the existing statuses of the vms. Revert the Vagrantfile, run `vagrant destroy -f`, and then re-modify the Vagrantfile.
2. Try removing vagrant’s metadata `rm -rf .vagrant`
3. For even more complicated underlying issues, `VBoxManage` manages ALL vms. List out all the current vms and remove all that are not needed.

    ```bash
    # List all current vms
    VBoxManage list vms

    # Unregister and delete associated files
    VBoxManage unregistervm "<VM_NAME>" --delete
    # Unregister vm via its name
    VBoxManage unregistervm "<VM_NAME>"
    # Unregister vm via its UID (useful when vm does not have a name)
    VBoxManage unregistervm "<UID>"
    ```


---

# Part 2 - K3s

---

In Part 2, we will be setting up 3 web applications that will run in our K3s instance. We will create the required resources (deployments, services, ingress) via YAML files. It is also possible to deploy pods through CLI commands, but YAML files provide an abundance of advantages:

- **Version control** - Track changes in Git
- **Reproducible** - Easy to recreate exact configuration
- **Documentation** - Self-documenting infrastructure
- **Complex configurations** - Handle multi-field specifications easily
- **Best practice** - Industry standard for production
- **Peer review** - Team can review before applying
- **Reusable** - Template and modify for different environments

---

## Vagrantfile

As we have done in Part 1, first, we need a machine on which we will run K3s. This time we only need one machine — a server machine.

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant configuration
Vagrant.configure("2") do |config|

	# Global configurations (applied across all machines)
	config.vm.box = "bento/debian-13"
	config.vm.box_version = "202510.26.0"
	config.vm.provider "virtualbox" do |vb|
		vb.cpus = 1
		vb.memory = 1024
	end

	# Server Machine
	config.vm.define "nlamS" do |server|
		server.vm.hostname = "nlamS"
		server.vm.network "private_network", ip: "192.168.56.110"
		server.vm.provision "shell", path: "./scripts/server.sh"
	end

end
```

This Vagrantfile is nearly identical to that of Part 1, except we have removed the agent machine. And since we don’t have an agent machine, we no longer need to copy the server’s private key to the agent to fetch the token required to connect the agent machine to the server machine.

---

## K3s Server Installation

```text
.
└── p2
    ├── confs
    │   ├── app1-deployment.yaml
    │   ├── app1-service.yaml
    │   ├── app2-deployment.yaml
    │   ├── app2-service.yaml
    │   ├── app3-deployment.yaml
    │   ├── app3-service.yaml
    │   └── ingress.yaml
    ├── scripts
    │   ├── launch.sh
    │   └── server.sh
    └── Vagrantfile
```

**Installation Script**

Similar to Part 1, we are installing K3s as a server. However, since there is no agent machine, we will not be doing anything with the generated token.

```bash
#!/usr/bin/env bash

# K3s Server Installation

# Install dependencies
apt-get update && apt-get install -y curl

# Install K3s (as server) with forced IP configuration
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --flannel-iface=eth1" sh -
```

---

## Essential CLI Commands

Just because our the YAML files will be doing all the heavy work, that doesn’t mean we can get by without any CLI commands. Here are select sets of CLI commands that you will-or at least should-be running at least once or twice for this project.

Note that these commands need to be run within the server machine where K3s is installed.

Information on how Kubernetes works:

```bash
# Lists resources supported by `kubectl explain`
kubectl api-resources

kubectl explain nodes
kubectl explain pods
kubectl explain deployment
kubectl explain service
kubectl explain ingress
kubectl explain endpoints
```

Creating resources:

```bash
# Creates a specific resource
kubectl apply -f <YAML_file_path>
# Creates resources from all the existing YAML files in given directory
kubectl apply -f <directory_path>
```

Observability in cluster(s):

```bash
kubectl get deployments
kubectl get pods
kubectl get events
kubectl config view
kubectl get services
```

---

## Manifests

We will always need at least the `apiVersion`, `kind`, and `metadata` sections when creating a resource with a manifest.

```yaml
# Standard Kubernetes Resource Structure

# API Version -REQUIRED-
apiVersion: <string>

# Type of resource -REQUIRED-
kind: <string>

# Metadata section -REQUIRED-
metadata:
  name: <string>          # -REQUIRED-
  namespace: <string>     # defaults to "default"
  labels: <map>
  annotations: <map>

# Spec section (unique to each resource type)
spec:
  <resource-specific fields>

# Status section (managed by Kubernetes, read-only)
status:
  <runtime state>
```

### Deployment

```bash
touch confs/app{1,2,3}-deployment.yaml
```

We can figure out how to fill out the 3 essentials with `kubectl explain deployment`. The headers provide information for `apiVersion` and `kind`. And then we select a preferred name for the resource.

```yaml
# p2/confs/app1-deployment.yaml

# From API reference header
# ```
# $ kubectl explain deployment
# GROUP:      apps
# KIND:       Deployment
# VERSION:    v1
# ```

apiVersion: apps/v1       # <GROUP>/<VERSION>
kind: Deployment          # <KIND>
metadata:
  name: app1-deployment   # Resource Name
```

This is definitely not enough to deploy our application. Nevertheless, let’s try creating this resource.

```bash
$ kubectl apply -f /vagrant/confs/app1-deployment.yaml
The Deployment "app1-deployment" is invalid:
* spec.selector: Required value
* spec.template.metadata.labels: Invalid value: null: `selector` does not match template `labels`
* spec.template.spec.containers: Required value
```

The error announces 3 missing values, all in `spec`, so let’s dive into that.

`kubectl explain deployment.spec`

There are many different fields that are included in deployment specifications. Note that `selector` and `template` are marked as required, which is consistent with our error messages.

**spec.selector**

`kubectl explain deployment.spec.selector`

There are two ways to select pods. For simpler selection requirements, `matchLabels` will suffice, and it is what we shall be using for this project.

```yaml
# The following configurations are identical

matchLabels:
  app: my-app # <key>: <value>

matchExpressions:
- key: app
  operator: In # Operator: "In", "NotIn", "Exists", "DoesNotExist"
  values:
  - my-app

# An empty selector

selector: {}

# or

selector:
  matchLabels: {}
```

It is also stated that “An empty label selector matches all objects.” and “A null label selector matches no objects.” I, however, find this quite confusing, since `selector` is a required field that requires a value, when are they null?

```yaml
# p2/confs/app1-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1-deployment
spec:
  selector:
    matchLabels:
      app: app1
```

**spec.template.metadata.labels**

Moving on, we will match the template labels to the selector, as the error requested.

```yaml
# p2/confs/app1-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1-deployment
spec:
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
```

**spec.template.spec.containers**

`kubectl explain deployment.spec.template.spec.containers`

Note that `containers` are of type `<[]Container>`. Meaning that it’s a list of `Container`s. Items in lists must be prefixed with `-`, otherwise, `kubectl` will refuse to create the resource due to incompatibility of structure type.

In the long list of fields, only `name` is listed as required. Let’s see if that suffices.

```yaml
# p2/confs/app1-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1-deployment
spec:
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
        - name: app1
```

```bash
$ kubectl apply -f /vagrant/confs/app1-deployment.yaml
The Deployment "app1-deployment" is invalid: spec.template.spec.containers[0].image: Required value
```

Apparently not. But of course we would need an image.

```yaml
# p2/confs/app1-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1-deployment
spec:
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
        - name: app1
          image: traefik/whoami
```

Traefik is a reverse proxy, just like NGINX, except it was built specifically with cloud-infrastructure and automisation in mind. This makes it a natural choice for many kubernetes orchestrated projects.

[`traefik/whoami`](https://github.com/traefik/whoami) is a super tiny docker image that returns whoami information, much smaller than `hello-kubernetes`, which is the example provided in the subject. Use whichever you please.

```bash
$ kubectl apply -f /vagrant/confs/app1-deployment.yaml
deployment.apps/app1-deployment created
```

And there we go! Our deployment resource is created.

To check up on our deployments, run the CLI command `kubectl get deployment`. For a wider view, run `kubectl get all`.

```bash
$ kubectl get deployments
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
app1-deployment   1/1     1            1           9m23s

$ kubectl get all
NAME                                   READY   STATUS    RESTARTS   AGE
pod/app1-deployment-58b98b5665-xmt5j   1/1     Running   0          3m18s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.43.0.1    <none>        443/TCP   40h

NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/app1-deployment   1/1     1            1           9m25s

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/app1-deployment-58b98b5665   1         1         1       3m18s
```

But our deployment isn’t complete yet. In order to deploy a web application, we need a port to listen on.

`kubectl explain deployment.spec.template.spec.containers.ports`

Note that `ports` is of type `<[]ContainerPort>`. So we must input it as a list of items. The plurality could be a hint, which I find helpful. The number of port to expose is the `containerPort` field, and the [`traefik/whoami` documentation](https://hub.docker.com/r/traefik/whoami) states that the default port number is 80.

```yaml
# p2/confs/app1-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1-deployment
spec:
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
        - name: app1
          image: traefik/whoami
          ports:
            - containerPort: 80
```

Let’s update the deployment:

```bash
$ kubectl apply -f /vagrant/confs/app1-deployment.yaml
deployment.apps/app1-deployment configured
```

Note that app2 requires 3 replicas (under `spec`). I’ll leave that to you!

If unspecified, the number of replicas of a deployment defaults to 1. It is considered good practice to always specify the number of replicas, even if that number is 1—the default number.

<https://kubernetes.io/docs/concepts/workloads/controllers/deployment/>

### Services

Now that our pods are deployed. We need to access them. Once again, we’re starting from scratch:

```yaml
# p2/confs/app1-service.yaml

# From API reference header
# ```
# $ kubectl explain service
# KIND:       Service
# VERSION:    v1
# ```

apiVersion: v1         # <VERSION>
kind: Service          # <KIND>
metadata:
  name: app1-service   # Resource Name
```

```bash
$ kubectl apply -f /vagrant/confs/app1-service.yaml
The Service "app1-service" is invalid: spec.ports: Required value
```

**spec.ports**

`kubectl explain service.spec.ports`

The only required field is `port`. We will expose port 80 for HTTP traffic.

```yaml
# p2/confs/app1-service.yaml

apiVersion: v1
kind: Service
metadata:
  name: app1-service
spec:
  ports:
    - port: 80
```

```bash
$ kubectl apply -f /vagrant/confs/app1-service.yaml
service/app1-service created
```

Now let’s see what we’ve got:

```bash
$ kubectl get all
NAME                                   READY   STATUS    RESTARTS   AGE
pod/app1-deployment-58b98b5665-xmt5j   1/1     Running   0          16m

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/app1-service   ClusterIP   10.43.181.140   <none>        80/TCP    5s
service/kubernetes     ClusterIP   10.43.0.1       <none>        443/TCP   40h

NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/app1-deployment   1/1     1            1           22m

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/app1-deployment-58b98b5665   1         1         1       16m
replicaset.apps/app1-deployment-8c569789d    0         0         0       22m
```

Now, we need our service to point to our deployment. The `spec.selector` routes service traffic to their matches. Our selector for `app1-deployment` was `app: app1`.

Also, since we are deploying a web application, the service will be listening on port 80, which is the conventional port for HTTP traffic. Incoming requests to this service on port 80 are then forwarded to the deployment’s `containerPort` (via `targetPort`). Therefore, deployment’s `containerPort` must be the same as the service’s `targetPort`.

```yaml
# p2/confs/app1-service.yaml

apiVersion: v1
kind: Service
metadata:
  name: app1-service
spec:
  selector:
    app: app1
  ports:
    - port: 80
      targetPort: 80
```

Now to check that everything is working:

```bash
$ kubectl port-forward service/app1-service 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

And in another terminal (again, within our server machine):

```bash
$ curl 127.0.0.1:8080
Hostname: app1-deployment-6fcb858b89-2xz9x
IP: 127.0.0.1
IP: ::1
IP: 10.42.0.14
IP: fe80::8fc:3ff:fee7:f7e0
RemoteAddr: 127.0.0.1:37712
GET / HTTP/1.1
Host: 127.0.0.1:8080
User-Agent: curl/8.5.0
Accept: */*
```

### Ingress

Kubernetes has officially announced that Gateway is replacing Ingress. As of now, the Ingress API is frozen and is no longer being developed. We can expect no further changes or updates made to it. That said, there seems to be no intent to remove ingress from Kubernetes. And since it is still widely used in production (migration takes time), I feel that it is still worth exploring.

Furthermore, Gateway requires more configuration and has a steeper learning curve compared to Ingress. Since we only need simple features, using Gateway add unnecessary complexity to this project. It is also said that it would be easier to learn Ingress first, and then move on to Gateway. Might as well take this opportunity to get familiar with Ingress first, and try Gateway in a future, more advanced project.

The following is a minimal Ingress resource example provided in the [official Ingress documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/), so we’ll start from here:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
spec:
  ingressClassName: nginx-example
  rules:
  - http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80
```

`apiVersion`: API Version

```yaml
apiVersion: networking.k8s.io/v1
```

`kind`: Type of resource

```yaml
kind: Ingress
```

`metadata`: Name of resource

```yaml
metadata:
  name: iot-ingress
```

`spec`:

Following the sample ingress manifest, the only noteworthy difference is substituting Nginx with Traefik, which is more suited for automation.

```yaml
spec:
  ingressClassName: traefik
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app3-service
            port:
              number: 80
```

Repeat for app 1 and app2:

```yaml
  - host: app1.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
  - host: app2.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

Notice that there is an additional configuration `host:` that matches the `Host` header on incoming requests. Then, `backend:` routes it to its service. The absence of this configuration in the previous service means that it is the default service if no matching `Host` headers are provided.

## Configuration Automisation

**Launch Script**

As previously mentioned, manifests in a directory can be applied all at once. Don’t worry if some of the resources in the directory are already up and running, since `kubectl apply` is idempotent.

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
CONF_DIR="$PWD/confs"
kubectl apply -f "${CONF_DIR}"
```

**In Vagrantfile, provision machine to include manifest directory and run script**

```ruby
SERVER		= "nlamS"
SERVER_IP	= "192.168.56.110"

	# Server Machine
	config.vm.define SERVER do |server|
		server.vm.hostname = SERVER
		server.vm.network "private_network", ip: SERVER_IP
		server.vm.provision "file", source: "confs", destination: "$HOME/confs"
		server.vm.provision "shell", path: "scripts/server.sh"
		server.vm.provision "shell", path: "scripts/launch.sh"
	end
```

---

# Part 3 - K3d & ArgoCD

---

## Overview

### Components

1. **Host** - Host virtual machine
2. **K3D** - Local Kubernetes cluster running in Docker
3. **ARGO (Argo CD)** - GitOps controller running inside K3D
4. **Git (GitHub)** - Public repository containing Kubernetes manifests
5. **Docker Hub** - Registry hosting application images (wil42/playground or your own)
6. **App in docker** - Deployed application (www container)

---

## K3d

As described in [k3d’s official documentation](https://k3d.io/stable/): k3d is a lightweight wrapper to run k3s in docker. Differing from Part 1 and Part 2, we will not need to launch machines on which to install and run k3s. Docker containers will take on the role of that of the machines we used in Part 1 and 2. And instead of creating and deploying docker containers ourselves, k3d will be doing it for us.

### K3d vs K3s

Several sources tend to describe the two as similar, but in my personal opinion, they are completely different tools. K3s is a lightweight version of Kubernetes, and k3d is a tool used to run kubernetes in docker. As we have demonstrated in Part 1 and 2, k3s can be installed and run on an arbitrary machine, and is not dependent on k3d in any way. However, without kubernetes, there will be nothing for k3d to run.

### Fundamentals

```bash
# Create a cluster
k3d cluster create p3

# List existing clusters
k3d cluster list
# Switch to another cluster
kubectl config use-context k3d-<cluster-name>

# Delete a specific cluster
k3d cluster delete p3
# Delete all clusters
k3d cluster delete --all
```

Creating a cluster will automatically place you within the created cluster. If you create another cluster, you will be switched from the initial cluster to the newly created one.

### Configuration Files

<https://k3d.io/stable/usage/configfile/>

It is considered good practice to create clusters that need to be reproduced from cluster config files. For the sake of learning, let’s try it out:

```yaml
# p3/p3-config.yaml

# Minimal configuration (configures nothing)
apiVersion: k3d.io/v1alpha5
kind: Simple
```

Now let’s add on some useful details:

```yaml
# p3/p3-config.yaml

# Required
apiVersion: k3d.io/v1alpha5
kind: Simple
name: p3
```

There, much better.

To access Argo CD from the host machine later on, the cluster also needs a port mapping. This maps port 8443 of the virtual machine to port 443 of the cluster’s load balancer, where Traefik listens for HTTPS traffic.

```yaml
# p3/p3-config.yaml

apiVersion: k3d.io/v1alpha5
kind: Simple
name: p3
ports:
  - port: 8443:443
    nodeFilters:
      - loadbalancer
```

```bash
# Create cluster
k3d cluster create --config p3-config.yaml
```

### Namespaces

<https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/>

<https://kubernetes.io/docs/tutorials/cluster-management/namespaces-walkthrough/>

We need two namespaces: `argocd` and `dev`. We can create a namespace via `kubectl apply -f` with the following manifest.

```yaml
# p3/argocd-namespace.yaml

apiVersion: v1
kind: Namespace
metadata:
  name: argocd
  labels:
    name: argocd
```

Must we do it this way? Not really. Let’s try this other way for the namespace `dev`

```bash
kubectl create namespace dev
```

To see existing namespaces, all three of the following commands work:

```bash
kubectl get ns
kubectl get namespace
kubectl get namespaces
```

---

## ArgoCD

<https://argo-cd.readthedocs.io/en/stable/getting_started/>

### Installation

```bash
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

### Configure Access to Argo CD from Browser or CLI

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

### Obtain password

The default username is `admin`. And to obtain the password needed to sign into argo:

```bash
# Show password automatically assigned to admin
argocd admin initial-password -n argocd
```

### Ingress

<https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#traefik-v30>

Traefik handles HTTPS, so Argo CD itself can serve plain HTTP (`server.insecure`). The IngressRoute then sends requests for `argocd.localhost` to the `argocd-server` service.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmd-params-cm
  namespace: argocd
data:
  server.insecure: "true"
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: argocd-server
  namespace: argocd
spec:
  entryPoints:
    - websecure
  routes:
    - kind: Rule
      match: Host(`argocd.localhost`)
      priority: 10
      services:
        - name: argocd-server
          port: 80
    - kind: Rule
      match: Host(`argocd.localhost`) && Header(`Content-Type`, `application/grpc`)
      priority: 11
      services:
        - name: argocd-server
          port: 80
          scheme: h2c
  tls: {}
```

```bash
kubectl apply -f <argocd ingress manifest>
# Argo CD only reads server.insecure at startup, so restart it
kubectl rollout restart deployment argocd-server -n argocd
```

To setup the website in virtual machine to be accessible on host machine, no extra command is needed: the `hostfwd=tcp::8000-:8443` rule from Part 0 forwards port 8000 of the host machine to port 8443 of the virtual machine, which k3d maps to Traefik.

Access at [`https://argocd.localhost:8000`](https://argocd.localhost:8000/) (the browser will warn about Traefik’s self-signed certificate)

Application manifest files

<https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#applications>

```bash
kubectl apply -f application.yaml
```

```bash
kubectl describe application p3-application -n argocd
```

```bash
kubectl port-forward svc/part3-service -n dev 8888:8888
```

---

## Troubleshooting

- `Connection refused`

    ```bash
    # Re-apply the manifest
    kubectl apply -n argocd -f <application manifest>
    ```

    ```bash
    # Shows only pods in namespace argocd that are running
    kubectl get pods -n argocd --field-selector=status.phase=Running -o wide
    # Check last 100 logs of argocd-server pod
    kubectl logs -n argocd <server pod name from previous command> --tail=100
    ```

- `bind: address already in use`

    ```bash
    # Find out what is occupying port 8443
    sudo ss -ltnp | grep ':8443'
    # Check if old port-forwarding is blocking 8443
    ps aux | grep '[k]ubectl port-forward'

    # Kill process
    kill <pid>
    ```


---

## Restarting

If things really don’t go your way and you can’t seem to fix it. Let’s perhaps try the equivalent of turning it of and rebooting it.

1. Restart the deployment in argocd namespace

    ```bash
    kubectl rollout restart deployment -n argocd
    ```

2. Recreate the namespace argocd

    ```bash
    # This deletes Argo CD, so it must be reinstalled
    kubectl delete namespace argocd
    kubectl create namespace argocd
    kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    # Then re-apply the ConfigMap, IngressRoute and Application manifests
    ```

3. Recreate the cluster k3d-p3

    ```bash
    k3d cluster delete p3
    k3d cluster create --config p3-config.yaml
    ```

---

# Part Bonus - GitLab

---

## Prerequisites

### Resources

GitLab calls for a certain amount of resources:

- Verify VM has enough resources (min 12GB RAM, 3 CPUs with a minimal configuration — resize if needed)<br>
Personally I used: 12 GB and 10 CPUs.

### Helm

<https://helm.sh/docs/intro/install/>

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
```

---

## Installation and Deployment

<https://www.stellarhosted.com/gitlab/kubernetes/>

1. Create `gitlab` namespace in the cluster

    ```bash
    kubectl create namespace gitlab
    ```

2. Add GitLab's official Helm chart repo

    ```bash
    helm repo add gitlab https://charts.gitlab.io/
    helm repo update
    helm search repo gitlab
    ```

3. Configure `values.yaml`

    This part is a real headache. There are tons of possibilities for the entire file. Our goal is to have a fully functional yet minimal configuration.

    Taking [values-gke-minimum.yaml](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/5bcb942b4d562ffd4cf3647997b80c3d8cdfa4bb/examples/values-gke-minimum.yaml) as our sample:

    ```yaml
    global:
      hosts:
        domain: localhost
        gitlab:
          name: gitlab.localhost
        minio:
          name: minio.localhost
        https: false
      ingress:
        configureCertmanager: false
        class: "traefik"
        tls:
          enabled: false
      rails:
        bootsnap:
          enabled: false
      pages:
        enabled: false
      kas:
        enabled: false  # kubernetes agent server

    installCertmanager: false
    nginx-ingress:
      enabled: false
    prometheus:
      install: false
    registry:
      enabled: false
    gitlab-runner:
      install: false

    redis:
      resources:
        requests:
          cpu: 10m
          memory: 64Mi
        limits:
          memory: 256Mi
    minio:
      resources:
        requests:
          cpu: 10m
          memory: 64Mi
        limits:
          memory: 256Mi

    gitlab:
      webservice:
        minReplicas: 1
        maxReplicas: 1
        resources:
          requests:
            cpu: 100m
            memory: 2G
          limits:
            memory: 5G
        workhorse:
          resources:
            requests:
              cpu: 10m
              memory: 10M
            limits:
              memory: 100M
      sidekiq:
        minReplicas: 1
        maxReplicas: 1
        concurrency: 2
        resources:
          requests:
            cpu: 50m
            memory: 1G
          limits:
            memory: 3G
      gitaly:
        resources:
          requests:
            cpu: 100m
            memory: 500Mi
          limits:
            memory: 1.5G
      gitlab-shell:
        enabled: false
      toolbox:
        enabled: false
      praefect:
        enabled: false
      spamcheck:
        enabled: false  # spam checking service
    ```

    - Disable unnecessary components (Registry, Pages, etc.) to save RAM
    - Set it to run locally (no external domain, use `localhost` or a local IP)
    - Disable TLS or use self-signed certs
4. Deploy via Helm into the `gitlab` namespace

    ```bash
    helm install gitlab gitlab/gitlab --version 9.11.12 --values values.yaml --namespace gitlab
    ```

    If already deployed, use `upgrade` instead:

    ```bash
    helm upgrade gitlab gitlab/gitlab --version 9.11.12 --values values.yaml --namespace gitlab
    ```

5. Wait for pods to be ready (can take 5–15 min)

    ```bash
    # Watch pods to see if everything is running smoothly
    kubectl get pods -n gitlab -w
    ```

6. Check status

    ```bash
    helm status gitlab -n gitlab
    ```

7. Check memory

    ```bash
    kubectl top pods -n gitlab
    #NAME                                             CPU(cores)   MEMORY(bytes)
    #gitlab-certmanager-846f5c6585-x8967              3m           45Mi
    #gitlab-certmanager-cainjector-645d574d56-w8kcr   3m           57Mi
    #gitlab-certmanager-webhook-6f8b898987-f8j7r      1m           31Mi
    #gitlab-gitaly-0                                  5m           216Mi
    #gitlab-gitlab-exporter-64f46b5fc-fdl72           7m           38Mi
    #gitlab-kas-ddcb84bf9-n9mhk                       2m           26Mi
    #gitlab-kas-ddcb84bf9-zztqv                       2m           27Mi
    #gitlab-minio-77cc4458d4-rt57j                    1m           7Mi
    #gitlab-postgresql-0                              10m          127Mi
    #gitlab-redis-master-0                            18m          55Mi
    #gitlab-sidekiq-all-in-1-v2-67cfffc9f7-27455      69m          1379Mi
    #gitlab-webservice-default-5f788d96bd-zsfgx       13m          1961Mi
    ```

    All memory should be within allocated `limit` in `values.yaml`. Otherwise, the pod will be killed with error `OOMKilled`.

8. Retrieve root password

    ```bash
    kubectl get secret gitlab-gitlab-initial-root-password \
      -n gitlab \
      -o jsonpath="{.data.password}" | base64 --decode
    echo
    ```

9. Login with username “root” and echo-ed password

---

## Configuration

- Create a GitLab user/group

```text
Sign in to GitLab as an administrator.
Go to Admin Area.
Select Users.
Click New user.
Enter the user's:
    Name
    Username
    Email
    Password, if applicable
Configure any required settings, such as access level or administrator status.
Click Create user.
```

For [GitLab.com](http://gitlab.com/), users normally create their own accounts and you then add them to groups/projects.<br>
Create a GitLab group

```text
Sign in to GitLab.
Click Create new (the + button).
Select New group.
Choose Create group.
Enter:
    Group name — e.g. my-company
    Group URL/path — e.g. my-company
    Visibility: Private, Internal, or Public
Click Create group.
```

You can then add users through Group → Manage → Members and assign roles such as Guest, Reporter, Developer, Maintainer, or Owner.

- Create a new repository mirroring your GitHub one
- Push your `deployment.yaml` and config files to it

---

## Argo CD Reconfiguration

- Update your Argo CD `Application` manifest to point to GitLab instead of GitHub. Since Argo CD runs inside the cluster, use GitLab’s in-cluster address as `repoURL`. A public GitLab project needs no credentials.

```text
http://gitlab-webservice-default.gitlab.svc:8181/<group>/<project>.git
```

- Verify Argo CD syncs successfully from GitLab

---

## Verification

- Change the app version in your GitLab repo (`v1` → `v2`)
- Confirm Argo CD detects and syncs the change
- Confirm the pod updates and `curl localhost:8888` returns the new version

---

# The Playbook (ft. Ansible)

---

I created two Ansible playbooks to automatise everything.

`provision.yml`

For learning purposes I think it is still useful to go through the process of setting up the working environment. However, as we know, virtual machines are not always safe on 42 stations. If for any reason yours gets corrupted or disappears, that might be a good excuse to use the provisioning playbook.

`iot.yml`

This playbook is available on my github because it is the fruit of my blood, sweat, and tears.
It is not perfect, but I am still proud of it.
Do not use this playbook to skip doing the actual work expected of this project.
I do not wish to be asked to take it down due to any abuse from fellow students.

---

### Installation

<https://docs.ansible.com/projects/ansible/latest/installation_guide/intro_installation.html>

Assuming python is already available, if Ansible is not yet installed on your station, install both the package and some dependencies:

```bash
pipx install ansible-core
pipx inject ansible-core netaddr
pipx ensurepath
PATH=$PATH:~/.local/bin
ansible-galaxy collection install community.docker community.general kubernetes.core
ansible-galaxy role install geerlingguy.docker averagebit.k3d
```

If even after installation, or the next time you login to the stations, Ansible is no longer found, that’s probably just because its path is a little lost.

```bash
PATH=$PATH:~/.local/bin
```

---

### Authorisation

1. Establish a first connection between the host machine and the virtual machine. This saves the host machine as a known host and ensures ansible will be able to connect without any hiccups.

    ```bash
    ssh-keyscan -p 2222 -H localhost >> ~/.ssh/known_hosts
    # Optional: check the entry was added
    ssh-keygen -f ~/.ssh/known_hosts -F '[localhost]:2222'
    # If you recreated the VM and SSH warns the key changed, remove the old entry
    ssh-keygen -f ~/.ssh/known_hosts -R '[localhost]:2222'
    ssh -p 2222 <user>@localhost
    ```

2. Add current user into sudo group so that Ansible can run privileged commands.

    ```bash
    su -
    usermod -aG sudo <user>
    exit
    newgrp sudo
    groups
    ```

---

### Run playbook

```bash
ansible-playbook -i inventory.ini provision.yml -k -K
```

---

### Cleanup

Storage is precious at 42. It’s always a good idea to cleanup after ourselves, be it in the clusters, shokudo, and even on our `/home`.

See what we have installed:

```bash
$ pipx list
venvs are in /home/nlam/.local/share/pipx/venvs
apps are exposed on your $PATH at /home/nlam/.local/bin
manual pages are exposed at /home/nlam/.local/share/man
   package ansible-core 2.21.4, installed using Python 3.13.5
    - ansible
    - ansible-config
    - ansible-console
    - ansible-doc
    - ansible-galaxy
    - ansible-inventory
    - ansible-playbook
    - ansible-pull
    - ansible-test
    - ansible-vault
   package netaddr 1.3.0, installed using Python 3.13.5
    - netaddr
```

Uninstall everything:

```bash
# Uninstall
pipx uninstall ansible-core

# Check
pipx list
ls ~/.local/bin | grep ansible
ls -la ~/.local/share/pipx/venvs/ansible-core 2>/dev/null

# Remove any remaining files
rm -rf ~/.ansible
rm -rf ~/.local/share/pipx/venvs/ansible-core
```
