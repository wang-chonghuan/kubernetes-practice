#run an app on the cluster called helloPackt using busybox
kubectl run helloPackt --image=busybox

jq # using jq for JSON parsing

kubectl config current-context # check out the context
kubectl config use-context my-current-cluster-name # check out the context
kubectl config get-contexts # a list of Kubernetes clusters

kubeadm version
kubectl version

sudo apt update
apt-cache madison kubeadm | grep 23 #check out the latest versions
#升级kubeadm
sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm=1.23.3-00 && sudo apt-mark hold kubeadm
kubectl -n kube-system get cm kubeadm-config -o yaml
#检查当前集群是否可以升级,以及可以升级到的版本
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.23.3
#封锁工作节点,抽取里面的pods,准备升级工作节点,之后节点状态变成Ready,SchedulingDisabled
kubectl drain kw-node1 --ignore-daemonsets
#升级kubelet kubectl
sudo apt-mark unhold kubelet kubectl && sudo apt-get update && sudo apt-get install -y kubelet=1.23.3-00 kubectl=1.23.3-00 && sudo apt-mark hold kubelet kubectl
kubectl version --short
#此时client的版本也变成1.23.3了
#Restart the kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
#解除封锁工作节点
kubectl uncordon kw-node1

#接下来升级一个工作节点
sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm=1.23.3-00 && sudo apt-mark hold kubeadm