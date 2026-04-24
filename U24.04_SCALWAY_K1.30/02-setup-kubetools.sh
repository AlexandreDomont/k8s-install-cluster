#!/bin/bash
set -e

# =========================================================
# Kubernetes tools install script - Ubuntu 24.04 compatible
# Version fixée pour stabilité (évite les bugs repo)
# =========================================================

if ! [ -f /tmp/container.txt ]; then
    echo "❌ run ./00-setup-container.sh before running this script"
    exit 4
fi

echo "🚀 Installing Kubernetes tools (kubeadm, kubelet, kubectl)"

# ---------------------------------------------------------
# VARIABLES
# ---------------------------------------------------------
KUBEVERSION="v1.30"

# ---------------------------------------------------------
# SYSTEM PREP
# ---------------------------------------------------------
echo "🔧 Configuring kernel modules"

cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

modprobe br_netfilter

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# ---------------------------------------------------------
# DEPENDENCIES
# ---------------------------------------------------------
echo "📦 Installing dependencies"

apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

# ---------------------------------------------------------
# CLEAN PREVIOUS CONFIG (important pour éviter bugs)
# ---------------------------------------------------------
echo "🧹 Cleaning old Kubernetes config"

apt-mark unhold kubelet kubeadm kubectl 2>/dev/null || true
apt-get remove -y kubelet kubeadm kubectl 2>/dev/null || true

rm -f /etc/apt/sources.list.d/kubernetes.list
rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# ---------------------------------------------------------
# ADD KUBERNETES REPO (version FIXÉE)
# ---------------------------------------------------------
echo "📥 Adding Kubernetes repo ${KUBEVERSION}"

mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBEVERSION}/deb/Release.key \
    | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/${KUBEVERSION}/deb/ /" \
    > /etc/apt/sources.list.d/kubernetes.list

apt-get update

# ---------------------------------------------------------
# INSTALL KUBERNETES
# ---------------------------------------------------------
echo "⚙️ Installing kubelet, kubeadm, kubectl"

apt-get install -y kubelet kubeadm kubectl cri-tools

apt-mark hold kubelet kubeadm kubectl

# ---------------------------------------------------------
# DISABLE SWAP (mandatory)
# ---------------------------------------------------------
echo "🛑 Disabling swap"

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# ---------------------------------------------------------
# START KUBELET
# ---------------------------------------------------------
echo "🔄 Starting kubelet"

systemctl enable kubelet
systemctl restart kubelet

# ---------------------------------------------------------
# CONFIGURE CRICTL
# ---------------------------------------------------------
echo "🔗 Configuring crictl"

crictl config runtime-endpoint unix:///run/containerd/containerd.sock

# ---------------------------------------------------------
# FINAL MESSAGE
# ---------------------------------------------------------
echo ""
echo "✅ Installation terminée"
echo ""
echo "👉 Prochaine étape (control plane) :"
echo ""
echo "kubeadm init \\"
echo "  --apiserver-advertise-address=<IP> \\"
echo "  --pod-network-cidr=192.168.0.0/16"
echo ""
echo "👉 Puis :"
echo "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
echo ""
