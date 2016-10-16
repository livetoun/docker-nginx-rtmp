FROM debian
MAINTAINER Konstantin Wilms <kon@geopacket.com>

WORKDIR /home/nginx/
ENV NGINX_VER 1.9.9

RUN apt-get -y install libpcre3 libpcre3-dev libssl-dev

RUN groupadd nginx
RUN useradd -m -g nginx nginx

RUN cd /home/nginx/ && wget -q http://nginx.org/download/nginx-${NGINX_VER}.tar.gz
RUN cd /home/nginx/ && tar -xzvf nginx-${NGINX_VER}.tar.gz

# rtmp-module
RUN cd /home/nginx/nginx-${NGINX_VER} && git clone git://github.com/arut/nginx-rtmp-module.git

# nginx build
RUN cd /home/nginx/nginx-${NGINX_VER} && ./configure \
 --prefix=/usr/local \
 --add-module=nginx-rtmp-module 
 --pid-path=/var/run/nginx.pid --conf-path=/etc/nginx/nginx.conf \
 --error-log-path=/var/log/nginx/error.log \
 --http-log-path=/var/log/nginx/access.log \
 --with-http_ssl_module \
 --user=nginx && \
  make && make install
  
  
  
RUN mkdir /etc/nginx && mkdir /var/log/nginx && mkdir /home/nginx/html
RUN cp /home/nginx/nginx-${NGINX_VER}/conf/* /etc/nginx/

ADD nginx /etc/init.d/nginx
ADD nginx.conf.template /etc/nginx/nginx.conf.template
ADD appinit /usr/bin/appinit
RUN chmod 744 /usr/bin/appinit

EXPOSE 80
EXPOSE 1935

CMD ["appinit"]
