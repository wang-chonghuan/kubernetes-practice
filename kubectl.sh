#方便操作
sudo apt-get install bash-completion
vim ~/.bashrc #加入以下三行
alias k=kubectl
source <(kubectl completion bash)
source <(kubectl completion bash | sed s/kubectl/k/g)
source .bashrc

#sets the context and the namespace as a one-time action
kubectl config set-context <context-of-question> --namespace=<namespace-of-question>
kubectl config use-context <context-of-question>

alias k=kubectl
k version

#lists all available commands plus their short names
kubectl api-resources
kubectl describe pvc my-claim

#不等待强制马上杀死k对象
kubectl delete pod nginx --force

#finds all Pods with the annotation key-value pair author=John Doe plus the surrounding 10 lines
kubectl describe pods | grep -C 10 "author=John Doe"
#searches the YAML representation of all Pods for their labels including the surrounding five lines of output
kubectl get pods -o yaml | grep -C 5 labels:

kubectl create --help
kubectl explain pods.spec

#显示当前pod的日志
kubectl logs mypod
#显示上一次崩溃的pod的日志
kubectl logs mypod --previous

kubectl get nodes
gcloud compute ssh <node-name>
kubectl describe node <node-name>
kubectl describe node

#gke
#连接到集群autopilot-cluster-1
gcloud container clusters get-credentials autopilot-cluster-1 --region europe-west1 --project fiery-splice-376923

#运行一个镜像,注意 --generator=run/v1已经废弃
kubectl run kubia --image=edwinbiz/kubia --port=8080
kubectl get pods
kubectl delete pods/kubia
kubectl describe pod {pod-name}
