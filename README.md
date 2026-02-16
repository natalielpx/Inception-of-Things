# Inception of Things - 42 project
## :open_file_folder: Project Overview
Introductory DevOps project to Vagrant and Kubernetes    
This project is divided into multiple parts, each introducing new tools and concepts essential to infrastructure management and container orchestration
## :hammer_and_wrench: Tutorial
I've documented my entire learning journey, from setup to completion. The official documentation is excellent for reference, but can be overwhelming when just starting out. This guide breaks down the project into manageable chunks and shares what I learnt from hands-on implementation.  

https://tinyurl.com/nlam-Inception-of-Things  

Written for students, by a student.
<!-- ## :triangular_ruler: Prerequisites
### Docker
Docker is required for K3d to function. It provides containerisation technology that K3d uses to run K3s clusters. -->
## :pushpin: Learning Objectives
### Vagrant
[Vagrant](https://developer.hashicorp.com/vagrant) is a tool for building and managing virtual machine environments in a single workflow.  
- Understand the concept of virtualisation.
- Learn to configure and provision virtual machines with a `Vagrantfile`.
- Set up multiple VMs and establish network communication between them.
- Automate environment setup for consistent deployments.
### K3s (Lightweight Kubernetes)
K3s is a lightweight Kubernetes distribution designed for resource-constrained environments.
- Learn the fundamentals of container orchestration.
- Understand how a Kubernetes cluster is structured (master node, worker nodes, pods, services, etc.).
- Deploy a simple containerised application to the cluster.
- Manage and observe cluster behaviour using basic `kubectl` commands.
### K3d
K3d is a lightweight wrapper to run K3s in Docker containers. 
- Understand the differences between K3s and K3d.
- Learn to quickly spin up Kubernetes clusters using Docker containers.
- Manage cluster lifecycle and configurations efficiently.
### ArgoCD
ArgoCD is a declarative GitOps continuous delivery tool for Kubernetes. 
- Implement continuous deployment using GitOps principles.
- Automatically sync application state from Git repositories.
- Manage application versions and rollbacks declaratively.
- Monitor deployment status through ArgoCD's web interface.
## :card_index_dividers: Contents
### Part 1 - K3s and Vagrant
Using Vagrant and K3s, set up a two-machine Kubernetes cluster that communicate via SSH without passwords and form a functional K3s cluster.   
- Server (Controller): K3s in controller mode at 192.168.56.110  
- ServerWorker (Agent): K3s in agent mode at 192.168.56.111  
### Part 2 - K3s and Three Simple Applications
On a single K3s server, deploy three web applications with Ingress-based routing that respond to IP 192.168.56.110 but route based on the HOST header.  
- app1: Accessible via HOST app1.com  
- app2: Accessible via HOST app2.com (3 replicas)  
- app3: Default application for all other requests  
### Part 3 - K3d and ArgoCD
🚧 In progress... 🚧  
Implement a continuous deployment pipeline using K3d and ArgoCD:  
Install K3d and Docker via an automated script  
Create two namespaces: argocd and dev  
Deploy an application in the dev namespace using ArgoCD  
Configure ArgoCD to sync with a public GitHub repository  
Demonstrate version updates (v1 → v2) through Git commits  
## :building_construction: Compilation
```
# Part 1

# Launch machines
cd p1
vagrant up

# Verify server machine
vagrant ssh <nlamS>
sudo kubectl get nodes -o wide

# Verify agent machine
vagrant ssh <nlamSW>
ip ip -s link show eth1
sudo journalctl -u k3s-agent -f # view logs in real-time
```
```
# Part 2

# Launch machines
cd p2
vagrant up

# Acess server machine
vagrant ssh <nlamS>

# Access applications via browser at 192.168.56.110 with different HOST headers
curl -H "Host:app1.com" 192.168.56.110		# connects to app1
curl -H "Host:app2.com" 192.168.56.110		# connects to app2
curl 192.168.56.110							# connects to app3
```
```
# Part 3

# In progress...
```
<!-- ## :mag: Resources -->
<!-- ### Vagrant -->
<!-- ### K3s -->