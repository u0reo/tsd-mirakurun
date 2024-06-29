# https://github.com/Chinachu/Mirakurun/blob/8997c9c9ba261f357fa92e442d5e769d65efa3b9/README.md
FROM node:16-alpine3.18 AS builder

RUN apk add --update-cache --no-cache alpine-sdk autoconf automake pkgconfig cmake pcsc-lite-dev && \
  apk add --update-cache --no-cache --repository edge pcsc-lite-dev
# RUN apt-get update && apt-get install -y build-essential autoconf automake pkg-config cmake libpcsclite-dev wget unzip pcsc-tools

# b25
# https://github.com/tsukumijima/libaribb25
# use alpine-sdk pkgconfig cmake pcsc-lite-dev
RUN cd / && \
  wget -O - https://github.com/tsukumijima/libaribb25/archive/refs/tags/v0.2.9.zip | unzip - && \
  cd libaribb25-0.2.9 && \
  cmake . && \
  make && \
  make install
# -- Install configuration: "Release"
# -- Installing: /usr/local/bin/b1
# -- Set runtime path of "/usr/local/bin/b1" to ""
# -- Installing: /usr/local/bin/arib-b1-stream-test
# -- Set runtime path of "/usr/local/bin/arib-b1-stream-test" to ""
# -- Installing: /usr/local/lib/libaribb1.a
# -- Installing: /usr/local/lib/libaribb1.so.0.2.9
# -- Installing: /usr/local/lib/libaribb1.so.0
# -- Installing: /usr/local/lib/libaribb1.so
# -- Installing: /usr/local/include/aribb1
# -- Installing: /usr/local/include/aribb1/arib_std_b25.h
# -- Installing: /usr/local/include/aribb1/b_cas_card.h
# -- Installing: /usr/local/include/aribb1/multi2.h
# -- Installing: /usr/local/include/aribb1/ts_section_parser.h
# -- Installing: /usr/local/include/aribb1/portable.h
# -- Installing: /usr/local/lib/pkgconfig/libaribb1.pc
# -- Installing: /usr/local/lib/libarib1.so
# -- Installing: /usr/local/include/arib1
# -- Running: ldconfig
# CMake Warning at cmake/PostInstall.cmake:5 (message):
#   ldconfig failed
# -- Installing: /usr/local/bin/b25
# -- Set runtime path of "/usr/local/bin/b25" to ""
# -- Installing: /usr/local/bin/arib-b25-stream-test
# -- Set runtime path of "/usr/local/bin/arib-b25-stream-test" to ""
# -- Installing: /usr/local/lib/libaribb25.a
# -- Installing: /usr/local/lib/libaribb25.so.0.2.9
# -- Installing: /usr/local/lib/libaribb25.so.0
# -- Installing: /usr/local/lib/libaribb25.so
# -- Installing: /usr/local/include/aribb25
# -- Installing: /usr/local/include/aribb25/arib_std_b25.h
# -- Installing: /usr/local/include/aribb25/b_cas_card.h
# -- Installing: /usr/local/include/aribb25/multi2.h
# -- Installing: /usr/local/include/aribb25/ts_section_parser.h
# -- Installing: /usr/local/include/aribb25/portable.h
# -- Installing: /usr/local/lib/pkgconfig/libaribb25.pc
# -- Installing: /usr/local/lib/libarib25.so
# -- Installing: /usr/local/include/arib25
# -- Running: ldconfig
# CMake Warning at cmake/PostInstall.cmake:5 (message):
#   ldconfig failed

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
# install -m 755 recpt1 recpt1ctl checksignal /usr/local/bin

# mirakurun
# https://github.com/Chinachu/Mirakurun
RUN cd / && \
  export DOCKER=YES && \
  wget -O - https://github.com/Chinachu/Mirakurun/archive/refs/heads/release/3.8.zip | unzip - && \
  cd Mirakurun-release-3.8 && \
  npm ci && \
  npm run build && \
  npm install -g --omit=dev --unsafe-perm

# 必要なファイルのみ1ファイルに
# Only the required files are to 1 file
RUN cd / && \
  mkdir /app && \
  cp -r /usr/local/lib/node_modules/mirakurun/bin* /app && \
  cp -r /usr/local/lib/node_modules/mirakurun/lib* /app && \
  cp -r /usr/local/lib/node_modules/mirakurun/*.json /app && \
  cp -r /usr/local/lib/node_modules/mirakurun/*.yml /app && \
  tar czvPf /lib.tar.gz \
    /usr/local/bin/b1 \
    /usr/local/bin/b25 \
    /usr/local/bin/arib* \
    /usr/local/include/arib* \
    /usr/local/lib/libarib* \
    /usr/local/lib/pkgconfig/libarib* \
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
