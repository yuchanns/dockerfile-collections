ARG UBUNTU_VERSION=22.04

FROM ubuntu:$UBUNTU_VERSION as protoc-builder

ARG PROTOC_VERSION=3.5.1

RUN apt update && apt install gcc g++ make autoconf aptitude libtool wget -y
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOC_VERSION/protobuf-all-$PROTOC_VERSION.tar.gz
RUN tar -zxvf protobuf-all-$PROTOC_VERSION.tar.gz
RUN cd protobuf-$PROTOC_VERSION && ./configure && make -j$(nproc) && make install
RUN ldconfig && protoc --version 

ARG UBUNTU_VERSION=22.04

FROM ubuntu:$UBUNTU_VERSION as nvim-builder

ARG NVIM_VERSION=0.7.0

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install make cmake g++ pkg-config libtool libtool-bin gettext unzip wget ninja-build -y
RUN wget https://github.com/neovim/neovim/archive/refs/tags/v$NVIM_VERSION.tar.gz
RUN tar -zxvf v$NVIM_VERSION.tar.gz
RUN cd neovim-$NVIM_VERSION && make CMAKE_BUILD_TYPE=Release && make install

ARG UBUNTU_VERSION=22.04

FROM ubuntu:$UBUNTU_VERSION

COPY --from=protoc-builder /usr/local/lib /usr/local/lib
COPY --from=protoc-builder /usr/local/bin/protoc /usr/local/bin/
COPY --from=protoc-builder /usr/local/include /usr/local/include/

COPY --from=nvim-builder /usr/local/bin/nvim /usr/local/bin/nvim
COPY --from=nvim-builder /usr/local/share/nvim /usr/local/share/nvim

RUN sed -i "s/archive.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list \
&& apt update && apt install git gcc g++ fzy ripgrep locales make language-pack-zh-hans rsync curl zsh -y \
&& DEBIAN_FRONTEND="noninteractive" TZ="Asia/Shanghai" apt install -y tzdata \
&& chmod +x /usr/local/bin/protoc && ldconfig && /usr/local/bin/protoc --version \
&& chown root /usr/local/bin/nvim && chown -R root /usr/local/share/nvim && chmod +x /usr/local/bin/nvim \
&& ln -s /usr/local/bin/nvim /usr/local/bin/vim \
&& apt clean && rm -rf /var/lib/apt/lists/*
