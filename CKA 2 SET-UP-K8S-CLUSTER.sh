######## 1 准备
su root
adduser w sudo
sudo apt-get install vim
sudo apt-get install net-tools
sudo apt-get install bash-completion
vim ~/.bashrc #加入以下三行
alias k=kubectl
source <(kubectl completion bash)
source <(kubectl completion bash | sed s/kubectl/k/g)
source .bashrc

######## 2 docker
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker w && newgrp docker
docker ps
docker run hello-world

######## 3 安装k8s
#swap 如果启用了交换，Kubernetes调度程序可能无法准确确定节点上的可用资源，因为它可能无法区分实际的内存和交换空间。
cat /proc/swaps #如果swap已经关闭,该命令的输出应该是空的
sudo swapon --show #显示swap分区,如果已关闭,也是空返回
sudo swapoff -a #临时关闭swap,重启后还会开启
sudo vim /etc/fstab #永久关闭swap 注释掉这一行/dev/<partition-name> none swap sw 0 0
sudo reboot
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
KUBE_VERSION=1.23.0 #指定版本号
export KUBE_VERSION=1.23.0 #~/.bashrc 固定
sudo apt-get update
sudo apt-get install -y kubelet=${KUBE_VERSION}-00 kubeadm=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00 kubernetes-cni=0.8.7-00
sudo apt-mark hold kubelet kubeadm kubectl
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
#将桥接的IPv4流量传递到iptables的链
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
sudo cp /etc/sysctl.d/k8s.conf /etc/sysctl.d/kubernetes.conf
# 可能会报无法访问8080,不确定是否要执行重启kubelete,等一会就能访问了,此时节点状态时notready或者ready
# 关掉终端再打开就好了
sudo systemctl start kubelet
kubectl get nodes

######## 4 初始化主节点
sudo kubeadm config images pull
sudo kubeadm reset -f
sudo kubeadm init --kubernetes-version=${KUBE_VERSION} --pod-network-cidr=192.168.0.0/16
#必须把密钥等配置放到本用户目录下,否则报The connection to the server localhost:8080 was refused
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sudo systemctl restart kubelet
sudo kubectl get nodes
#这里出现6443无法访问的问题, 6443是apiserver访问kubelet的端口,说明kubelet挂了,这个莫名其妙的错误卡了整整一天
#排查后,原因是磁盘空间不足,把虚拟机的磁盘设置为60G就解决了,当然还可能有其他原因,最好能查到日志

######## 5 设置主节点CNI
#此时复制这台虚拟机,复制出2台,三台的网卡都设置成两张,分别是NAT和桥接模式,后者允许所有连接
#这两条命令创建CNI,不行,节点不会ready
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml
#改用这条好了
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
kubectl get pods -n kube-system 
#删除主节点的污点,让pod可以调度到主节点
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl get no -o wide

######## 6 配置网络

#复制虚拟机时的方法
pod连接不上nslookup kubernetes.default.svc.cluster.local
原因是复制虚拟机副本时, 没有生成了新的MAC地址, 正确的方法应该是"包含所有网卡的MAC地址"
我是怎么解决的? 我用ifconfig查看了IP地址, 和配置说明书上的一样, 这时我想到可能是复制完副本的启动顺序有问题.
我想重新复制, 重新复制时发现MAC的复制策略有问题, 原来是上次选错了

#私有IP地址范围包括几个地址块，包括192.168.0.0/16、10.0.0.0/8和172.16.0.0/12
#vbox-ubuntu22的桥接网卡的掩码是inet 10.54.138.191  netmask 255.255.224.0,相当于其CIDR记号是/19
#在主节点固定桥接网卡的IP
sudo vim /etc/netplan/00-installer-config.yaml
network:
    ethernets:
        enp0s3:
            dhcp4: true
        enp0s8:
            dhcp4: no
            addresses: [10.54.138.191/19]
    version: 2
EOF
#在工作节点1固定桥接网卡的IP
sudo vim /etc/netplan/00-installer-config.yaml
network:
    ethernets:
        enp0s3:
            dhcp4: true
        enp0s8:
            dhcp4: no
            addresses: [10.54.138.226/19]
    version: 2
EOF
#启用配置
sudo netplan apply
#关闭SELinux 否则 kubelet 挂载目录时可能报错Permission denied,应该永久关闭,但是本机好像没有selinux
setenforce 0  # 临时
#修改主机名,两台机器都加
sudo vim /etc/hosts
10.54.138.191 kw-master
10.54.138.226 kw-node1
EOF
#分别修改两个节点的名字
sudo vim /etc/hosts #改为kw-master和kw-node1
#分别执行生效新主机名
sudo systemctl restart systemd-hostnamed
sudo sysctl --system
#分别添加ssh配置文件
vim ~/.ssh/config
Host kw-master
    HostName 10.54.138.191
    User w
    Port 22
    IdentityFile /home/w/.ssh/id_rsa

Host kw-node1
    HostName 10.54.138.226
    User w
    Port 22
    IdentityFile /home/w/.ssh/id_rsa
EOF
#分别安装ssh
sudo apt-get install openssh-server
ls /etc/init.d/ | grep ssh #来验证远程虚拟机上的SSH服务的名称
sudo service ssh start
systemctl status sshd #验证sshd是否active
#复制密钥到对方机器
#如果你有三个虚拟机想要互相SSH，你需要使用ssh-copy-id命令将SSH公钥复制到每个虚拟机。
#这将使你能够在所有三个虚拟机之间建立无密码的SSH连接。
ssh-copy-id -i /home/w/.ssh/id_rsa.pub w@kw-node1 #在主节点执行
ssh-copy-id -i /home/w/.ssh/id_rsa.pub w@kw-master #在工作节点执行
#至此,两台机器可以通过ssh连接,不需要密码

######## 7 把工作节点加入主节点
kubeadm token create --print-join-command # 显示token
#>>>> kubeadm join 10.0.2.15:6443 --token van8m0.dc29rs6ey5t4mh3w --discovery-token-ca-cert-hash sha256:9406966c6b34bd526ac4ada6e637069a51db1cb51bc630339c9766cf5be6d505
#报错了,因为k8s跑在了网卡1上,网卡1是用来和宿主机通信的网卡,这个IP是和宿主机通信专用的,cg说过
#所以要销毁k8s重新以新参数初始化
#--apiserver-advertise-address选项用来指定你想用于Kubernetes API服务器的网络接口的IP地址。这个IP地址应该是分配给你的节点的IP地址之一。
sudo kubeadm init --kubernetes-version=${KUBE_VERSION} --apiserver-advertise-address=10.54.138.191 --pod-network-cidr=192.169.0.0/16
#别忘了重新cp配置文件
#在主节点获取工作节点的加入指令
kubeadm token create --print-join-command
#工作节点不应该执行kubeadm init命令。kubeadm init命令用于初始化一个新的Kubernetes控制平面，它应该只在集群的主节点上运行。
#如果工作节点执行过kubeadm init,必须rest,并删除~/.kube
#然后在工作节点执行
sudo kubeadm join 10.54.138.191:6443 --token oofqdt.o9kx4u4ppaucf6kn --discovery-token-ca-cert-hash sha256:216e1290dcd10665b70d40f6dc6c3edcdff6214a4161d8dca47049a61952b735
#至此成功,在主节点执行k get nodes -o wide
NAME        STATUS   ROLES                  AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
kw-master   Ready    control-plane,master   11m     v1.23.0   10.54.138.191   <none>        Ubuntu 22.04.1 LTS   5.15.0-60-generic   docker://23.0.1
kw-node1    Ready    <none>                 3m19s   v1.23.0   10.54.138.226   <none>        Ubuntu 22.04.1 LTS   5.15.0-60-generic   docker://23.0.1

