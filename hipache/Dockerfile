FROM 		ubuntu:14.04

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys B0DE9C5DEBF486359EB255B03B0153D0383F073D
RUN echo "deb http://ppa.launchpad.net/tsuru/ppa/ubuntu trusty main"  > /etc/apt/sources.list.d/tsuru.list
RUN apt-get update

RUN apt-get install -y patch
RUN apt-get install -y node-hipache

EXPOSE      8080

ADD ./hipache.init.sh /etc/init.d/hipache
RUN chmod +x /etc/init.d/hipache

