FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHON_VERSION=3.7.9 \
    FIREFOX_VERSION=120.0

# Update and install required packages
RUN apt-get update && apt-get install -y \
    software-properties-common \
    wget \
    curl \
    git \
    openjdk-11-jdk \
    xvfb \   # Install Xvfb but do NOT start it
    x11vnc \
    tigervnc-standalone-server \
    tigervnc-tools \
    fluxbox \
    unzip \
    openssh-server \
    build-essential \
    libssl-dev \
    libffi-dev \
    libsqlite3-dev \
    libbz2-dev \
    libncurses5-dev \
    libgdbm-dev \
    libreadline-dev \
    liblzma-dev \
    libnss3-dev \
    zlib1g-dev \
    libgtk-3-0 \
    libdbus-glib-1-2 \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.7.9 from source
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar xvf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    make altinstall && \
    cd .. && rm -rf Python-${PYTHON_VERSION} Python-${PYTHON_VERSION}.tgz

# Set Python 3.7 as default
RUN ln -sf /usr/local/bin/python3.7 /usr/bin/python3 && \
    ln -sf /usr/local/bin/python3.7 /usr/bin/python

# Install pip and necessary Python packages
RUN python3 -m ensurepip && \
    python3 -m pip install --upgrade pip && \
    pip3 install selenium==4.14.0 webdriver-manager

# Install Geckodriver 0.33
RUN wget -q https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz \
    && tar -xzf geckodriver-v0.33.0-linux64.tar.gz \
    && mv geckodriver /usr/local/bin/ \
    && chmod +x /usr/local/bin/geckodriver \
    && rm geckodriver-v0.33.0-linux64.tar.gz

# Install Firefox 120 manually
RUN wget -q https://ftp.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}/linux-x86_64/en-US/firefox-${FIREFOX_VERSION}.tar.bz2 && \
    tar -xjf firefox-${FIREFOX_VERSION}.tar.bz2 && \
    mv firefox /opt/firefox && \
    ln -sf /opt/firefox/firefox /usr/local/bin/firefox && \
    rm firefox-${FIREFOX_VERSION}.tar.bz2

# Configure SSH
RUN mkdir /var/run/sshd && \
    echo 'root:jenkins' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "export VISIBLE=now" >> /etc/profile

# Create 'tommy' user with password 'tommy'
RUN useradd -m -s /bin/bash tommy && \
    echo 'tommy:tommy' | chpasswd && \
    usermod -aG sudo tommy

# Expose ports for VNC and SSH
EXPOSE 5901 22

# Start VNC, but NOT Xvfb (since Jenkins will handle it)
CMD bash -c "fluxbox & \
             x11vnc -display :1 -forever -loop -noxdamage -repeat -rfbport 5901 -shared & \
             /usr/sbin/sshd -D"
