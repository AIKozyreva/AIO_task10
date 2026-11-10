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

WORKDIR /tmp
