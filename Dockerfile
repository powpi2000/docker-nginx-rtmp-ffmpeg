FROM ubuntu:14.04
MAINTAINER eric <powpi2000@gmail.com>

ENV FFMPEG_VERSION 2.8.6
ENV NGINX_VERSION 1.8.1
#ENV NGINX_VERSION 1.4.6
ENV NGINX_DISTRO_VERSION 1+trusty0
#ENV NGINX_DISTRO_VERSION 1ubuntu3.3
ENV NGINX_DISTRO_FULL_VERSION $NGINX_VERSION-$NGINX_DISTRO_VERSION
ENV NGINX_RTMP_MODULE_VERSION master

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y
RUN apt-get install software-properties-common dpkg-dev curl yasm pkg-config git -y
RUN apt-get install python-software-properties -y

WORKDIR /usr/src
RUN git clone git://git.videolan.org/x264.git
RUN cd  /usr/src/x264 && ./configure --enable-static --enable-shared && make && make install && ldconfig

WORKDIR /usr/src
##insall ffmpeg
RUN curl https://www.ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.gz | tar -xzC /usr/src/

RUN cd ffmpeg-$FFMPEG_VERSION && ./configure --enable-gpl --enable-libx264 && make && make install

#RUN add-apt-repository ppa:mc3man/trusty-media -y 

#RUN	apt-get update 
#RUN	apt-get dist-upgrade  --fix-missing -y  
#RUN	apt-get install ffmpeg -y

RUN ffmpeg -formats   

RUN apt-get update -qq && apt-get install -y python python-pip python-dev
WORKDIR /usr/src

###install nginx with rtmp,secure_link
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C
RUN	apt-get update 

RUN echo 'deb http://ppa.launchpad.net/nginx/stable/ubuntu trusty main' >> /etc/apt/sources.list && \
    echo 'deb-src http://ppa.launchpad.net/nginx/stable/ubuntu trusty main' >> /etc/apt/sources.list && \
    apt-get update && apt-get source nginx=$NGINX_VERSION && apt-get build-dep -y nginx=$NGINX_VERSION
RUN ls -al /usr/src

RUN curl -sSL https://github.com/arut/nginx-rtmp-module/archive/${NGINX_RTMP_MODULE_VERSION}.tar.gz | tar -xzC /usr/src/nginx-${NGINX_VERSION}/ && \
    sed -ri '/^common_configure_flags := \\$/ a\	    		--add-module=/usr/src/nginx-$(NGINX_VERSION)/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} \\' /usr/src/nginx-$NGINX_VERSION/debian/rules && \
    sed -ri '/^common_configure_flags := \\$/ a\    			--with-http_secure_link_module \\' /usr/src/nginx-$NGINX_VERSION/debian/rules 

RUN cd /usr/src/nginx-$NGINX_VERSION && dpkg-buildpackage -b 
RUN ls -al /usr/src
RUN dpkg --install /usr/src/nginx-common_${NGINX_DISTRO_FULL_VERSION}_all.deb /usr/src/nginx-full_${NGINX_DISTRO_FULL_VERSION}_amd64.deb
RUN rm -rf /usr/src/*
RUN pip install request
RUN mkdir /tmp/history
RUN chown www-data /tmp/history

EXPOSE 1935

CMD ["nginx", "-c", "/etc/nginx/nginx.conf", "-g", "daemon off;"]
