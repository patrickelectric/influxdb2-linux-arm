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

FROM amd64/debian:buster-slim

# Specify release in format x.xx.*
# Latest point release is automatically detected
# Currently influxdb2 requires Go 1.17
ARG GO_VERSION="1.20.*"

WORKDIR /tmp
ENV IS_IN_CONTAINER 1
ENV DEBIAN_FRONTEND noninteractive

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
RUN GO_LATEST=$(git ls-remote --tags https://github.com/golang/go.git | sort -Vr -k2 | grep -Po -m 1 "go${GO_VERSION}") \
  && echo "Downloading Go release ${GO_LATEST}" \
  && curl -fL# https://golang.org/dl/${GO_LATEST}.linux-amd64.tar.gz | tar -xz -C /opt/
ENV PATH "/opt/go/bin:/root/go/bin:${PATH}"

# Install Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH "/root/.cargo/bin:${PATH}"
ENV RUSTFLAGS " -C linker=arm-linux-gnueabihf-gcc"
RUN rustup target add armv7-unknown-linux-gnueabihf

# Install nfpm
RUN go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest \
  && nfpm --version

# Clean-up
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && go clean -modcache

WORKDIR /root

COPY ["build_package.sh", "col_table", "influxdb2_nfpm.yml", "influxdb2-client_nfpm.yml", "."]
ENV CARGO_HOME /root/.cargo
COPY config.toml /root/.cargo/config.toml

ENTRYPOINT ["bash","build_package.sh"]
# ENTRYPOINT ["bash"]
