#!/usr/bin/env bash
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

# Check if script is executed within container
if [ -z ${IS_IN_CONTAINER+x} ]; then
    echo "ERROR: This script expect to be run inside a docker container"
    exit 1
fi

# Start with clean console
clear

echo "##########################################################################"
echo "### Building influxdb2 server & influx-cli packages for armhf (ARMv7A) ###"
echo "##########################################################################"
echo
echo "### PREPERATIONS ###"
echo

# Include required col table
source $(pwd)/col_table

# Helper to create tar.gz archive
# $1 = target folder
# $2 = filename of archive
# $3 = influxd <or> influx
create_archive () {
    tar -cf $1/$2 LICENSE README.md >/dev/null
    tar -C bin/linux/ -rf $1/$2 $3 >/dev/null
    gzip -9 $1/$2 >/dev/null
    pushd $1 >/dev/null
    sha256sum $2.gz > $2.gz.sha256sum
    popd >/dev/null
}

# Sets environment suitable for cross compiling for armhf (ARMv7l)
set_cross () {
    go env -w CC=arm-linux-gnueabihf-gcc
    go env -w CXX=arm-linux-gnueabihf-g++
    go env -w GOARCH=arm
    go env -w GOARM=7
    go env -w CGO_ENABLED=1
    export LD_LIBRARY_PATH=/usr/arm-linux-gnueabihf/lib
    ln -s /usr/arm-linux-gnueabihf/lib/ld-linux-armhf.so.3 /lib/ld-linux-armhf.so.3
}

rustup target add armv7-unknown-linux-gnueabihf
rustup component add rust-src rust-std --toolchain armv7-unknown-linux-gnueabihf

# Set date format
DATE_TIME=`date +"%b %d, %Y %H:%M:%S %p %Z"`
LOG_DATE=`date +"%Y%m%d"`

# Set GIT Sources
GIT_INFLUXDB2="influxdata/influxdb"
GIT_INFLUXCLI="influxdata/influx-cli"

# Influxdb2 nfpm file
INFLUXDB2_NFPM="influxdb2_nfpm.yml"
INFLUXCLI_NFPM="influxdb2-client_nfpm.yml"

# Package name templates
INFLUXDB2_DEB="influxdb2-${INFLUXDB2_BRANCH}-armv7l.deb"
INFLUXDB2_RPM="influxdb2-${INFLUXDB2_BRANCH}-armv7l.rpm"
INFLUXDB2_TAR="influxdb2-${INFLUXDB2_BRANCH}-linux-armv7l.tar"
INFLUXCLI_DEB="influxdb2-client-${INFLUXCLI_BRANCH}-armv7l.deb"
INFLUXCLI_RPM="influxdb2-client-${INFLUXCLI_BRANCH}-armv7l.rpm"
INFLUXCLI_TAR="influxdb2-client-${INFLUXCLI_BRANCH}-linux-armv7l.tar"

# Set Variables
BUILD_OUTPUT=/build_output
LOG_DIR=${BUILD_OUTPUT}
GO_VERSION=`go version`
CARGO_VERSION=`cargo --version`

# Clean host folder
rm -vrf ${BUILD_OUTPUT}/* 2>&1 | tee -a ${LOG_FILE} >/dev/null
echo -e "  ${INFO} Cleaned ${BUILD_OUTPUT}/..."

# Setup working folder
WORKINGDIR="$(go env GOPATH)/src/github.com"
if [ ! -d ${WORKINGDIR} ]; then
    mkdir -p ${WORKINGDIR}
fi

# Create and set logfile
LOG_FILE="${LOG_DIR}/influxdb2-build-${LOG_DATE}.log"
if [ -f ${LOG_FILE} ]; then
    rm -f ${LOG_FILE}
    touch ${LOG_FILE}
fi
echo -e "  ${INFO} Initialized log file ${LOG_FILE}..."

# Test if INFLUXDB2_BRANCH is set
if [ -z ${INFLUXDB2_BRANCH+x} ]; then
    echo "${DATE_TIME} - ERROR: INFLUXDB2_BRANCH not defined, please specify influxdb version" 2>&1 | tee -a ${LOG_FILE} >/dev/null
    echo -e "  ${CROSS} Error message: influxdb2 branch not defined! Please make sure to set INFLUXDB2_BRANCH."
    exit 1
else
    echo -e "  ${INFO} Using influxdb2 branch: ${INFLUXDB2_BRANCH}..."
    echo "Influxdb2 git branch: ${INFLUXDB2_BRANCH}" 2>&1 | tee -a ${LOG_FILE} >/dev/null
fi

# Test if INFLUXCLI_BRANCH is set
if [ -z ${INFLUXCLI_BRANCH+x} ]; then
    echo "${DATE_TIME} - ERROR: INFLUXCLI_BRANCH not defined, please specify influxdb version" 2>&1 | tee -a ${LOG_FILE} >/dev/null
    echo -e "  ${CROSS} Error message: influx-cli branch not defined! Please make sure to set INFLUXCLI_BRANCH."
    exit 1
else
    echo -e "  ${INFO} Using influx-cli branch: ${INFLUXCLI_BRANCH}..."
    echo "Influx-cli branch: ${INFLUXCLI_BRANCH}" 2>&1 | tee -a ${LOG_FILE} >/dev/null
fi

# Log GOLANG version
echo ${GO_VERSION} 2>&1 | tee -a ${LOG_FILE} >/dev/null
echo -e "  ${INFO} Using go version: ${GO_VERSION}..."

# Log CARGO version
echo ${CARGO_VERSION} 2>&1 | tee -a ${LOG_FILE} >/dev/null
echo -e "  ${INFO} Using cargo version: ${CARGO_VERSION}..."

# Move into working directory
cd ${WORKINGDIR}
echo ${pwd} 2>&1 | tee -a ${LOG_FILE} >/dev/null

# Log go env
go env 2>&1 | tee -a ${LOG_FILE} >/dev/null

# Download influxdb2 repository
echo
echo "### INFLUXDB2 ###"
echo
echo -e "  ${INFO} Starting influxdb2 clone using branch ${INFLUXDB2_BRANCH}"
git clone --branch ${INFLUXDB2_BRANCH} --depth 1 https://github.com/${GIT_INFLUXDB2}.git 2>&1 | tee -a ${LOG_FILE} >/dev/null
if [ $? -ne 0 ]; then
    echo "${DATE_TIME} - ERROR: Unable to clone influxdb repository" 2>&1 | tee -a ${LOG_FILE} >/dev/null
    echo -e "  ${CROSS} Error message: Unable to clone influxdb2 repository branch ${INFLUXDB2_BRANCH}"
    exit 1
else
    echo -e "  ${TICK} Succesfully cloned influxdb2 repository"
    cd influxdb
    mkdir .cargo
    cp /root/.cargo/config.toml .cargo/config.toml
    go env -w GO111MODULE=on
    go env 2>&1 | tee -a ${LOG_FILE} >/dev/null
    # Remove task generate from task all:
    sed -i '/all: generate $(CMDS)/{s//all: $(CMDS)/g;h};${x;/./{x;q0};x;q1}' *[Mm]akefile 2>&1 | tee -a ${LOG_FILE} >/dev/null
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "${DATE_TIME} - ERROR: Unable to change task all: in Makefile" 2>&1 | tee -a ${LOG_FILE} >/dev/null
        echo -e "  ${CROSS} Error message: Failed to change task all: in Makefile"
        exit 1
    else
        echo -e "  ${TICK} Succesfully changed task all: in Makefile"
    fi
    
    # Prevent go pkg-config beeing build on the fly
    sed -i '/PKG_CONFIG:=.*/{s//PKG_CONFIG:=${GOPATH}\/bin\/pkg-config/g;h};${x;/./{x;q0};x;q1}' *[Mm]akefile 2>&1 | tee -a ${LOG_FILE} >/dev/null
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "${DATE_TIME} - ERROR: Unable to set variable PKG_CONFIG in Makefile" 2>&1 | tee -a ${LOG_FILE} >/dev/null
        echo -e "  ${CROSS} Error message: Failed to set PKG_CONFIG variable in Makefile"
        exit 1
    else
        echo -e "  ${TICK} Succesfully set PKG_VARIABLE in Makefile"
    fi

    # Make tidy
    echo -e "  ${INFO} Starting to tidy go modules..."
    make tidy 2>&1 | tee -a ${LOG_FILE} >/dev/null
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "${DATE_TIME} - ERROR: Unable to make tidy" 2>&1 | tee -a ${LOG_FILE} >/dev/null
        echo -e "  ${CROSS} Error message: Failed to tidy go modules!"
        exit 1
    else
        echo -e "  ${TICK} Finished tidying modules (influxdb2)"
    fi

    # Build and install go pkg-config
    go install github.com/influxdata/pkg-config@latest 2>&1 | tee -a ${LOG_FILE} >/dev/null
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "${DATE_TIME} - ERROR: Failed to built and install Go pkg-config" 2>&1 | tee -a ${LOG_FILE} >/dev/null
        echo -e "  ${CROSS} Error message: Failed to built and install Go pkg-config!"
        exit 1
    else
        echo -e "  ${TICK} Built and installed Go pkg-config"
    fi

    # Generate influxdb2 make prerequisites
    echo -e "  ${INFO} Starting generation of prerequisites..."
    make generate 2>&1 | tee -a ${LOG_FILE} >/dev/null
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "${DATE_TIME} - ERROR: Unable to make generate" 2>&1 | tee -a ${LOG_FILE} >/dev/null
        echo -e "  ${CROSS} Error message: Failed to generate prerequisites!"
        exit 1
    else
        # Setup environment for cross compiling for ARMv7l (armhf)
        echo -e "  ${TICK} Generated all prerequisites"
        set_cross
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            echo "${DATE_TIME} - ERROR: Unable to set environment for cross compiling" 2>&1 | tee -a ${LOG_FILE} >/dev/null
            echo -e "  ${CROSS} Error message: Unable to to set cross compile env!" 
            exit 1
        else
            echo -e "  ${TICK} Switched to cross compile environment"
        fi
        
        # Log critical variables for debugging
        echo ${LD_LIBRARY_PATH} 2>&1 | tee -a ${LOG_FILE} >/dev/null
        ls /lib/ld-linux-armhf.so.3 2>&1 | tee -a ${LOG_FILE} >/dev/null
        go env 2>&1 | tee -a ${LOG_FILE} >/dev/null
    fi
fi

# Compile influxdb2 and create packages on success
echo -e "  ${INFO} Starting influxdb2 server build (influxd)"
make 2>&1 | tee -a ${LOG_FILE} >/dev/null
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "${DATE_TIME} - ERROR: Unable to compile influxdb2" 2>&1 | tee -a ${LOG_FILE} >/dev/null
    echo -e "  ${CROSS} Error message: Failed to compile influxdb2 server (influxd)"
    exit 1
else
    echo -e "  ${TICK} Compiled influxdb2 server (influxd)"
    # Build DEB Package
    nfpm package -f $(pwd)/../../../../${INFLUXDB2_NFPM} -p deb -t ${BUILD_OUTPUT}/${INFLUXDB2_DEB} 2>&1 | tee -a ${LOG_FILE} >/dev/null
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "${DATE_TIME} - ERROR: Unable to build deb package" 2>&1 | tee -a ${LOG_FILE} >/dev/null
        echo -e "  ${CROSS} Error message: Failed to build DEB package ${INFLUXDB2_DEB}"
        exit 1
    else
        pushd ${BUILD_OUTPUT} >/dev/null
        sha256sum ${INFLUXDB2_DEB} > ${INFLUXDB2_DEB}.sha256sum 2>&1 | tee -a ${LOG_FILE} >/dev/null
        popd >/dev/null
        echo -e "  ${TICK} Build DEB package ${INFLUXDB2_DEB}"
    fi

    # Build RPM Package
    nfpm package -f $(pwd)/../../../../${INFLUXDB2_NFPM} -p rpm -t ${BUILD_OUTPUT}/${INFLUXDB2_RPM} 2>&1 | tee -a ${LOG_FILE} >/dev/null
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "${DATE_TIME} - ERROR: Unable to build rpm package" 2>&1 | tee -a ${LOG_FILE} >/dev/null
        echo -e "  ${CROSS} Error message: Failed to build RPM package ${INFLUXDB2_RPM}"
        exit 1
    else
        pushd ${BUILD_OUTPUT} >/dev/null
        sha256sum ${INFLUXDB2_RPM} > ${INFLUXDB2_RPM}.sha256sum 2>&1 | tee -a ${LOG_FILE} >/dev/null
        popd >/dev/null
        echo -e "  ${TICK} Build RPM package ${INFLUXDB2_RPM}"
    fi

    # Build tar.gz
    create_archive ${BUILD_OUTPUT} ${INFLUXDB2_TAR} influxd 2>&1 | tee -a ${LOG_FILE} >/dev/null
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "${DATE_TIME} - ERROR: Unable to build tar package" 2>&1 | tee -a ${LOG_FILE} >/dev/null
        echo -e "  ${CROSS} Error message: Failed to create TAR archive ${INFLUXDB2_TAR}"
        exit 1
    else
        echo -e "  ${TICK} Create TAR archive ${INFLUXDB2_TAR}"
        cd ${WORKINGDIR}
    fi
fi

# Download influxdb-cli repository
echo
echo "### INFLUXDB2-CLIENT ###"
echo
git clone --branch=${INFLUXCLI_BRANCH} --depth=1 https://github.com/${GIT_INFLUXCLI}.git 2>&1 | tee -a ${LOG_FILE} >/dev/null
if [ $? -ne 0 ]; then
    echo "${DATE_TIME} - ERROR: Unable to clone influx-cli repository" 2>&1 | tee -a ${LOG_FILE} >/dev/null
    exit 1
else
    cd influx-cli
    go clean -modcache 2>&1 | tee -a ${LOG_FILE} >/dev/null
    echo -e "  ${INFO} Starting to tidy go modules (cross compile)..."
    go mod tidy 2>&1 | tee -a ${LOG_FILE} >/dev/null
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "${DATE_TIME} - ERROR: Unable to make tidy" 2>&1 | tee -a ${LOG_FILE} >/dev/null
        cho -e "  ${CROSS} Error message: Failed to tidy go modules (cross compile)!"
        exit 1
    else
        echo -e "  ${TICK} Finished tidying modules (influx-cli)"
    fi
fi

# Compile influx-cli
echo -e "  ${TICK} Compiled influxdb2 client (influx)"
make 2>&1 | tee -a ${LOG_FILE} >/dev/null
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "${DATE_TIME} - ERROR: Unable to compile influx-cli" 2>&1 | tee -a ${LOG_FILE} >/dev/null
    echo -e "  ${CROSS} Error message: Failed to compile influxdb2 client (influx)"
    exit 1
else
    echo -e "  ${TICK} Compiled influx client (influx)"
    # Build DEB Package
    nfpm package -f $(pwd)/../../../../${INFLUXCLI_NFPM} -p deb -t ${BUILD_OUTPUT}/${INFLUXCLI_DEB} 2>&1 | tee -a ${LOG_FILE} >/dev/null
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "${DATE_TIME} - ERROR: Unable to build deb package" 2>&1 | tee -a ${LOG_FILE} >/dev/null
        echo -e "  ${CROSS} Error message: Failed to build DEB package ${INFLUXCLI_DEB}"
        exit 1
    else
        pushd ${BUILD_OUTPUT} >/dev/null
        sha256sum ${INFLUXCLI_DEB} > ${INFLUXCLI_DEB}.sha256sum 2>&1 | tee -a ${LOG_FILE} >/dev/null
        popd >/dev/null
        echo -e "  ${TICK} Build DEB package ${INFLUXCLI_DEB}"
    fi

    # Build RPM Package
    nfpm package -f $(pwd)/../../../../${INFLUXCLI_NFPM} -p rpm -t ${BUILD_OUTPUT}/${INFLUXCLI_RPM} 2>&1 | tee -a ${LOG_FILE} >/dev/null
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "${DATE_TIME} - ERROR: Unable to build rpm package" 2>&1 | tee -a ${LOG_FILE} >/dev/null
        echo -e "  ${CROSS} Error message: Failed to build RPM package ${INFLUXCLI_RPM}"
        exit 1
    else
        pushd ${BUILD_OUTPUT} >/dev/null
        sha256sum ${INFLUXCLI_RPM} > ${INFLUXCLI_RPM}.sha256sum 2>&1 | tee -a ${LOG_FILE} >/dev/null
        popd >/dev/null
        echo -e "  ${TICK} Build RPM package ${INFLUXDB2_RPM}"
    fi

    # Build tar.gz
    create_archive ${BUILD_OUTPUT} ${INFLUXCLI_TAR} influx 2>&1 | tee -a ${LOG_FILE} >/dev/null
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "${DATE_TIME} - ERROR: Unable to build tar package" 2>&1 | tee -a ${LOG_FILE} >/dev/null
        echo -e "  ${CROSS} Error message: Failed to create TAR archive ${INFLUXCLI_TAR}"
        exit 1
    else
        echo -e "  ${TICK} Create TAR archive ${INFLUXCLI_TAR}"
    fi
fi

# Nicely exit script
echo -e "  ${INFO} All done! Below a list of all files create in ${BUILD_OUTPUT} on your host."
echo
echo "### FILES CREATED ###"
echo
ls -1 ${BUILD_OUTPUT}  | awk '{print "  "$0}'
exit 0
