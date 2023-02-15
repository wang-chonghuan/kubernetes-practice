kubectl api-versions
kubectl run frontend --image=nginx --restart=Never --port=80


# produce a manifest file without actually creating an object
#这里的Never会导致node重启后,这个服务是completed的状态
kubectl run frontend --image=nginx --restart=Never --port=80 -o yaml --dry-run=client > pod.yaml
vim pod.yaml
kubectl create -f pod.yaml
kubectl describe pod frontend
kubectl delete pod frontend
kubectl delete -f pod.yaml
export KUBE_EDITOR=vim
kubectl edit pod frontend
kubectl replace -f pod.yaml

#build jar
#用spring initializr初始化一个spring boot, JDK版本号设置为11, 在项目目录下执行
./mvnw clean package
java -jar ./target/<JAR包名>
vim Dockerfile
BOF
FROM openjdk:17-ea-slim-buster #需要在https://hub.docker.com/ 查询
WORKDIR /app
COPY target/java-hello-world-0.0.1.jar java-hello-world.jar
ENTRYPOINT ["java", "-jar", "/app/java-hello-world.jar"]
EXPOSE 8080
EOF
docker build -t java-hello-world:1.0.0 .
docker images
docker run -d -p 8080:8080 java-hello-world:1.0.0
docker logs <container-name-or-id> #查看docker日志
curl localhost:8080 #无法访问该端口,是因为该容器不是daemon而是一个job
#该8080端口是本机的,不是apiserver使用的8080

#ubuntu22 安装jdk
sudo apt update && sudo apt upgrade -y
apt-cache search openjdk
sudo apt-get install openjdk-17-jre
sudo apt-get install openjdk-17-jdk
java --version
sudo apt-get remove openjdk-17-jre openjdk-17-jdk --purge
sudo update-alternatives --config java #显示安装路径
sudo vim /etc/profile
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
PATH=$PATH:$HOME/bin:$JAVA_HOME/bin
export JAVA_HOME
export JRE_HOME
export PATH
EOF

#创建pod其中有一个容器,并运行该容器,创建时间很长,可能要几分钟
kubectl run hazelcast --image=hazelcast/hazelcast --restart=Never --port=5701 --env="DNS_DOMAIN=cluster" --labels="app=hazelcast,env=prod"
vim pod.yaml
BOF
apiVersion: v1
kind: Pod
metadata:
  name: hazelcast
  labels:
    app: hazelcast
    env: prod
spec:
  containers:
  - env:
    - name: DNS_DOMAIN
      value: cluster
    image: hazelcast/hazelcast
    name: hazelcast
    ports:
    - containerPort: 5701
  restartPolicy: Never
EOF
kubectl create -f pod.yaml
kubectl get pods hazelcast
kubectl describe pods hazelcast | grep Image
#把pod的日志下载到终端查看
kubectl logs hazelcast
kubectl logs hazelcast -f
kubectl logs hazelcast -p #查看前一个容器崩溃前的日志
#Error from server (BadRequest): previous terminated container "hazelcast" in pod "hazelcast" not found

#在容器里打开一个shell, 注意不是在pod里打开
kubectl exec -it hazelcast -- /bin/sh
kubectl exec -it <pod-name> -c <container-name> -- /bin/sh
kubectl exec hazelcast -- env
#删除
kubectl delete pod hazelcast
#立即删除(注意此处不要用-f,-f是指定yaml文件用的)
kubectl delete pod <pod-name> --grace-period=0 --force
#按照创造pod的文件删除
kubectl delete -f pod.yaml

#指定容器的运行命令, 先用这个命令生成一个yaml
kubectl run mypod --image=busybox -o yaml --dry-run=client --restart=Never > pod-busybox.yaml -- /bin/sh -c "while true; do date; sleep 10; done"

#显示命名空间
kubectl get namespaces
BOF
default           Active   43h
kube-node-lease   Active   43h
kube-public       Active   43h
kube-system       Active   43h
EOF
kubectl create namespace code-red
kubectl get namespace code-red
vim create-ns.yaml
BOF
apiVersion: v1
kind: Namespace
metadata:
  name: code-red
EOF
#在命名空间中创建pod,以及查询,不指定就是用default命名空间
kubectl run pod --image=nginx --restart=Never -n code-red
kubectl get pods -n code-red
#删除一个命名空间,会删除该命名空间下的所有对象
kubectl delete namespace code-red
#学完了k8s的pods和ns,我觉得k8s甚至像一个编程平台,你实时在这个平台上对你的系统的组成元素(可运维的粒度的元素)进行实时的增删改查,实时看到他们投入运维,实时与它们交互,以前的程序是静止的,现在的程序是活着的,以前的程序是组件化的,你可以从maven或者npm下到你需要的组件,组装进你的代码里.现在的程序是微服务化的,你从dockerhub上找到你需要的镜像,直接投入你的k8s平台使用!!!以前看smalltalk创始人alan key说,他希望的面向对象程序,是由一组互相对话的对象组成,如今他这个设想在k8s上实现了.实时创建对象,实时运行.但是有些镜像还需要你自己构建,因为太大太复杂,还需进行组件装配写一个新的程序再容器化.比如,我现在写代码,我可以直接在k8s里写一段go的程序,需要组件的就用组件,不需要组件的用第三方镜像,然后打包,投入运维,这是开发的新范式.application-oriented development,从面向对象开发, 到面向应用开发, 直接对微服务进行编程!所以说YAML工程师就是面向应用开发的工程师.一种快捷方式是,在pod.yaml的command和arg字段里写shell程序,代表一个pod的功能.如果该字段里能写更复杂的程序呢?做到在一个yaml里完成所有的pod代码!
