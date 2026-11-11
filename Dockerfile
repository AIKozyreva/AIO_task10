FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

ENV SOFT=/soft

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
	cmake \
	pkg-config \
	wget \
	ca-certificates \
	bzip2 \
	zlib1g-dev \
	libbz2-dev \
	libcurl4-openssl-dev \
	libssl-dev \
	libncurses5-dev \
	perl \
	python3 \
	python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# libdeflate v1.26, дата релиза: 22.08.2026
# https://github.com/ebiggers/libdeflate
# -----------------------------------------------------------------------------
RUN wget -q https://github.com/ebiggers/libdeflate/releases/download/v1.26/libdeflate-1.26.tar.gz && \
    tar -xzf libdeflate-1.26.tar.gz && \
    cd libdeflate-1.26 && \
    cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$SOFT/libdeflate-1.26 \
        -DCMAKE_INSTALL_LIBDIR=lib && \
    cmake --build build -j"$(nproc)" && \
    cmake --install build && \
    cd /tmp && \
    rm -rf libdeflate-1.26 libdeflate-1.26.tar.gz

ENV LIBDEFLATE=$SOFT/libdeflate-1.26
ENV LIBDEFLATEGZIP=$LIBDEFLATE/bin/libdeflate-gzip
ENV LIBDEFLATEGUNZIP=$LIBDEFLATE/bin/libdeflate-gunzip
ENV LD_LIBRARY_PATH=$LIBDEFLATE/lib

WORKDIR /tmp
