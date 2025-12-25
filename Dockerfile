# Use Ubuntu 24.04 as base
FROM ubuntu:24.04

# Set Flutter version as build argument (can be overridden at build time)
ARG FLUTTER_VERSION=3.32.0

# Set environment variables
ENV ANDROID_HOME="/home/flutter/android-sdk"
ENV ANDROID_SDK_ROOT="/home/flutter/android-sdk"
ENV PUB_CACHE="/home/flutter/.pub-cache"
ENV PUB_HOSTED_URL="https://pub.dartlang.org"
ENV DART_SDK="/usr/lib/dart"
ENV PATH="/home/flutter/.pub-cache/bin:/home/flutter/fvm/default/bin:${DART_SDK}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# Install dependencies for Flutter testing (add lcov for coverage reporting and dart-sdk for FVM)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
    openssh-client \
        unzip \
        xz-utils \
        zip \
        libglu1-mesa \
        xvfb \
        ca-certificates \
    lcov \
    apt-transport-https \
    wget \
    gnupg \
    openjdk-17-jdk \
    && wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/dart.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | tee /etc/apt/sources.list.d/dart_stable.list && \
    apt-get update && \
    apt-get install -y dart && \
    rm -rf /var/lib/apt/lists/*

# Update certificates and configure git
RUN update-ca-certificates && \
    git config --global http.sslverify true

# Create non-root user
RUN useradd -m -s /bin/bash flutter && \
    mkdir -p /home/flutter/.pub-cache /home/flutter/fvm /home/flutter/android-sdk && \
    chown -R flutter:flutter /home/flutter

# Switch to non-root user
USER flutter

# Install Android SDK Command Line Tools
RUN cd /home/flutter/android-sdk && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip commandlinetools-linux-11076708_latest.zip && \
    rm commandlinetools-linux-11076708_latest.zip && \
    mkdir -p cmdline-tools/latest && \
    mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true && \
    yes | cmdline-tools/latest/bin/sdkmanager --licenses && \
    cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Set working directory and ensure proper ownership
WORKDIR /app

# Install FVM globally using dart
RUN dart pub global activate fvm

# Copy .fvmrc to use project's Flutter version
COPY --chown=flutter:flutter .fvmrc ./

# Install Flutter using FVM based on .fvmrc and set it as default
RUN fvm install && \
    fvm global ${FLUTTER_VERSION}

# Ensure PATH and SSH alias are exported in interactive shells
RUN echo 'export PATH="$PATH:$HOME/.pub-cache/bin:$HOME/fvm/default/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"' >> ~/.bashrc
RUN mkdir -p /home/flutter/.ssh && \
    echo "alias load_ripplearc_key='eval \"\$(ssh-agent -s)\" && ssh-add /home/flutter/.ssh/ripplearc_git_rsa'" >> /home/flutter/.bashrc

# Verify Flutter installation and configure
RUN fvm flutter doctor --verbose && \
    fvm flutter config --no-analytics && \
    fvm flutter precache

# Copy pubspec files for better caching
COPY --chown=flutter:flutter pubspec.yaml pubspec.lock ./

# Install dependencies using FVM-managed Flutter
RUN fvm flutter pub get

# Copy the rest of the application
COPY --chown=flutter:flutter . .

# Default command: run tests and generate golden files
CMD ["/bin/bash"]