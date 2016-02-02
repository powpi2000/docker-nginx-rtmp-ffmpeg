FROM ubuntu:14.04
MAINTAINER eric <powpi2000@gmail.com>

ENV NGINX_VERSION 1.8.1
ENV NGINX_DISTRO_VERSION 1+trusty0
ENV NGINX_DISTRO_FULL_VERSION $NGINX_VERSION-$NGINX_DISTRO_VERSION
ENV NGINX_RTMP_MODULE_VERSION master

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y
RUN apt-get install software-properties-common dpkg-dev curl  git -y
RUN apt-get install python-software-properties -y
##insall ffmpeg
RUN add-apt-repository ppa:mc3man/trusty-media -y 
RUN	apt-get update 
RUN	apt-get dist-upgrade -y  
RUN	apt-get install ffmpeg -y
RUN ffmpeg -formats  


###install nginx with rtmp,secure_link
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C

WORKDIR /usr/src
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

EXPOSE 80 1935

CMD ["nginx", "-c", "/etc/nginx/nginx.conf", "-g", "daemon off;"]