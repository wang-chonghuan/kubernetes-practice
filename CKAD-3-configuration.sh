#创建ConfigMap的四种方法
kubectl create configmap db-config --from-literal=db=staging #字面值
kubectl create configmap db-config --from-env-file=config.env #kv环境变量文件
kubectl create configmap db-config --from-file=config.txt #单文件
kubectl create configmap db-config --from-file=app-config #目录
#创建configmap.yaml
vim configmap-backend-config.yaml #用yaml定义configmap, 是literal values, 包含了两对, 用k create
BOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
data:
  database_url: jdbc:postgresql://localhost/test
  user: fred
EOF
#用yaml创建configmap, 也可以用apply
kubectl create -f configmap-backend-config.yaml
vim pod-configured-pod.yaml
BOF
apiVersion: v1
kind: Pod
metadata:
  name: configured-pod
spec:
  containers:
  - image: nginx:1.19.0
    name: app
    envFrom:
    - configMapRef:
        name: backend-config
EOF
#声明一个pod,其中的容器引用configmap
vim pod-configured-pod.yaml
BOF
apiVersion: v1
kind: Pod
metadata:
  name: configured-pod
spec:
  containers:
  - image: nginx:1.19.0
    name: app
    envFrom:
    - configMapRef:
        name: backend-config
EOF
#注入环境变量后, 查看容器里的环境变量值
kubectl exec configured-pod -- env
#环境变量的key应该是大写加下划线,如果不遵守该命名约定,可以用如下方法修改其key,但是要删掉pod重新apply
vim pod-configured-pod-modify.yaml
BOF
apiVersion: v1
kind: Pod
metadata:
  name: configured-pod
spec:
  containers:
  - image: nginx:1.19.0
    name: app
    env:
    - name: DATABASE_URL
      valueFrom:
        configMapKeyRef:
          name: backend-config
          key: database_url
    - name: USERNAME
      valueFrom:
        configMapKeyRef:
          name: backend-config
          key: user
EOF
#从volumn加载configmap给pod
vim pod-configured-pod-volumn.yaml
BOF
apiVersion: v1
kind: Pod
metadata:
  name: configured-pod
spec:
  containers:
  - name: app
    image: nginx:1.19.0
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: backend-config
EOF
#创建secrets, generic from 值和文件
kubectl create secret generic db-creds --from-literal=pwd=s3cre! #字面值
kubectl create secret generic db-creds --from-env-file=secret.env #包含环境变量的文件
kubectl create secret generic ssh-key --from-file=id_rsa=~/.ssh/id_rsa #SSH key file
#yaml创建secrets时要自己加密值
echo -n 's3cre!' | base64
#定义一个secret yaml,注意类型是Opaque
BOF
apiVersion: v1
kind: Secret
metadata:
  name: db-creds
type: Opaque
data:
  pwd: czNjcmUh
EOF
#定义一个secret,通过挂载volumn实现
vim pod-configured-pod-secret-volumn.yaml
BOF
apiVersion: v1
kind: Pod
metadata:
  name: configured-pod
spec:
  containers:
  - image: nginx:1.19.0
    name: app
    volumeMounts:
    - name: secret-volume
      mountPath: /var/app
      readOnly: true
  volumes:
    - name: secret-volume
      secret:
        secretName: ssh-key
EOF

#命名空间
#先创建命名空间
kubectl create namespace team-awesome
#显示当前命名空间
k config view | grep namespace
#设置修改当前命名空间(也就是修改默认命名空间)
kubectl config set-context --current --namespace=team-awesome

#Resource Boundaries
#创建quota
kubectl get namespace
vim 
apiVersion: v1

kind: ResourceQuota
vim awesome-quota.yaml
BOF
metadata:
  name: awesome-quota
spec:
  hard:
    pods: 2
    requests.cpu: "1"
    requests.memory: 1024m
    limits.cpu: "4"
    limits.memory: 4096m
EOF
#为namespace创建资源配额
kubectl create -f awesome-quota.yaml --namespace=team-awesome
#删除资源配额
k delete quota awesome-quota -n default
#查看quota
k get quota -n default
#描述某namespace的资源配额
k desc quota
kubectl describe resourcequota awesome-quota --namespace=team-awesome
#在有quota的命名空间中定义pod必须定义资源限制
vim pod-for-quota.yaml
BOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - image: nginx:1.18.0
    name: nginx
    resources:
      resources:
        requests:
          cpu: "0.5"
          memory: "512Mi"
        limits:
          cpu: "1"
          memory: "1024Mi"
EOF
kubectl create -f nginx-pod.yaml --namespace=team-awesome
#想再创建一个,不行,因为metadata.name必须不同,否则是修改原有Pod,必须用新名字

#Service Account
#显示所有可用的sa
kubectl get serviceaccounts
#查看sa存储令牌的secret
kubectl get serviceaccount default -o yaml | grep -B 2 -A 1 secrets
#显示secret的内容
kubectl get secret default-token-bf8rh -o yaml
#每一个pod中的spec都能看到它的sa
k get pod nginx -o yaml | grep serviceAccountName -A 2 -B 2
#创建sa
kubectl create serviceaccount custom
#使用sa,修改配置文件或在创建pod时用参数
kubectl run nginx --image=nginx --restart=Never --serviceaccount=custom
#运行时修改是更好的方法
#需要有必要的权限来更新pod运行的命名空间中的pod
kubectl patch pod my-pod -p '{"spec": {"serviceAccountName": "new-serviceaccount"}}'

