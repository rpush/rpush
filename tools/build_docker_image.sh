set -v
vagrant up

scp -r -P 2222 -i /Users/ian/.vagrant.d/insecure_private_key Dockerfile vagrant@127.0.0.1:~

vagrant ssh -- 'rm -rf gems'
rm -rf gems
mkdir -p gems

for gem in railties rails activerecord actionpack activesupport activemodel actionmailer rake rack
do
  cp vendor/cache/$gem-*.gem gems/
done

scp -r -P 2222 -i /Users/ian/.vagrant.d/insecure_private_key gems vagrant@127.0.0.1:~
rm -rf gems

vagrant ssh -- 'set -v; sudo docker build -t rpush:latest .'
