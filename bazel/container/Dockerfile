FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        gcc \
        g++ \
        binutils \
        lld \
        python3 \
        python3-pip \
        git \
        curl \
        wget \
        libz-dev \
        pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Bazelisk as "bazel"
RUN curl -fsSL \
        https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 \
        -o /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

ENV PATH="/usr/local/bin:${PATH}"
ENV LC_ALL=C

WORKDIR /workspace

CMD ["/bin/bash"]