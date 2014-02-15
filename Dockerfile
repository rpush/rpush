# cd ~/rpush
# git fetch; git reset --hard origin/master
# sudo docker build -t rpush:latest .
# sudo docker run -i -t -v /home/vagrant/rpush:/mnt/rpush:ro rpush:latest bash -l

FROM ubuntu:saucy
MAINTAINER Ian Leitch

RUN apt-get -y update
RUN sudo apt-get -y upgrade
RUN apt-get -y -q install build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison pkg-config libpq5 libpq-dev build-essential git-core curl libcurl4-gnutls-dev python-software-properties libffi-dev libgdbm-dev mysql-server mysql-client libmysqlclient-dev postgresql gawk

RUN curl -L https://get.rvm.io | bash -s stable
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /etc/bash.bashrc
RUN /bin/bash -l -c rvm requirements

ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN /bin/bash -l -c 'rvm install 2.0.0'
RUN /bin/bash -l -c 'rvm use 2.0.0 --default'
RUN /bin/bash -l -c 'gem install --no-ri --no-rdoc bundler rails mysql2 rake rdoc'
