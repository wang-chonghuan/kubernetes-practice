########minikube

#安装minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start
#查看处理器架构
uname -p
#卸载docker
sudo apt-get autoremove docker docker-ce docker-engine docker.io containerd runc
dpkg -l | grep docker
dpkg -l | grep ^rc|awk '{print $2}'|sudo xargs dpkg -P
sudo apt-get autoremove docker-ce-*
rm -rf /etc/systemd/docker.service.d
sudo rm -rf /var/lib/docker
#安装docker
curl -fsSL https://get.docker.com | bash -s docker
#但是docker daemon需要sudo才能访问,minikube报错,此时需要把当前用户加入docker组里,就不用sudo了,minikube就有访问权限了
sudo usermod -aG docker walt && newgrp docker
#安装kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client --output=yaml 
#验证集群是否工作,显示集群信息
kubectl cluster-info
#登录进minikube虚拟机
minikube ssh
exit

#
minikube start --memory 8192 --cpus 4
kubectl get node # 同nodes
minikube stop
minikube config set memory 8192
minikube config set cpus 4
minikube start
minikube config --help
minikube delete --all #deletes all local Kubernetes clusters and all profiles