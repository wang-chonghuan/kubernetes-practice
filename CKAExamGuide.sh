#安装containerd
wget https://github.com/containerd/containerd/releases/download/v1.6.16/containerd-1.6.16-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.6.16-linux-amd64.tar.gz
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo cp ./containerd.service /usr/local/lib/systemd/system/
systemctl daemon-reload
systemctl enable --now containerd
systemctl restart containerd
wget https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
wget https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.2.0.tgz
ctr --help

#安装kubectl #用apt-get安装kubectl会出现8080端口无法访问的问题,所以必须用这个方法
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client --output=yaml

#disable swap for kubeadm
sudo swapoff -a
#确保这个端口没被占用
telnet 127.0.0.1 6443

#设置net.bridge.bridge-nf-call-iptables为1用于watch the bridged traffic
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

#安装kubeadm
#Update the apt package index, add the Google Cloud public signing key, and set up the Kubernetes apt repository
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
#注意https://apt.kubernetes.io/ kubernetes-xenial中间有个空格,否则会报malformed错误
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm
#固定软件的版本,使其不会自动升级, sudo apt-mark unhold kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
kubeadm
#验证kubelet是否在主节点上
which kubelet
#启动kubeadm时报错没有容器运行时的处理办法,因为容器运行时没有启动,1.26版本的k8s不支持docker,所以前提必须时ctr
rm /etc/containerd/config.toml
systemctl restart containerd
#pre-pull the images that are required to set up the Kubernetes cluster
sudo kubeadm config images pull
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
#报这个错误时[ERROR FileContent–proc-sys-net-ipv4-ip_forward]: /proc/sys/net/ipv4/ip_forward contents are not set to 1
echo 1 > /proc/sys/net/ipv4/ip_forward #必须切换到root用户
#After your Kubernetes control-plane is initialized, configure kubectl否则会出现会出现8080端口无法访问的问题
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

####配置k8s网络
#创造一个CRD for CNI Calico
#错 kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
#错 kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml
#如果遇到Unable to connect to the server: net/http: TLS handshake timeout
unset http_proxy
unset https_proxy
#如果k get nodes遇到The connection to the server 10.0.2.15:6443 was refused
sudo -i
swapoff -a
exit
strace -eopenat kubectl version
#以上另一种可能时,containerd挂了,要重启
sudo systemctl stop kubelet
systemctl restart containerd
sudo systemctl start kubelet

#卸载全套
kubeadm reset
sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube*   
sudo apt-get autoremove  
sudo rm -rf ~/.kube

#主节点重启后,kubectl get nodes报错The connection to the server localhost:8080 was refused
#有两个原因,一是没有关sudo swapoff -a,二是配置文件的环境变量没有设置,需要重新定义环境变量export KUBECONFIG=$HOME/admin.conf
$ cp /etc/kubernetes/admin.conf $HOME/
$ chown  $(id -u) $HOME/admin.conf
$ export KUBECONFIG=$HOME/admin.conf