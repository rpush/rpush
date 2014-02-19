set -v
vagrant up
scp -r -P 2222 -i /Users/ian/.vagrant.d/insecure_private_key Dockerfile vagrant@127.0.0.1:~
vagrant ssh -- 'set -v; sudo docker build -t rpush:latest .'
