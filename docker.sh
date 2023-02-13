########docker

#本地或者远程拉一个busybox运行
docker run busybox echo "Hello world"
#根据Dockerfile构建image
docker build -t kubia .
# 显示本地所有images
docker images
#run your image,-d必须加在kubia前面,否则不会detached,而是作为运行参数
docker run --name kubia-container -p 8080:8080 -d kubia
docker stop kubia
docker rm kubia # 每次用完必须停止且删除,否则不能重新启动该名字的容器,只有守护进程启动的容器才可以如此操作,否则就是ctrl+c
#显示停止的容器,必须加-a,然后才可以remove
docker ps -a
#显示正在运行的容器
docker ps
#详细信息
docker inspect kubia-container
#在容器内执行shell
docker exec -it kubia-container bash
#显示容器中的进程
ps aux
#从宿主机上看容器
ps aux | grep app.js
#停止容器,要等30秒
docker stop kubia-container
docker rm kubia-container
#重新给一个image打tag,不是改名,只是复制了一个新的
docker tag kubia edwinbiz/kubia
#要推送要先登录
docker login
#必须带用户名推送
docker push edwinbiz/kubia
docker pull