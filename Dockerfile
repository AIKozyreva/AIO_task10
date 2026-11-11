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
	liblzma-dev \
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

# ----------------------------------------
# HTSlib 1.25, дата релиза: 27.10.2026 (с libdeflate)
# https://github.com/samtools/htslib
# ----------------------------------------
RUN wget -q https://github.com/samtools/htslib/releases/download/1.25/htslib-1.25.tar.bz2 && \
    tar -xjf htslib-1.25.tar.bz2 && \
    cd htslib-1.25 && \
    ./configure --prefix=$SOFT/htslib-1.25 \
        --with-libdeflate \
        CPPFLAGS="-I$LIBDEFLATE/include" \
        LDFLAGS="-L$LIBDEFLATE/lib" && \
    make -j"$(nproc)" && \
    make install && \
    cd /tmp && \
    rm -rf htslib-1.25 htslib-1.25.tar.bz2

ENV HTSLIB=$SOFT/htslib-1.25
ENV BGZIP=$HTSLIB/bin/bgzip
ENV TABIX=$HTSLIB/bin/tabix
ENV HTSFILE=$HTSLIB/bin/htsfile
ENV LD_LIBRARY_PATH=$HTSLIB/lib:$LD_LIBRARY_PATH

# ----------------------------------------
# HTSlib 1.25, дата релиза: 27.10.2026 (собирается с libdeflate)
# https://github.com/samtools/htslib
# ----------------------------------------
RUN wget -q https://github.com/samtools/htslib/releases/download/1.25/htslib-1.25.tar.bz2 && \
    tar -xjf htslib-1.25.tar.bz2 && \
    cd htslib-1.25 && \
    ./configure --prefix=$SOFT/htslib-1.25 \
        --with-libdeflate \
        CPPFLAGS="-I$LIBDEFLATE/include" \
        LDFLAGS="-L$LIBDEFLATE/lib" && \
    make -j"$(nproc)" && \
    make install && \
    cd /tmp && \
    rm -rf htslib-1.25 htslib-1.25.tar.bz2

ENV HTSLIB=$SOFT/htslib-1.25
ENV BGZIP=$HTSLIB/bin/bgzip
ENV TABIX=$HTSLIB/bin/tabix
ENV HTSFILE=$HTSLIB/bin/htsfile
ENV LD_LIBRARY_PATH=$HTSLIB/lib:$LD_LIBRARY_PATH

# -------------------------------------
# Samtools 1.25, дата релиза: 27.10.2026 (с исп-м HTSlib)
# https://github.com/samtools/samtools
# -------------------------------------
RUN wget -q https://github.com/samtools/samtools/releases/download/1.25/samtools-1.25.tar.bz2 && \
    tar -xjf samtools-1.25.tar.bz2 && \
    cd samtools-1.25 && \
    ./configure --prefix=$SOFT/samtools-1.25 \
        --with-htslib=$HTSLIB \
        CPPFLAGS="-I$LIBDEFLATE/include" \
        LDFLAGS="-L$LIBDEFLATE/lib" && \
    make -j"$(nproc)" && \
    make install && \
    cd /tmp && \
    rm -rf samtools-1.25 samtools-1.25.tar.bz2

ENV SAMTOOLS=$SOFT/samtools-1.25/bin/samtools

# --------------------------------------
# BCFtools 1.25, дата релиза: 27.10.2026 (с исп-м HTSlib)
# https://github.com/samtools/bcftools
# --------------------------------------
RUN wget -q https://github.com/samtools/bcftools/releases/download/1.25/bcftools-1.25.tar.bz2 && \
    tar -xjf bcftools-1.25.tar.bz2 && \
    cd bcftools-1.25 && \
    ./configure --prefix=$SOFT/bcftools-1.25 \
        --with-htslib=$HTSLIB \
        CPPFLAGS="-I$LIBDEFLATE/include" \
        LDFLAGS="-L$LIBDEFLATE/lib" && \
    make -j"$(nproc)" && \
    make install && \
    cd /tmp && \
    rm -rf bcftools-1.25 bcftools-1.25.tar.bz2

ENV BCFTOOLS=$SOFT/bcftools-1.25/bin/bcftools
ENV BCFTOOLS_PLUGINS=$SOFT/bcftools-1.25/libexec/bcftools

# ----------------------------------------
# VCFtools 0.1.17, дата релиза: 15.05.2025
# https://github.com/vcftools/vcftools
# ----------------------------------------
RUN wget -q https://github.com/vcftools/vcftools/releases/download/v0.1.17/vcftools-0.1.17.tar.gz && \
    tar -xzf vcftools-0.1.17.tar.gz && \
    cd vcftools-0.1.17 && \
    ./configure --prefix=$SOFT/vcftools-0.1.17 && \
    make -j"$(nproc)" && \
    make install && \
    cd /tmp && \
    rm -rf vcftools-0.1.17 vcftools-0.1.17.tar.gz

ENV VCFTOOLS=$SOFT/vcftools-0.1.17/bin/vcftools
ENV PERL5LIB=$SOFT/vcftools-0.1.17/share/perl5/site_perl

WORKDIR /tmp

# --------------------------------------
# pysam 0.24.1, дата релиза: 07.09.2026 
# https://github.com/pysam-developers/pysam
# --------------------------------------
RUN pip3 install --no-cache-dir --target=$SOFT/pysam-0.24.1 pysam==0.24.1

ENV PYTHONPATH=$SOFT/pysam-0.24.1

# --------------------------------------------
# restore_ref_alt.py, дата создания: 10.11.2026 (скрипт, задача 3)
# --------------------------------------------
COPY scripts/restore_ref_alt.py $SOFT/restore_ref_alt-1.0/restore_ref_alt.py
RUN chmod +x $SOFT/restore_ref_alt-1.0/restore_ref_alt.py

ENV RESTOREREFALT=$SOFT/restore_ref_alt-1.0/restore_ref_alt.py

ENV PATH=$SOFT/restore_ref_alt-1.0:$SOFT/vcftools-0.1.17/bin:$SOFT/bcftools-1.25/bin:$SOFT/samtools-1.25/bin:$HTSLIB/bin:$LIBDEFLATE/bin:$PATH

WORKDIR /root
CMD ["/bin/bash"]
