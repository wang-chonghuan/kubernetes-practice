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

#golang
apt-cache policy golang
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt update
sudo apt install golang-go
go version
chmod 777 kuard

