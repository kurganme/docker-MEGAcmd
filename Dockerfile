FROM debian:9 as builder

RUN \
  apt-get update &&\
  apt-get install --yes \
    autoconf build-essential libtool g++ libcrypto++-dev libz-dev \
    libsqlite3-dev libssl-dev libcurl4-gnutls-dev libreadline-dev \
    libpcre++-dev libsodium-dev libc-ares-dev libfreeimage-dev \
    libavcodec-dev libavutil-dev libavformat-dev libswscale-dev \
    libmediainfo-dev libzen-dev git

RUN \
  cd &&\
  git clone https://github.com/meganz/MEGAcmd.git &&\
  cd MEGAcmd &&\
  git submodule update --init --recursive

RUN \
  cd && cd MEGAcmd &&\
  sh autogen.sh &&\
  ./configure &&\
  make

RUN \
  cd &&\
  mkdir -p ./out/mega.d &&\
  install -s \
    MEGAcmd/mega-exec MEGAcmd/mega-cmd MEGAcmd/.libs/mega-cmd-server \
    ./out/mega.d/ &&\
  LD_LIBRARY_PATH="$(readlink -f ./MEGAcmd/sdk/src/.libs)" \
  ldd MEGAcmd/mega-exec MEGAcmd/mega-cmd MEGAcmd/.libs/mega-cmd-server |\
  sed -rn 's|^\s+(.* => )?/(.*) \(0x[0-9a-f]+\)$|/\2|p' |\
  sort -u |\
  xargs -i_ install -s _ ./out/mega.d/

COPY mega-exec mega-cmd mega-cmd-server /root/out/

FROM alpine:3.9

COPY --from=builder /root/out/ /usr/local/bin

# docker build --force-rm --tag mega-cmd .
# docker run --rm -ti mega-cmd
# docker run --rm mega-cmd tar c -C /usr/local/bin mega-cmd mega-exec mega.d | tar x -C ~/bin
