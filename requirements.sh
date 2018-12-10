#!/bin/bash

kube_version="1.13.0"

# Exit immediately if a command exits with a non-zero status
set -e

echo "Ensure that APT works with HTTPS..."
sudo apt-get -qq update -y
sudo apt-get -qq install -y \
  apt-transport-https \
  ca-certificates \
  software-properties-common \
  curl

echo "Add Kubernetes repo..."
sudo sh -c 'curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -'
sudo sh -c 'echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'

echo "Add Docker repo..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"


echo "Add GlusterFS repo..."
sudo add-apt-repository -y ppa:gluster/glusterfs-3.12

echo "Updating Ubuntu..."
sudo apt-get -qq update -y
sudo DEBIAN_FRONTEND=noninteractive \
  apt-get -y -qq \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  upgrade

echo "Installing Kubernetes requirements..."
sudo apt-get -qq install -y \
  docker-ce=18.06.1~ce~3-0~ubuntu \
  kubernetes-cni=0.6.0-00 \
  kubeadm=$kube_version-00 \
  kubelet=$kube_version-00 \
  kubectl=$kube_version-00 \


echo "Installing other requirements..."
# APT requirements
sudo apt-get -qq install -y \
  python \
  daemon \
  attr \
  glusterfs-client \
  nfs-common \
  jq

# Helm
HELM_TGZ=helm-v2.10.0-linux-amd64.tar.gz
wget -P /tmp/ https://kubernetes-helm.storage.googleapis.com/$HELM_TGZ
tar -xf /tmp/$HELM_TGZ -C /tmp/
sudo mv /tmp/linux-amd64/helm /usr/local/bin/

# Heketi
HEKETI_TGZ=heketi-client-v5.0.0.linux.amd64.tar.gz
wget -P /tmp/ https://github.com/heketi/heketi/releases/download/v5.0.0/$HEKETI_TGZ
tar -xf /tmp/$HEKETI_TGZ -C /tmp/
sudo mv /tmp/heketi-client/bin/heketi-cli /usr/local/bin/
sudo chmod 0755 /usr/local/bin/heketi-cli
rm -R /tmp/heketi-client/

echo "Pulling required Docker images..."
# Essential Kubernetes containers are listed in following files:
# https://github.com/kubernetes/kubernetes/blob/master/cmd/kubeadm/app/constants/constants.go (etcd-version)
# https://github.com/kubernetes/kubernetes/blob/master/cluster/addons/dns/kubedns-controller.yaml.base (kube-dns-version)

sudo kubeadm config images pull --kubernetes-version=v$kube_version
# The above command will pull the following images.
#     k8s.gcr.io/kube-apiserver:v1.13.0
#     k8s.gcr.io/kube-controller-manager:v1.13.0
#     k8s.gcr.io/kube-scheduler:v1.13.0
#     k8s.gcr.io/kube-proxy:v1.13.0
#     k8s.gcr.io/pause:3.1
#     k8s.gcr.io/etcd:3.2.24
#     k8s.gcr.io/coredns:1.2.6

# Pull the flannel image
sudo docker pull quay.io/coreos/flannel:v0.10.0

# After having installed all the necessary packages, we check whether there are related security-updates
sudo apt-get -qq update -y && sudo unattended-upgrades -d
