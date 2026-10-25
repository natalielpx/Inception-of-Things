# Inception of Things
 
A 42 project introducing Kubernetes through K3s, K3d, Vagrant and Argo CD.

## Tutorial
 
I've documented my entire learning journey, from setup to completion. The official documentation is excellent for reference, but can be overwhelming when just starting out. This guide breaks down the project into manageable chunks and shares what I learnt from hands-on implementation.
 
https://natalielpx.github.io/Inception-of-Things/
 
Written for students, by a student.
 
## Project Overview
 
Inception of Things is a system administration project from the 42 curriculum. It is split into three parts and a bonus, each building on the previous one:
 
| Part | What it does |
|---|---|
| **Part 1 — Vagrant x K3s** | Provisions two virtual machines with Vagrant and joins them into a K3s cluster: one server, one agent (server worker). |
| **Part 2 — K3s and three apps** | Runs three web applications on a single K3s server and routes traffic to them by hostname with an Ingress. |
| **Part 3 — K3d and Argo CD** | Runs K3s inside Docker with K3d and deploys an application continuously from a Git repository with Argo CD. |
| **Bonus — GitLab** | Self-hosts GitLab in the cluster with Helm and points Argo CD at it instead of GitHub. |
 
The entire project runs inside a single host virtual machine.
 
## Learning Objectives
 
- Provision and configure multiple virtual machines with Vagrant
- Install and connect K3s server and agent nodes
- Write Kubernetes manifests: Deployments, Services and Ingress
- Route traffic to several applications with Traefik
- Run Kubernetes clusters in Docker with K3d
- Practise GitOps: deploy from Git with Argo CD and sync changes automatically
- Deploy and tune a complex application (GitLab) with Helm

## Contents
 
```text
.
├── p1/          # Vagrant x K3s: server + agent machines
├── p2/          # K3s with three apps and an Ingress
├── p3/          # K3d cluster + Argo CD
├── bonus/       # Self-hosted GitLab with Helm
├── provision/   # Ansible playbook to set up the working environment
└── docs/        # Tutorial (GitHub Pages)
```
