#!/bin/bash
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

IMAGE_NAME="influxdb2builder"

# Functions
get_release() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

# Create output folder
BUILD_OUTPUT="${HOME}/influxdb2/build_output"
if [ ! -d ${BUILD_OUTPUT} ]; then
    mkdir -p ${BUILD_OUTPUT}
fi

# Run Container and start build
docker run \
 --privileged \
 --tmpfs /tmp:exec \
 --net=host \
 --rm \
 -e GOROOT="/opt/go" \
 -e GOPATH="/root/go" \
 -e INFLUXDB2_BRANCH=`get_release influxdata/influxdb` \
 -e INFLUXCLI_BRANCH=`get_release influxdata/influx-cli` \
 -e TZ=Europe/Amsterdam \
 -v ${BUILD_OUTPUT}:/build_output \
 -ti ${IMAGE_NAME}
