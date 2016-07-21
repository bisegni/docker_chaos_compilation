FROM ubuntu:14.04

MAINTAINER Claudio Bisegni "Claudio.Bisegni@lnf.infn.it"

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

RUN mkdir -p /tmp/source

COPY ./chaos_start.sh /tmp/

RUN chmod a+x /tmp/chaos_start.sh
