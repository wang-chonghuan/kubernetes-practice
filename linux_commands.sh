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
sudo apt update
sudo apt remove runc
curl -fsSL https://get.docker.com | bash -s docker
:.../simple-node$ sudo docker build -t simple-node .
docker run --rm -p 3000:3000 simple-node
docker ps
docker stop {CONTAINER_ID}