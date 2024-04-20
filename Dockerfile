FROM node:16-alpine3.17 AS builder

RUN apk add --update-cache --no-cache alpine-sdk autoconf automake pkgconfig cmake pcsc-lite-dev
# RUN apt-get update && apt-get install -y build-essential autoconf automake pkg-config cmake libpcsclite-dev wget unzip pcsc-tools

# b25
# https://github.com/stz2012/libarib25/tree/v0.2.5-20220902
# use alpine-sdk pkgconfig cmake pcsc-lite-dev
RUN cd / && \
  wget -O - https://github.com/stz2012/libarib25/archive/refs/tags/v0.2.5-20220902.zip | unzip - && \
  cd libarib25-0.2.5-20220902 && \
  cmake . && \
  make && \
  make install
# RUN cd / && mkdir libarib25 && wget -O - https://github.com/stz2012/libarib25/archive/refs/tags/v0.2.5-20220902.tar.gz | tar zxvf - -C libarib25 --strip-components 1 && cd libarib25 && cmake . && make && make install
# -- Install configuration: "Release"
# -- Installing: /usr/local/bin/b25
# -- Set runtime path of "/usr/local/bin/b25" to ""
# -- Installing: /usr/local/lib/libarib25.a
# -- Installing: /usr/local/lib/libarib25.so.0.2.5
# -- Installing: /usr/local/lib/libarib25.so.0
# -- Installing: /usr/local/lib/libarib25.so
# -- Installing: /usr/local/include/arib25/arib_std_b25.h
# -- Installing: /usr/local/include/arib25/b_cas_card.h
# -- Installing: /usr/local/include/arib25/multi2.h
# -- Installing: /usr/local/include/arib25/ts_section_parser.h
# -- Installing: /usr/local/include/arib25/portable.h
# -- Installing: /usr/local/include/arib25/arib25_api.h
# -- Installing: /usr/local/lib/pkgconfig/libarib25.pc

# recpt1
# https://github.com/stz2012/recpt1
# use alpine-sdk autoconf automake
RUN cd / && \
  wget -O - https://github.com/stz2012/recpt1/archive/refs/heads/master.zip | unzip - && \
  cd recpt1-master/recpt1 && \
  sh autogen.sh && \
  ./configure --enable-b25 && \
  make && \
  make install
# RUN cd / && mkdir recpt1 && wget -O - https://github.com/stz2012/recpt1/archive/refs/heads/master.tar.gz | tar zxvf - -C recpt1 --strip-components 1 && cd recpt1/recpt1 && sh autogen.sh && ./configure --enable-b25 && make
# install -m 755 recpt1 recpt1ctl checksignal /usr/local/bin

# mirakurun
RUN cd / && \
  export DOCKER=YES && \
  wget -O - https://github.com/Chinachu/Mirakurun/archive/refs/heads/release/3.8.zip | unzip - && \
  cd Mirakurun-release-3.8 && \
  npm ci && \
  npm run build && \
  npm install -g --omit=dev --unsafe-perm

# 必要なファイルのみ1ファイルに
# Only the required files are to 1 file
RUN mkdir /app && \
  cp -r /usr/local/lib/node_modules/mirakurun/bin* /app && \
  cp -r /usr/local/lib/node_modules/mirakurun/lib* /app && \
  cp -r /usr/local/lib/node_modules/mirakurun/*.json /app && \
  cp -r /usr/local/lib/node_modules/mirakurun/*.yml /app && \
  tar czvPf lib.tar.gz \
    /usr/local/bin/b25 \
    /usr/local/include/arib25 \
    /usr/local/lib/libarib25* \
    /usr/local/lib/pkgconfig/libarib25.pc \
    /usr/local/bin/recpt1* \
    /usr/local/bin/checksignal \
    /app


FROM node:16-alpine3.17

# ビルド済みのバイナリをコピー
# Copy the builded binary
COPY --from=builder /lib.tar.gz /

# カードリーダーライブラリを追加 & バイナリを展開 & 依存ライブラリのみインストール
# Add card reader library & Expand binary & Install only dependent libraries
RUN echo '@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories && \
  apk add --update-cache --no-cache ccid pcsc-tools@testing && \
  tar zxvf /lib.tar.gz && \
  cd /app && \
  DOCKER=YES npm ci --omit=dev && \
  npm cache clean --force

ENV DOCKER=YES \
    NODE_ENV=production \
    SERVER_CONFIG_PATH='/config/server.yml' \
    TUNERS_CONFIG_PATH='/config/tuners.yml' \
    CHANNELS_CONFIG_PATH='/config/channels.yml' \
    SERVICES_DB_PATH='/data/services.json' \
    PROGRAMS_DB_PATH='/data/programs.json' \
    LOGO_DATA_DIR_PATH='/data/logo-data'

WORKDIR /app
COPY ./scripts .
CMD ./start.sh

HEALTHCHECK --interval=2m --timeout=30s --start-period=10s --retries=3 \
  CMD ./healthcheck.sh

EXPOSE 40772 9229

VOLUME /config
VOLUME /data
