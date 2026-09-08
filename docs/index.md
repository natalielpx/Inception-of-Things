# 42 Inception of Things - Kubernetes

# Part 0 - Setup a Virtual Machine

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

# Part 1 - Vagrant x K3s

## Vagrant

Vagrant is a command-line tool that works with virtualization software (like **VirtualBox**, **VMware**, or **Libvirt**) to:

- Create lightweight, disposable development environments
- Share consistent setups across the team
- Automate provisioning (installing packages, configuring services, etc.)

### Vagrantfiles

Vagrantfiles are just Ruby scripts that Vagrant reads. It is used to describe, configure, and provision our desired machine(s).

You can create a Vagrantfile via `vagrant init`, or simply create a file named `Vagrantfile`.

```
.
└── pt1
    └── Vagrantfile
```

```yaml
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

We can look for vagrant boxes here: 

```yaml
Vagrant.configure("2") do |config|

	# Vagrant box
	config.vm.box = "generic/debian12"
	config.vm.box_version = "4.3.12"
	
end
```

- In `.box`, the name before `/` is the creator, and the name after it is the distribution. It goes without saying that it is advised to use boxes from reputable owners.
- `.box_version` is useful to ensure that even if a newer version becomes available, the precise version that is requested will be use. This is helpful to avoid any compatibility issues that may arise from an unexpected update.
- remove
    
    **Synced (Shared) Folders**
    
    ```bash
    .
    └── pt1
        ├── .shared
        └── Vagrantfile
    ```
    
    ```yaml
    Vagrant.configure("2") do |config|
    
    	# Vagrant box
    	config.vm.box = "generic/debian12"
    	config.vm.box_version = "4.3.12"
    	# Synced Folders
    	config.vm.synced_folder ".shared", "/vagrant_shared"
    	
    end
    ```
    
    All machines configured under this configuration will have access to the synced folder. We will be using this synced folder to store the K3s token that we will be needing later on.
    
    - The first argument is the relative path of the folder to the root directory. This folder should be created beforehand. Here we are using the folder `.shared` (which is already present in our directory). Any files stored inside the synced folders within the machines will also be stored here, in the root of the repository.
    - The second argument is the absolute path of the folder within the machine(s). Files to be shared with the other machines are to be placed into this folder.

**Providers**

Vagrant itself doesn’t virtualise anything directly. It’s more like a universal controller that talks to other virtualisation tools. A provider in Vagrant is the backend system that actually *creates, runs, and manages* your virtual machines (VMs). Providers have to be installed on the host machine. In our case, we have already installed libvirt, and that is what we will be using.

```yaml
Vagrant.configure("2") do |config|

	# Vagrant box
	config.vm.box = "generic/debian12"
	config.vm.box_version = "4.3.12"
	# Provider
	config.vm.provider "libvirt" do |lv|
		lv.cpus = 1
		lv.memory = 1024
	end
		
end
```

- `.provider "”` takes in its argument as the provider. Here, libvirt is our choice of provider.
- `.cpus` is the number of processors allocated to each machine. Here we are only allocating 1 per machine. Allocating more will quickly deplete the amount of CPUs we have allocated to our host machine.
- `.memory` is the base memory allocated to each machine. Here we are using 1024MB so as to not overload our host machin

### Machines

```yaml
Vagrant.configure("2") do |config|

	# Global configurations (applied across all machines)
	config.vm.box = "generic/debian12"
	config.vm.box_version = "4.3.12"
	config.vm.provider "libvirt" do |lv|
		lv.cpus = 1
		lv.memory = 1024
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
```

- `.define ""` defines a machine by the name of the argument it is passed to. This name will be used by Vagrant when we are using vagrant commands.
- `.hostname` declares the hostname of the OS of machine. Essentially, this is the name the machine recognises itself with.
- `.network "private_network"`  exposes the machine to the local network. This network is inaccessible to the internet. The machines can be accessed via their designated IP.

### Vagrant Commands

Here is a non exhaustive collection of useful vagrant commands:

- `vagrant init` Creates an initial Vagrantfile
- `vagrant up` Creates and configures machines according to Vagrantfile
- `vagrant up --no-parallel` Creates and configures machines one after another
- `vagrant provision`
- `vagrant destroy -f` Destroys all resources that were created without asking for confirmation
- `vagrant ssh [name|id]` SSHs into a running Vagrant machine
- `vagrant status` Shows state of Vagrant machines

## K3s Server & Server Worker (Agent) Installation

Now that we have two machines, one of these machines will be provisioned as a K3s server, and the other will its server worker (agent). We will be installing K3s on the machines with scripts.

```
.
└── pt1
    ├── scripts
    │   ├── agent.sh
    │   └── server.sh
    └── Vagrantfile
```

```yaml
Vagrant.configure("2") do |config|

	# Global configurations (applied across all machines)
	config.vm.box = "generic/debian12"
	config.vm.box_version = "4.3.12"
	config.vm.provider "libvirt" do |lv|
		lv.cpus = 1
		lv.memory = 1024
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
		
		agent.vm.provision "shell", path: "./scripts/agent.sh"
end
```

`.provision` provides variable options to provisioning our machine

`”shell”` allows us to provision our machines with a shell script. There is an option of including our scripts inline with `inline:`, but here we are choosing to use `path:` as I find it is cleaner.

`“file”` allows us to copy files or folders from a specific `source:` path into the `destination:` path on our machines.

**K3s Server Installation Script**

```bash
#!/usr/bin/env bash

# K3s Server

# Install dependencies
apt update && apt install -y curl

# Install K3s (as server)
curl -sfL https://get.k3s.io | sh -
```

**K3s Agent Installation Script**

```bash
#!/usr/bin/env bash

# K3s Agent

# Install dependencies
apt update && apt install -y curl

# Wait until token exists and server responds
until curl -k https://192.168.56.110:6443 >/dev/null 2>&1; do
  echo "Waiting for K3s server to be ready..."
  sleep 5
done

# Export values (essential to install K3s as agent)
export K3S_URL=https://192.168.56.110:6443
export K3S_TOKEN_FILE=/vagrant_shared/token

# Install K3s (as agent)
curl -sfL https://get.k3s.io | sh -
```

## Launch

1. Launch the machines with `vagrant up` and wait for the machines to be ready.
2. Check the status of the machines with `vagrant status` to ensure both machines are up and running.
3. Check that the server machine is running correctly.
    1. Access server with `vagrant ssh [server]` where `[server]` is the name of the server machine.
    2. Run `sudo kubectl get node -o wide` and compare results with that in the subject.
4. Check that the agent machine is running correctly.
    1. Access server with `vagrant ssh [agent]` where `[agent]` is the name of the agent machine.
    2. Run `ip -s link show eth1` and compare results with that in the subject.
    3. If something is wrong, run `sudo journalctl -u k3s-agent -f` to view agent logs in real-time.

# Part 2 - K3s

In Part 2, we will be setting up 3 web applications that will run in our K3s instance. We will create the required resources (deployments, services, ingress) via YAML files. It is also possible to deploy pods through CLI commands, but YAML files provide an abundance of advantages:

- **Version control** - Track changes in Git
- **Reproducible** - Easy to recreate exact configuration
- **Documentation** - Self-documenting infrastructure
- **Complex configurations** - Handle multi-field specifications easily
- **Best practice** - Industry standard for production
- **Peer review** - Team can review before applying
- **Reusable** - Template and modify for different environments

sudo apt-get install -y nfs-kernel-server

## Vagrantfile

As we have done in Part 1, first, we need a machine on which we will run K3s. This time we only need one machine — a server machine. However, since we will be actually running a cluster of applications, we will allocate more resources.

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant configuration
Vagrant.configure("2") do |config|

	# Global configurations (applied across all machines)
	config.vm.box = "bento/ubuntu-24.04"
	config.vm.provider "vmware_desktop" do |vmw|
		vmw.vmx["numvcpus"] = "1"
		vmw.vmx["memsize"] = "512"
		vmw.gui = false
	end

	# Server Machine
	config.vm.define "nlamS" do |server|
		server.vm.hostname = "nlamS"
		server.vm.network "private_network", ip: "192.168.56.110"
		server.vm.provision "shell", path: "./scripts/server.sh"
	end

end
```

This Vagrantfile is nearly identical to that of Part 1, except we have removed the agent machine. And since we don’t have an agent machine, we no longer need the shared folder that was used to share the token required to connect the agent machine to the server machine.

## K3s Server Installation and Setup

```
.
└── pt2
    ├── scripts
    │   ├── setup.sh
    │   └── server.sh
    └── Vagrantfile
```

**Installation Script**

Similar to Part 1, we are installing K3s as a server. However, since there is no agent machine, we will not be doing anything with the generated token.

```bash
#!/usr/bin/env bash

# K3s Server Installation

# Install dependencies
apt update && apt install -y curl

# Install K3s (as server) with forced IP configuration
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --flannel-iface=eth1" sh -
```

**Setup Script**

If you’ve tried running `kubectl get nodes` in part 1 and realised it doesn’t work without `sudo`, we’re here to address that.

```bash
#!/usr/bin/env bash

# Export environmental variable for KUBECONFIG
export KUBECONFIG=/home/vagrant/.kube

# Create .kube directory in home
mkdir -p /home/vagrant/.kube

# Copy K3s config file
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config

# Change ownership to user
chown vagrant:vagrant /home/vagrant/.kube/config

# Set proper permissions
chmod 600 /home/vagrant/.kube/config

# Add KUBECONFIG export to .bashrc if not already present
if ! grep -q "KUBECONFIG" /home/$user/.bashrc; then
  echo "export KUBECONFIG=$conf_file" >> /home/$user/.bashrc
fi
```

After ssh-ing into the server machine, we need to run `source /home/vagrant/.bashrc` for KUBECONFIG to actually be exported. 

Now try `kubectl` without `sudo`, it should work fine.

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
# pt2/confs/app1-deployment.yaml

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

```bash
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
# pt2/confs/app1-deployment.yaml

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
# pt2/confs/app1-deployment.yaml

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
# pt2/confs/app1-deployment.yaml

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
# pt2/confs/app1-deployment.yaml

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

Note that `ports` is of type `<[]ServicePort>`. So we must input it as a list of items. The plurality could be a hint, which I find helpful. The number of port to expose is the `containerPort` field, and the [`traefil/whoami` documentation](https://hub.docker.com/r/traefik/whoami) states that the default port number is 80.

```yaml
# pt2/confs/app1-deployment.yaml

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

https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

### Services

Now that our pods are deployed. We need to access them. Once again, we’re starting from scratch:

```bash
# pt2/confs/app1-service.yaml

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

```bash
# pt2/confs/app1-service.yaml

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
# pt2/confs/app1-service.yaml

apiVersion: v1
kind: Service
metadata:
  name: app1-service
spec:
  selector:
    app: app1
  ports:
    - port: 80
    - targetPort: 80
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

This is a minimal Ingress resource example provided in the [official Ingress documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/), so we’ll start from here.

`apiVersion`: API Version

```yaml
apiVersion: networking.k8s.io/v1
```

`kind`: Type of resource

```yaml
kind: Ingress
```

`metadata`: 

```yaml
metadata:
  name: minimal-ingress
```

`spec`:

```yaml
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

# **Part 3 - K3d & ArgoCD**

## Overview

### Components

1. **Host** - Host virtual machine
2. **K3D** - Local Kubernetes cluster running in Docker
3. **ARGO (Argo CD)** - GitOps controller running inside K3D
4. **Git (GitHub)** - Public repository containing Kubernetes manifests
5. **Docker Hub** - Registry hosting application images (wil42/playground or your own)
6. **App in docker** - Deployed application (www container)

### Structure

```bash

```

## Install Dependencies

### Docker

https://docs.docker.com/engine/install/debian/

```jsx
# Remove any conflicting packages
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc | cut -f1)

# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Installation
sudo apt update
sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Check running
sudo systemctl status docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Kubectl

```jsx
sudo apt-get update
sudo apt-get install -y kubectl
```

## K3d

As described in [k3d’s official documentation](https://k3d.io/stable/): k3d is a lightweight wrapper to run k3s in docker. Differing from Part 1 and Part 2, we will not need to launch machines on which to install and run k3s. Docker containers will take on the role of that of the machines we used in Part 1 and 2. And instead of creating and deploying docker containers ourselves, k3d will be doing it for us.

### K3d vs K3s

Several sources tend to describe the two as similar, but in my personal opinion, they are completely different tools. K3s is a lightweight version of Kubernetes, and k3d is a tool used to run k3s in docker. As we have done in Part 1 and 2, k3s can run on an arbitrary machine, and is not dependent on k3d in any way. However, without k3s, there will be nothing for k3d to run.

### Installation

https://k3d.io/stable/#quick-start

```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

### Fundamentals

```bash
# Create a cluster
k3d cluster create part3

# List existing clusters
k3d cluster list
# Switch to another cluster
kubectl config use-context k3d-<cluster-name>

# Delete a specific cluster
k3d cluster delete part3
# Delete all clusters
k3d cluster delete --all
```

Creating a cluster will automatically place you within the created cluster. If you create another cluster, you will be switched from the initial cluster to the newly created one.

### Configuration Files

https://k3d.io/v5.1.0/usage/configfile/

It is considered good practice to create clusters that need to be reproduced from cluster config files. For the sake of learning, let’s try it out:

```yaml
# p3/p3-config.yaml

# Minimal configuration (configures nothing)
apiVersion: k3d.io/v1alpha3
kind: Simple
```

```yaml
k3d cluster create --config p3-config.yaml
```

Now let’s add on some useful details:

```yaml
# p3/p3-config.yaml

# Required
apiVersion: k3d.io/v1alpha3
kind: Simple

```

### Namespaces

https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/

https://kubernetes.io/docs/tutorials/cluster-management/namespaces-walkthrough/

```bash
# p3/namespaces/argocd.yaml

apiVersion: v1
kind: Namespace
metadata:
  name:

```

## ArgoCD

https://argo-cd.readthedocs.io/en/stable/getting_started/

### Installation

```bash
kubectl create namespace argocd

kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

### Configure Access to Argo CD from Browser or CLI

```jsx
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

### Port Forwarding

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

The default username is `admin`. And to obtain the password needed to sign into argo:

```bash
# Show password automatically assigned to admin
argocd admin initial-password -n argocd
```

![image.png](42%20Inception%20of%20Things%20-%20Kubernetes/image.png)

Application manifest files

https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#applications

```bash
kubectl apply -f application.yaml
```

# Part Bonus - GitLab

## Prerequisites

### Resources

GitLab calls for a certain amount of resources:

- Verify VM has enough resources (min 4GB RAM, 2 CPUs — resize if needed)
Personally I used:

While my allocated resources are lower than recommended, it all worked out in the end. I suspect it is because our infrastructure load is minimal. Feel free to allocate the recommended amount of resources, though the 42 stations might not always be generous enough in these aspects.

### Helm

https://helm.sh/docs/intro/install/

```jsx
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
```

### PostgreSQL

https://docs.gitlab.com/charts/advanced/external-db/external-omnibus-psql/

`/etc/gitlab/gitlab.rb`

i’ll just use AUTH_CIDR_ADDRESS=172.19.0.0/16

```yaml
# Change the address below if you do not want PG to listen on all available addresses
postgresql['listen_address'] = '0.0.0.0'
# Set to approximately 1/4 of available RAM.
postgresql['shared_buffers'] = "512MB"
# This password is: `echo -n '${password}${username}' | md5sum - | cut -d' ' -f1`
# The default username is `gitlab`
postgresql['sql_user_password'] = "DB_ENCODED_PASSWORD"
# Configure the CIDRs for MD5 authentication
postgresql['md5_auth_cidr_addresses'] = ['AUTH_CIDR_ADDRESSES']
# Configure the CIDRs for trusted authentication (passwordless)
postgresql['trust_auth_cidr_addresses'] = ['127.0.0.1/24']

## Configure gitlab_rails
gitlab_rails['auto_migrate'] = false
gitlab_rails['db_username'] = "gitlab"
gitlab_rails['db_password'] = "DB_PASSSWORD"

## Disable everything else
sidekiq['enable'] = false
puma['enable'] = false
registry['enable'] = false
gitaly['enable'] = false
gitlab_workhorse['enable'] = false
nginx['enable'] = false
prometheus_monitoring['enable'] = false
redis['enable'] = false
gitlab_kas['enable'] = false
```

```yaml
# Reconfigure package
gitlab-ctl reconfigure

# Check processes 
gitlab-ctl status
# Excpected output
# run: logrotate: (pid 4856) 1859s; run: log: (pid 31262) 77460s
# run: postgresql: (pid 30562) 77637s; run: log: (pid 30561) 77637s
```

### Redis

## **Install GitLab**

https://www.stellarhosted.com/gitlab/kubernetes/

### Phase 2 — GitLab namespace + deployment

Create `gitlab` namespace in the cluster

```jsx
kubectl create namespace gitlab
```

- Add GitLab's official Helm chart repo
- Configure `values.yaml` — critical settings:
    - Disable unnecessary components (Registry, Pages, etc.) to save RAM
    - Set it to run locally (no external domain, use `localhost` or a local IP)
    - Disable TLS or use self-signed certs
- Deploy via Helm into the `gitlab` namespace
- Wait for pods to be ready (can take 5–15 min)
- Access GitLab UI and retrieve the root password

---

### Phase 3 — GitLab configuration

- Create a GitLab user/group
- Create a new repository mirroring your GitHub one
- Push your `deployment.yaml` and config files to it
- Generate an access token for Argo CD

---

### Phase 4 — Argo CD reconfiguration

- Add your local GitLab repo as a repository in Argo CD (via token or SSH)
- Update your Argo CD `Application` manifest to point to GitLab instead of GitHub
- Verify Argo CD syncs successfully from GitLab

---

### Phase 5 — Validate the full flow

- Change the app version in your GitLab repo (`v1` → `v2`)
- Confirm Argo CD detects and syncs the change
- Confirm the pod updates and `curl localhost:8888` returns the new version

---

### Phase 6 — Cleanup + repo structure

- Move all scripts and configs into the `bonus/` folder
    - `bonus/scripts/` — install script (Docker, K3d, Helm, GitLab, Argo CD)
    - `bonus/confs/` — all manifests and `values.yaml`
- Ensure the install script is runnable from scratch for the defense

# Best Practices

- Specifying number of replicas
- Specifying protocol
- Naming port for `containerPort`
    
    We shall give this port a name, so that when we can reference it in the service resource without stating the port number. If in the future, the container port has to be changed, it only has to be updated in the deployment.
