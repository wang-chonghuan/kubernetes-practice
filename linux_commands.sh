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
git pull
cd kuard
docker build -t kuard .
docker run --rm -p 8080:8080 kuard
docker tag kuard gcr.io/kuar-demo/kuard-amd64:blue
docker push gcr.io/kuar-demo/kuard-amd64:blue #Unauthorized access.
docker run -d --name kuard --publish 8080:8080 gcr.io/kuar-demo/kuard-amd64:blue # deploy kuard using the following Docker command
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
kubectl get daemonSets --namespace=kube-system kube-proxy #在每个node上部署一个kube-proxy容器的实例
kubectl get deployments --namespace=kube-system coredns #用deployments运行一个coredns,也可以自动变为多个,replicas

#kubectl
cat $HOME/.kube/config | more
kubectl config set-context my-context --namespace=mystuff #创建一个新context,默认用户空间名字不同
kubectl config use-context my-context #使用新的上下文
kubectl get pods
kubectl get services
kubectl get nodes
kubectl get pods my-pod -o jsonpath --template={.status.podIP} #this command will extract and print the IP address of the specified Pod
kubectl get pods,services
kubectl describe <resource-name> <obj-name>
kubectl explain pods
kubectl apply -f obj.yaml --dry-run
kubectl apply -f obj.yaml
kubectl edit <resource-name> <obj-name>
kubectl apply -f myobj.yaml view-last-applied #will show you the last state that was applied to the object
kubectl delete -f obj.yaml
kubectl delete <resource-name> <obj-name>
kubectl label pods bar color=red #add the color=red label to a Pod named bar
kubectl label pods bar color=red --overwrite
kubectl label pods bar color-
kubectl logs <pod-name> #see the logs for a running container
kubectl logs <pod-name> #-c for choosing one container in this pod; -f without exiting
kubectl exec -it <pod-name> -- bash # provide you with an interactive shell inside the running container
kubectl attach -it <pod-name> #allow you to send input to the running process which is set up to read from standard input
kubectl cp <pod-name>:</path/to/remote/file> </path/to/local/file> #copy files to and from a container
kubectl port-forward <pod-name> 8080:80 # opens connection that forwards traffic from local on port 8080 to the container on port 80
kubectl get events --watch #stream events, -A
kubectl top nodes # cpu and memory
kubectl top pods --all-namespaces
kubectl cordon # for a node
kubectl drain
kubectl uncordon
echo "source <(kubectl completion bash)" >> ${HOME}/.bashrc
kubectl help <command-name>

#pods
kubectl run kuard --image=gcr.io/kuar-demo/kuard-amd64:blue
kubectl get pods
kubectl delete pods/kuard
kubectl apply -f kuard-pod.yaml #必须先delete上一个才能重新启动
kubectl get pods -o wide | -o json | -o yaml | --v=10
kubectl describe pods kuard
kubectl delete pods/kuard
kubectl delete -f kuard-pod.yaml
kubectl logs kuard -f
kubectl exec kuard -- date #execute commands in the context of the container
kubectl exec -it kuard -- ash #an interactive session

#gcp
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-416.0.0-linux-arm.tar.gz
tar -xf google-cloud-cli-416.0.0-linux-arm.tar.gz
./google-cloud-sdk/install.sh
./google-cloud-sdk/bin/gcloud init

#labels
##create the alpaca-prod deployment and set the ver, app, and env labels
##弃用了
kubectl run alpaca-prod --image=gcr.io/kuar-demo/kuard-amd64:blue --replicas=2 --labels="ver=1,app=alpaca,env=prod"
##用以下替代
kubectl create deployment alpaca-prod --image gcr.io/kuar-demo/kuard-amd64:blue --replicas 2
kubectl label deployment alpaca-prod ver=1 appname=alpaca env=prod --overwrite
kubectl create deployment alpaca-test --image gcr.io/kuar-demo/kuard-amd64:green --replicas 1
kubectl label deployment alpaca-test ver=2 app=alpaca env=test --overwrite

kubectl get deployments --show-labels #列出所有deployments
kubectl label deployment alpaca-test appname- #删除标签
kubectl label --overwrite deployment alpaca-test app=alpaca #修改标签
##再创建一组
kubectl create deployment bandicoot-prod --image gcr.io/kuar-demo/kuard-amd64:green --replicas 2
kubectl label deployment bandicoot-prod ver=2 app=bandicoot env=prod --overwrite
kubectl create deployment bandicoot-staging --image gcr.io/kuar-demo/kuard-amd64:green --replicas 1
kubectl label deployment bandicoot-staging ver=2 app=bandicoot env=staging --overwrite
#只显示符合某些条件的pods或deployments
kubectl label deployments alpaca-test "canary=true"
kubectl get deployments -L canary
kubectl get pods --selector="ver=2"
#and
kubectl get deployments --selector="env=prod,ver=2"
#删除所有部署
kubectl delete deployments --all

####service discovery
#创建部署指定端口
kubectl create deployment alpaca-prod --image gcr.io/kuar-demo/kuard-amd64:blue --port=8080
#扩容
kubectl scale deployment alpaca-prod --replicas 3
#创建service object
kubectl expose deployment alpaca-prod

kubectl get services -o wide
#port-forward
ALPACA_POD=$(kubectl get pods -l app=alpaca-prod -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward $ALPACA_POD 48858:8080