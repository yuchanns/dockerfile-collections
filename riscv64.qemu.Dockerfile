ARG UBUNTU_VERSION=20.04

FROM ubuntu:$UBUNTU_VERSION as riscv-gdb-builder

ARG GDB_VERSION=2022.04.12

RUN sed -i "s/archive.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list && apt update
RUN DEBIAN_FRONTEND=noninteractive apt install -y autoconf automake autotools-dev curl \
  python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev git openssh-server
RUN cd /tmp && git clone --depth 1 --branch $GDB_VERSION https://github.com/riscv-collab/riscv-gnu-toolchain.git
RUN cd /tmp/riscv-gnu-toolchain && ./configure --prefix=/opt/riscv && make -j$(nproc) linux

ARG UBUNTU_VERSION=20.04

FROM ubuntu:$UBUNTU_VERSION

COPY --from=riscv-gdb-builder /opt/riscv/bin/riscv64-unknown-linux-gnu-gdb /usr/local/bin/riscv64-unknown-linux-gnu-gdb

RUN sed -i "s/archive.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list && apt update \
  && DEBIAN_FRONTEND=noninteractive apt install -y qemu-system-riscv64 build-essential tmux && apt clean
