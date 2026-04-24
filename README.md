# k8s-install-cluster

# ☸️ Kubernetes Cluster Installation Guide

![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-blue?logo=kubernetes)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?logo=ubuntu)
![Containerd](https://img.shields.io/badge/Containerd-2.x-575757)
![License](https://img.shields.io/badge/License-MIT-green)

> 🚀 Déploiement rapide d’un cluster Kubernetes (Control Plane + Workers) sur Ubuntu 24.04  
> 💡 Compatible lab, formation et préparation CKA

---

# 🎯 Overview

Ce repository permet de déployer un cluster Kubernetes complet avec :

- ⚙️ containerd (runtime)
- ☸️ kubeadm / kubelet / kubectl
- 🌐 CNI Calico
- 🔥 Exposition NodePort

---

# 🏗️ Architecture

```
        +----------------------+
        |   Control Plane      |
        |  (API + Scheduler)   |
        +----------+-----------+
                   |
        -------------------------
        |                       |
+---------------+     +---------------+
|   Worker 1    |     |   Worker 2    |
|   Pods        |     |   Pods        |
+---------------+     +---------------+
```

---

# 🧠 Prérequis

- Ubuntu 24.04 LTS
- Accès root ou sudo
- Accès Internet
- Ports ouverts :
  - 6443 (API)
  - 30000-32767 (NodePort)

---

# 🚀 CONTROL PLANE SETUP

## 1. Clone repository

```bash
git clone https://github.com/AlexandreDomont/k8s-install-cluster.git
cd k8s-install-cluster/U24.04_SCALWAY_K1.30
```

## 2. Install container runtime

```bash
./00-setup-container.sh
```

## 3. Install Kubernetes tools

```bash
./02-setup-kubetools.sh
```

## 4. Retrieve node IP

```bash
CONTROL_PLANE_IP=$(ip -4 addr show ens2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo $CONTROL_PLANE_IP
```
> Attention: ens2 ici

## 5. Initialize cluster

```bash
kubeadm init \
  --apiserver-advertise-address=$CONTROL_PLANE_IP \
  --pod-network-cidr=192.168.0.0/16
```

## 6. Configure kubectl

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## 7. Install CNI (Calico)

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.4/manifests/calico.yaml
```

## 8. Validate cluster

```bash
kubectl get nodes
kubectl get pods -A
```

---

# 🌐 TEST APPLICATION (NodePort)

```bash
kubectl run testpod --image=nginx
kubectl expose pod testpod --type=NodePort --port=80 --target-port=80 --name=test-service

NODE_IP=$(ip -4 addr show ens2 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
NODE_PORT=$(kubectl get svc test-service -o jsonpath='{.spec.ports[0].nodePort}')

curl http://$NODE_IP:$NODE_PORT/
```

---

# 👷 WORKER NODE SETUP

```bash
git clone https://github.com/AlexandreDomont/k8s-install-cluster.git
cd k8s-install-cluster/U24.04_SCALWAY_K1.30
./00-setup-container.sh
./02-setup-kubetools.sh

kubeadm join <CONTROL_PLANE_IP>:6443 \
  --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH>
```

---

# 🔁 RESET CLUSTER

```bash
kubeadm reset -f
ip link delete cni0 || true
ip link delete flannel.1 || true
ip link delete cali0 || true
rm -rf /etc/cni/net.d
rm -rf /var/lib/kubelet/*
rm -rf /etc/kubernetes/*
systemctl restart containerd
```

---

# 👨‍💻 Author

Alexandre Domont

---

# 📄 License

MIT
