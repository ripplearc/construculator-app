# Use Ubuntu 24.04 as base
FROM ubuntu:24.04

# Set environment variables
ENV FLUTTER_VERSION=3.32.0
ENV PATH="/flutter/bin:${PATH}"
ENV PUB_CACHE="/home/flutter/.pub-cache"
ENV PUB_HOSTED_URL="https://pub.dartlang.org"

# Install dependencies for Flutter testing (add lcov for coverage reporting)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
        libglu1-mesa \
        xvfb \
        ca-certificates \
        lcov \
        && rm -rf /var/lib/apt/lists/*

# Update certificates and configure git
RUN update-ca-certificates && \
    git config --global http.sslverify true

# Install Flutter using the official Flutter SDK archive (more reliable)
RUN curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.0-stable.tar.xz -o flutter.tar.xz && \
    tar -xf flutter.tar.xz -C / && \
    rm flutter.tar.xz

# Fix git ownership and create non-root user
RUN git config --global --add safe.directory /flutter && \
    useradd -m -s /bin/bash flutter && \
    chown -R flutter:flutter /flutter && \
    mkdir -p /home/flutter/.pub-cache && \
    chown -R flutter:flutter /home/flutter

# Set working directory and ensure proper ownership
WORKDIR /app
RUN chown -R flutter:flutter /app

# Copy pubspec files first for better caching
COPY pubspec.yaml pubspec.lock ./
RUN chown flutter:flutter pubspec.yaml pubspec.lock

# Switch to non-root user before running flutter commands
USER flutter

# Verify Flutter installation and configure pub cache
RUN flutter doctor --verbose && \
    flutter config --no-analytics && \
    flutter precache

# Install dependencies
RUN flutter pub get

# Copy the rest of the application
COPY --chown=flutter:flutter . .

# Default command: run tests and generate golden files
CMD ["/bin/bash"]
