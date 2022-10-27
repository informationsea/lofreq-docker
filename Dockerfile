FROM debian:11-slim AS download-lofreq
RUN apt-get update && apt-get upgrade -y && apt-get install -y curl && apt-get clean
WORKDIR /download
RUN curl -OL https://github.com/CSB5/lofreq/raw/master/dist/lofreq_star-2.1.5_linux-x86-64.tgz
RUN tar xzf lofreq_star-2.1.5_linux-x86-64.tgz

FROM debian:11-slim AS download-bcftools
RUN apt-get update && apt-get install -y curl lbzip2 bzip2
ARG BCFTOOLS_VERSION=1.16
RUN curl --fail -OL https://github.com/samtools/bcftools/releases/download/${BCFTOOLS_VERSION}/bcftools-${BCFTOOLS_VERSION}.tar.bz2
RUN tar xf bcftools-${BCFTOOLS_VERSION}.tar.bz2

FROM debian:11-slim AS download-samtools
RUN apt-get update && apt-get install -y curl lbzip2 bzip2
ARG SAMTOOLS_VERSION=1.16.1
RUN curl --fail -OL https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2
RUN tar xf samtools-${SAMTOOLS_VERSION}.tar.bz2

FROM debian:11-slim AS download-htslib
RUN apt-get update && apt-get install -y curl lbzip2 bzip2
ARG HTSLIB_VERSION=1.16
RUN curl --fail -OL https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2
RUN tar xf htslib-${HTSLIB_VERSION}.tar.bz2

FROM debian:11-slim AS buildenv-bcftools
RUN apt-get update && apt-get install -y build-essential ncurses-dev libbz2-dev zlib1g-dev libcurl4-openssl-dev curl liblzma-dev
ARG BCFTOOLS_VERSION=1.16
COPY --from=download-bcftools /bcftools-${BCFTOOLS_VERSION} /bcftools-${BCFTOOLS_VERSION}
WORKDIR /bcftools-${BCFTOOLS_VERSION}
RUN ./configure --prefix=/usr
RUN make -j4
RUN make install DESTDIR=/dest

FROM debian:11-slim AS buildenv-samtools
RUN apt-get update && apt-get install -y build-essential ncurses-dev libbz2-dev zlib1g-dev libcurl4-openssl-dev curl liblzma-dev
ARG SAMTOOLS_VERSION=1.16.1
COPY --from=download-samtools /samtools-${SAMTOOLS_VERSION} /bcftools-${SAMTOOLS_VERSION}
WORKDIR /bcftools-${SAMTOOLS_VERSION}
RUN ./configure --prefix=/usr
RUN make -j4
RUN make install DESTDIR=/dest

FROM debian:11-slim AS buildenv-htslib
RUN apt-get update && apt-get install -y build-essential ncurses-dev libbz2-dev zlib1g-dev libcurl4-openssl-dev curl liblzma-dev
ARG HTSLIB_VERSION=1.16
COPY --from=download-htslib /htslib-${HTSLIB_VERSION} /htslib-${HTSLIB_VERSION}
WORKDIR /htslib-${HTSLIB_VERSION}
RUN ./configure --prefix=/usr
RUN make -j4
RUN make install DESTDIR=/dest

FROM debian:11-slim
RUN apt-get update && apt-get install -y bash libbz2-1.0 libcurl4 liblzma5 && apt-get clean -y && rm -rf /var/lib/apt/lists/*
COPY --from=buildenv-bcftools /dest /
COPY --from=buildenv-samtools /dest /
COPY --from=buildenv-htslib /dest /
COPY --from=download-lofreq /download/lofreq_star-2.1.5_linux-x86-64/ /usr

ADD run.sh /run.sh
ENTRYPOINT [ "/bin/bash", "/run.sh" ]