# node
su root
adduser walt sudo
sudo apt-get install curl
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
nvm --version
nvm ls-remote
nvm install v10.24.1
nvm ls
nvm alias default 10.24.1
node --version
npm --version
npm init
npm install --save express

# docker
sudo apt update
sudo apt remove runc
curl -fsSL https://get.docker.com | bash -s docker
:.../simple-node$ sudo docker build -t simple-node .
docker run --rm -p 3000:3000 simple-node
docker ps
docker stop {CONTAINER_ID}

# kuard
git clone https://github.com/kubernetes-up-and-running/kuard
cd kuard
docker build -t kuard .
docker run --rm -p 8080:8080 kuard
docker tag kuard gcr.io/kuar-demo/kuard-amd64:blue
docker push gcr.io/kuar-demo/kuard-amd64:blue #Unauthorized access.
docker run -d --name kuard --publish 8080:8080 gcr.io/kuar-demo/kuard-amd64:blue
docker stop kuard
docker rm kuard # 每次用完必须停止且删除,否则不能重新启动该名字的容器,只有守护进程启动的容器才可以如此操作,否则就是ctrl+c
docker run -d --name kuard --publish 8080:8080 --memory 200m --memory-swap 1G --cpu-shares 1024 gcr.io/kuar-demo/kuard-amd64:blue
docker ps -a
docker image ls
docker rmi gcr.io/kuar-demo/kuard-amd64:blue
docker rmi <image-id> # 必须先stop和rm容器,才能rmi\
docker system prune

#golang
apt-cache policy golang
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt update
sudo apt install golang-go
go version
chmod 777 kuard

#aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
which aws
ls -l /usr/local/bin/aws

#k8s on aws
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
eksctl create cluster #只有在aws cloudshell上才可以,在本地会报Error: checking AWS STS access – cannot get role ARN for current session
kubectl version --short
kubectl get componentstatuses
kubectl get nodes
kubectl describe nodes ip-192-168-50-46.eu-west-1.compute.internal

