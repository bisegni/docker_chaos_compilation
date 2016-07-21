FROM ubuntu:14.04

MAINTAINER Claudio Bisegni "Claudio.Bisegni@lnf.infn.it"

#installa package needed by chaos compilation process
RUN apt-get clean && \
    apt-get update
RUN apt-get install -y \
    librtmp0 \
    python-httplib2 \
    cmake \
    git \
    python \
    wget \
    autoconf \
    automake \
    libtool \
    doxygen \
    scons \
    ruby \
    curl \
    gcc \
    g++-4.8-arm-linux-gnueabihf \
    gcc-4.8-arm-linux-gnueabihf \
    build-essential \
    bc \
    cppcheck

#downlaod crosstool neede for embedded devices
#RUN curl -SL http://opensource.lnf.infn.it/binary/chaos/tools/chaos-cross-tools-x86_64.tgz | tar xvz -C /

RUN mkdir -p /tmp/source

COPY ./chaos_start.sh /tmp/

RUN chmod a+x /tmp/chaos_start.sh
