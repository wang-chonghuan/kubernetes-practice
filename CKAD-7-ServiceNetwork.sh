#创建一个service,ip类型是clusterip,名字是nginx-service,以及端口映射
kubectl create service clusterip nginx-service --tcp=80:80
#直接创建一个pod，然后暴露一个端口作为服务
kubectl run nginx --image=nginx --restart=Never --port=80 --expose
w@kw-master:~$ k get service
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
nginx           ClusterIP   10.106.66.148    <none>        80/TCP    6s
nginx-service   ClusterIP   10.108.101.248   <none>        80/TCP    31m
w@kw-master:~$ k get pods
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          8s
#创建一个部署
kubectl create deployment my-deploy --image=nginx:1.14.2
#把部署暴露出一个服务，这个服务的名字和部署的名字一样，都是my-deploy
kubectl expose deployment my-deploy --port=80 --target-port=80
#用yaml定义service
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx-service #选择app名为nginx-service的pod还是depl?
  ports:
  - port: 80
    targetPort: 80
EOF
#查看TYPE CLUSTER-IP EXTERNAL-IP PORT(S)
kubectl get services
#因为该service指向了deployment，所有有两个端点
w@kw-master:~/ckad/c7-service-network$ k describe service my-deploy 
Name:              my-deploy
Namespace:         ckad4
Labels:            app=my-deploy
Annotations:       <none>
Selector:          app=my-deploy
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.106.247.194
IPs:               10.106.247.194
Port:              <unset>  80/TCP
TargetPort:        80/TCP
Endpoints:         10.32.0.5:80,10.44.0.1:80
Session Affinity:  None
Events:            <none>
EOF

#开两个pod,让它们可以互相通信
kubectl run nginx --image=nginx --restart=Never --port=80 --expose

NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
service/nginx ClusterIP 10.96.225.204 <none> 80/TCP 26s

kubectl run busybox --image=busybox --restart=Never -it -- /bin/sh
#进入第二个pod
\# wget -O- 10.96.225.204:80

#代理命令可以从本地主机建立到Kubernetes API服务器的直接连接
$ kubectl proxy --port=9999
Starting to serve on 127.0.0.1:9999
#可以通过访问localhost:9999来访问k8sapi,从而访问到这个只对内部开放的service
curl -L localhost:9999/api/v1/namespaces/default/services/nginx/proxy

#把访问服务的方式改为NodePort
kubectl patch service nginx -p '{"spec":{"type":"NodePort"}}'
#查看服务的端口
$ k get service nginx
NAME    TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx   NodePort   10.97.160.96   <none>        80:32340/TCP   26m
#查看节点的IP
$ k describe node kw-master | grep InternalIP
  InternalIP:  10.54.138.191
#访问该服务，从该集群的任何节点上都可以
$ curl 10.54.138.191:32340

#用一个NetworkPolicy让进入某pod的流量只能来自于某pod
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow
spec:
  podSelector:
    matchLabels:
      app: payment-processor
      role: api
  ingress:
  - from:
    - podSelector:
        matchLables:
          app: coffeeshop
EOF

#创建一个Pod，有标签，暴露80端口
kubectl run payment-processor --image=nginx --restart=Never -l app=payment-processor,role=api --port 80
$ k get pods -o wide
NAME                READY   STATUS    RESTARTS   AGE   IP          NODE       NOMINATED NODE   READINESS GATES
payment-processor   1/1     Running   0          36s   10.44.0.1   kw-node1   <none>           <none>

#创建网络策略
kubectl create -f networkpolicy-api-allow.yaml
k get networkpolicies.networking.k8s.io

#用另一个Pod去连接pod-pay的IP和端口,连不上
$ kubectl run grocery-store --rm -it --image=busybox --restart=Never -l app=grocery-store,role=backend -- /bin/sh
\# wget --spider --timeout=1 10.44.0.1
Connecting to 10.44.0.1 (10.44.0.1:80)
wget: download timed out
#修改上面的标签app=coffeeshop就可以连了，注意，改pod名没用


#默认网络策略，禁止任何进出流量
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF


#只允许frontend访问backend的8080
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: port-allow
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080