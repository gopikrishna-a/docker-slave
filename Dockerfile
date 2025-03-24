FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packages
RUN apt-get update && apt-get install -y \
    software-properties-common \
    wget \
    curl \
    git \
    openjdk-11-jdk \
    xvfb \
    firefox \
    unzip \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.7.9
RUN apt-get update && apt-get install -y \
    python3.7 \
    python3.7-venv \
    python3.7-dev \
    && ln -sf /usr/bin/python3.7 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.7 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# Install Geckodriver 0.33
RUN wget -q https://github.com/mozilla/geckodriver/releases/download/v0.33.0/geckodriver-v0.33.0-linux64.tar.gz \
    && tar -xzf geckodriver-v0.33.0-linux64.tar.gz \
    && mv geckodriver /usr/local/bin/ \
    && chmod +x /usr/local/bin/geckodriver \
    && rm geckodriver-v0.33.0-linux64.tar.gz

# Install Selenium
RUN python3 -m pip install --upgrade pip && \
    pip3 install selenium==4.14.0 webdriver-manager

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

# Expose SSH Port
EXPOSE 22

# Start SSH and keep container running
CMD ["/usr/sbin/sshd", "-D"]
