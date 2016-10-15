FROM ubuntu
MAINTAINER Konstantin Wilms <kon@geopacket.com>

ENV LIBVPX_VER 1.5.0

RUN apt-get update

RUN apt-get -y install unzip git wget autoconf automake build-essential libass-dev libfreetype6-dev libgpac-dev \
    libtheora-dev libtool libvorbis-dev libxfixes-dev pkg-config texi2html zlib1g-dev

# yasm
RUN apt-get install yasm

# x264
RUN wget http://download.videolan.org/pub/x264/snapshots/last_x264.tar.bz2
RUN tar xjvf last_x264.tar.bz2
RUN cd /x264-snapshot* && ./configure --prefix="/ffmpeg_build" --bindir="/bin" --enable-static
RUN cd /x264-snapshot* && make && make install && make distclean

# libfdk-aac
RUN wget -O fdk-aac.zip https://github.com/mstorsjo/fdk-aac/zipball/master && unzip fdk-aac.zip
RUN cd mstorsjo-fdk-aac* && autoreconf -fiv && ./configure --prefix="/ffmpeg_build" --disable-shared
RUN cd mstorsjo-fdk-aac* && make && make install && make distclean

# libmp3lame
RUN apt-get install -y libmp3lame-dev

# libopus
RUN apt-get install -y libopus-dev

# libvpx
#RUN wget http://webm.googlecode.com/files/libvpx-v${LIBVPX_VER}.tar.bz2 && tar xjvf libvpx-v${LIBVPX_VER}.tar.bz2
RUN wget http://storage.googleapis.com/downloads.webmproject.org/releases/webm/libvpx-${LIBVPX_VER}.tar.bz2 && tar xjvf libvpx-${LIBVPX_VER}.tar.bz2

RUN cd libvpx-${LIBVPX_VER} && ./configure --prefix="/ffmpeg_build" --disable-examples
RUN cd libvpx-${LIBVPX_VER} && make && make install && make clean

# ffmpeg
RUN wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && tar xjvf ffmpeg-snapshot.tar.bz2
RUN PKG_CONFIG_PATH="/ffmpeg_build/lib/pkgconfig" && export PKG_CONFIG_PATH
RUN cd ffmpeg && ./configure --prefix="/ffmpeg_build" --extra-cflags="-I/ffmpeg_build/include" \
   --extra-ldflags="-L/ffmpeg_build/lib" --bindir="/bin" --extra-libs="-ldl" --enable-gpl \
   --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus \
   --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libx264 --enable-nonfree
RUN cd ffmpeg && make && make install && make distclean && hash -r

WORKDIR /home/nginx/
ENV NGINX_VER 1.7.1

RUN apt-get -y install libpcre3-dev libssl-dev

RUN groupadd nginx
RUN useradd -m -g nginx nginx

RUN cd /home/nginx/ && wget -q http://nginx.org/download/nginx-${NGINX_VER}.tar.gz
RUN cd /home/nginx/ && tar -xzvf nginx-${NGINX_VER}.tar.gz

# rtmp-module
RUN cd /home/nginx/nginx-${NGINX_VER} && git clone git://github.com/arut/nginx-rtmp-module.git

# nginx build
RUN cd /home/nginx/nginx-${NGINX_VER} && ./configure \
  --prefix=/usr/local \
  --add-module=nginx-rtmp-module --user=nginx && \
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
