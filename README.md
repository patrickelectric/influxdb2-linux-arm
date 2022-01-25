# Influxdb2 for ARMv7 (32-bit)

[InfluxDB 2.0](https://www.influxdata.com/) includes a powerful monitoring and alerting system that's based on the same technology as Tasks and Flux. Our native UI provides a way to quickly define threshold and deadman alerts on your data, but if you need more flexibility, you can built your own custom alerting using the underlying Tasks system.


## Why this project?

* InfluxData no longer provides support for 32-bit ARM architecture as of Influxdb 2.x.
* Influxdb 1.x is significantly different from Influxdb 2.x, therefore not suitable as alternative.
* InfluxData does not provide binaries nor packages for 32-bit ARM.

## What is the goal?

* Provide pre-built DEB and RPM packages for ARM 32-bit.
* Provide a means to easily built you own packages without the need of in depth knowledge.
* Automate the built as much as possible.

## Prerequisites

* Any Linux (AMD64) distro with Docker.io installed.
* Computer or Virtual Machine running Linux with Internet access.
* Very basic Linux knowledge.

## Targeted Architecture

**ARM 32-bit**

Basically the code should run on and not limited to e.g., RaspberryPI 2 and 3 models and various Samsung Exynos 5422 Odroid boards.

* \>= ARMv7A with Hard Float also known as armhf
* CPU feature required: neon-vfpv3

> Note: Boards with 2GB or more physical memory is highly recommended.

**Not supported**

* <= ARMv6 Processors
* Processors without hard floating point capabilities

### More details

```
$ file -e elf influxd
influxd: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV)

$ readelf -h influxd
ELF Header:
  Magic:   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00
  Class:                             ELF32
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              EXEC (Executable file)
  Machine:                           ARM
  Version:                           0x1
  Entry point address:               0x260509
  Start of program headers:          52 (bytes into file)
  Start of section headers:          202678888 (bytes into file)
  Flags:                             0x5000400, Version5 EABI, hard-float ABI
  Size of this header:               52 (bytes)
  Size of program headers:           32 (bytes)
  Number of program headers:         10
  Size of section headers:           40 (bytes)
  Number of section headers:         52
  Section header string table index: 51

$ readelf -A influxd
Attribute Section: aeabi
File Attributes
  Tag_CPU_name: "7-A"
  Tag_CPU_arch: v7
  Tag_CPU_arch_profile: Application
  Tag_ARM_ISA_use: Yes
  Tag_THUMB_ISA_use: Thumb-2
  Tag_FP_arch: VFPv3-D16
  Tag_ABI_PCS_GOT_use: GOT-indirect
  Tag_ABI_PCS_wchar_t: 4
  Tag_ABI_FP_rounding: Needed
  Tag_ABI_FP_denormal: Needed
  Tag_ABI_FP_exceptions: Needed
  Tag_ABI_FP_number_model: IEEE 754
  Tag_ABI_align_needed: 8-byte
  Tag_ABI_enum_size: int
  Tag_ABI_VFP_args: VFP registers
  Tag_CPU_unaligned_access: v6
  Tag_ABI_FP_16bit_format: IEEE 754
```

## Assumptions

* Ubuntu Server 20.04 (minimal) with Docker.io installed.
* [builtx](https://docs.docker.com/builtx/working-with-builtx/) plugin for docker installed

## For the gullible and lazy

You can download the pre-built packages from the [Download](https://bitbucket.org/choekstra/influxdb2-linux-arm/downloads/) page.
Checksum files are provided. 

> Disclaimer: Although I did not manipulate the code in anyway provide by InfluxData, it is best practice not to trust sources like these. I highly recommend to built the packages yourself when able.

## built your own packages!

To built your own packages, make sure you have the prerequisites in place. Once you have setup your Linux OS with Docker.io, clone this repository by executing `git clone https://choekstra@bitbucket.org/choekstra/influxdb2-linux-arm.git`.

### built Docker image

Using [builtx](https://docs.docker.com/builtx/working-with-builtx/) is highly recommended, but not required. This image contains everything that is needed to cross-compile Influxdb2 and to built the DEB and RPM packages. Influxdb2 is built using multiple program languages e.g., GOLANG and RUSTC.

```bash
$ cd influxdb
$ ./bake_image.sh
builtx plugin is installed, continuing using builtx:
[+] builting 186.2s (15/15) FINISHED
 => [internal] load built definition from Dockerfile                                                           0.0s
 => => transferring dockerfile: 2.81kB                                                                         0.0s
 => [internal] load .dockerignore                                                                              0.0s
 => => transferring context: 2B                                                                                0.0s
 => [internal] load metadata for docker.io/amd64/debian:stretch-slim                                           1.0s
 => [ 1/10] FROM docker.io/amd64/debian:stretch-slim@sha256:a2e05027c644442099883498f6e002ea0f5cdacaa01dadaa5  0.0s
 => [internal] load built context                                                                              0.0s
 => => transferring context: 17.94kB                                                                           0.0s
 => CACHED [ 2/10] WORKDIR /tmp                                                                                0.0s
 => [ 3/10] RUN apt update  && apt-get --no-install-recommends install -y  ca-certificates  make  pkg-config  23.1s
 => [ 4/10] RUN GO_LATEST=$(git ls-remote --tags https://github.com/golang/go.git | sort -Vr -k2 | grep -Po -  7.6s
 => [ 5/10] RUN curl https://sh.rustup.rs -sSf | bash -s -- -y                                                75.2s
 => [ 6/10] RUN rustup target add armv7-unknown-linux-gnueabihf                                                3.1s
 => [ 7/10] RUN go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest   && nfpm --version                  37.8s
 => [ 8/10] RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*   && go clean -modcache                          0.4s
 => [ 9/10] WORKDIR /root                                                                                      0.0s
 => [10/10] COPY [built_package.sh, col_table, influxdb2_nfpm.yml, influxdb2-client_nfpm.yml, .]               0.0s
 => exporting to image                                                                                        37.9s
 => => exporting layers                                                                                       37.9s
 => => writing image sha256:394bec3ca626add04af85209d238502d1c7e009af60b1c196977d78fdd7c5311                   0.0s
 => => naming to docker.io/library/influxdb2builter                                                            0.0s
 
 $ docker images
 REPOSITORY         TAG       IMAGE ID       CREATED              SIZE
influxdb2builter   latest    394bec3ca626   About a minute ago   2.3GB
```

### built Influxdb2 and Client packages

Since Influxdb2 v2.0.9 the client `influx` will be maintained in a separate repository and package. Therefore this project builts a package for Influxdb and one for the client.

```bash
$ ./run_container.sh
##########################################################################
### builting influxdb2 server & influx-cli packages for armhf (ARMv7A) ###
##########################################################################

### PREPERATIONS ###

  [i] Cleaned /built_output/...
  [i] Initialized log file /built_output/influxdb2-built-20220125.log...
  [i] Using influxdb2 branch: v2.1.1...
  [i] Using influx-cli branch: v2.2.1...
  [i] Using go version: go version go1.17.6 linux/amd64...
  [i] Using cargo version: cargo 1.58.0 (f01b232bc 2022-01-19)...

### INFLUXDB2 ###

  [i] Starting influxdb2 clone using branch v2.1.1
  [✓] Succesfully cloned influxdb2 repository
  [i] Starting to tidy go modules...
  [✓] Finished tidying modules (influxdb2)
  [i] Starting generation of prerequisites...
  [✓] Generated all prerequisites
  [✓] Switched to cross compile environment
  [i] Starting to tidy go modules (cross compile)...
  [✓] Finished tidying modules (cross compile)!
  [i] Starting influxdb2 server built (influxd)
  [✓] Compiled influxdb2 server (influxd)
  [✓] built DEB package influxdb2-v2.1.1-armv7l.deb
  [✓] built RPM package influxdb2-v2.1.1-armv7l.rpm
  [✓] Create TAR archive influxdb2-v2.1.1-linux-armv7l.tar

### INFLUXDB2-CLIENT ###

  [i] Starting to tidy go modules (cross compile)...
  [✓] Finished tidying modules (influx-cli)
  [✓] Compiled influxdb2 client (influx)
  [✓] Compiled influx client (influx)
  [✓] built DEB package influxdb2-client-v2.2.1-armv7l.deb
  [✓] built RPM package influxdb2-v2.1.1-armv7l.rpm
  [✓] Create TAR archive influxdb2-client-v2.2.1-linux-armv7l.tar
  [i] All done! Below a list of all files create in /built_output on your host.

### FILES CREATED ###

  influxdb2-built-20220125.log
  influxdb2-client-v2.2.1-armv7l.deb
  influxdb2-client-v2.2.1-armv7l.deb.sha256sum
  influxdb2-client-v2.2.1-armv7l.rpm
  influxdb2-client-v2.2.1-armv7l.rpm.sha256sum
  influxdb2-client-v2.2.1-linux-armv7l.tar.gz
  influxdb2-client-v2.2.1-linux-armv7l.tar.gz.sha256sum
  influxdb2-v2.1.1-armv7l.deb
  influxdb2-v2.1.1-armv7l.deb.sha256sum
  influxdb2-v2.1.1-armv7l.rpm
  influxdb2-v2.1.1-armv7l.rpm.sha256sum
  influxdb2-v2.1.1-linux-armv7l.tar.gz
  influxdb2-v2.1.1-linux-armv7l.tar.gz.sha256sum
Files can be found in: /home/<your home>/influxdb2/built_output

$ cd /home/<your home>/influxdb2/built_output
```

## Finally install the packages

For detailed information on how to install Influxdb 2.x and perform post-install setup, read the official [documentation](https://docs.influxdata.com/influxdb/v2.1/install/).

**DEB**

Install or upgrade:

```bash
$ sudo dpkg -i influxdb2-client-v2.2.1-armv7l.deb
$ sudo dpkg -i influxdb2-v2.1.1-armv7l.deb
```

**RPM**

Install or upgrade:

```bash
$ sudo yum localinstall influxdb2-client-v2.2.1-armv7l.rpm
$ sudo yum localinstall influxdb2-v2.1.1-armv7l.rpm
```

## For who that want to know more

The image and built has been fully automated and provides the following features:

**built Features**

* built DEB packages
* built RPM packages
* built TAR archive containing binaries only
* Create checksum files for each package/archive
* Create log of most activities for info/debug purposes

**Image built features**

* Detect automatically latest point release of GOLANG to be added to image
* Prepare Linux, Go and CARGO for cross compile to ARM 32-bit

**Container Features**

* Provide a nice status GUI instead of gibberish
* Fully automated cross compile built of binaries
* Fully automated DEB, RPM and TAR archive built
* Automatically determine latest Inlfuxdb2 and Influx-cli release

## Acknowledgements

- Inlfuxdb2 server developed by InfluxData [Git Repository](https://github.com/influxdata/influxdb)
- Inlfuxdb2 client developed by InfluxData [Git Repository](https://github.com/influxdata/influx-cli)
- Borrowed COL_TABLE code from the [PiHole](https://github.com/pi-hole/pi-hole) project