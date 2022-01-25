# MIT License
#
# Copyright (c) 2022 Christian Hoekstra
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

FROM amd64/debian:stretch-slim

WORKDIR /tmp
ENV IS_IN_CONTAINER 1
ENV DEBIAN_FRONTEND noninteractive
ARG GO_VERSION="1.17.6"
ARG GOREL_VERSION="v1.3.1"
ARG NFPM_VERSION="v2.11.3"
VOLUME ["/build_output"]

RUN apt update \ 
 && apt-get --no-install-recommends install -y \
 ca-certificates \
 make \
 pkg-config \
 gcc \
 bzr \
 clang \
 libprotobuf-dev \
 protobuf-compiler \
 curl \
 git \
 nano \
 yarn \
 libc6-armel-cross \
 libc6-dev-armel-cross \
 binutils-arm-linux-gnueabi \
 libncurses5-dev \
 build-essential \
 bison \
 flex \
 libssl-dev \
 bc \
 gcc-arm-linux-gnueabihf \ 
 g++-arm-linux-gnueabihf \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install GO from binary
RUN curl -fL# https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -xz -C /opt/
ENV PATH "/opt/go/bin:/root/go/bin:${PATH}"

# Install Go from source (ARMv7 binary)

# Install Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH "/root/.cargo/bin:${PATH}"
ENV RUSTFLAGS " -C linker=arm-linux-gnueabihf-gcc"
RUN rustup target add armv7-unknown-linux-gnueabihf

# Run Task
RUN go install github.com/go-task/task/v3/cmd/task@latest \
  && task --version

# Install nfpm
RUN git clone --branch=${NFPM_VERSION} --depth=1 https://github.com/goreleaser/nfpm.git \
  && cd nfpm \
  && task setup \
  && task build \
  && mkdir -p ${GOPATH}/bin \
  && mv -v ./nfpm ${GOPATH}/bin \
  && ${GOPATH}/bin/nfpm --version \
  && go clean -modcache
 
# Install goreleaser
# RUN git clone --branch=${GOREL_VERSION} --depth=1 https://github.com/goreleaser/goreleaser \
#  && cd goreleaser \
#  && go mod tidy \
#  && go build -o goreleaser . \
#  && mkdir -p ${GOPATH}/bin \
#  && mv -v ./goreleaser ${GOPATH}/bin \ 
#  && ${GOPATH}/bin/goreleaser --version \
#  && go clean -modcache

RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /root

COPY ["build_package.sh", "col_table", "influxdb2_nfpm.yml", "influxdb2-client_nfpm.yml", "."]

ENTRYPOINT ["bash","build_package.sh"]
# ENTRYPOINT ["bash"]
