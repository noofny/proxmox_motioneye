#!/bin/bash


echo "Setup OS : begin"


# timezone
echo "Setting timezone..."
timedatectl set-timezone Australia/Sydney


# locale
echo "Setting locale..."
LOCALE_VALUE="en_AU.UTF-8"
echo ">>> locale-gen..."
locale-gen ${LOCALE_VALUE}
cat /etc/default/locale
source /etc/default/locale
echo ">>> update-locale..."
update-locale ${LOCALE_VALUE}
echo ">>> hack /etc/ssh/ssh_config..."
sed -e '/SendEnv/ s/^#*/#/' -i /etc/ssh/ssh_config


# patch
echo "Patching..."
apt-get -y purge openssh-{client,server}
apt-get autoremove
apt-get update --allow-releaseinfo-change
apt-get upgrade -y


# packages
echo "Installing packages..."
apt-get update --allow-releaseinfo-change && \
apt-get install -y \
    curl \
    wget \
    htop \
    net-tools \
    motion \
    ffmpeg \
    v4l-utils \
    python-pip \
    python-dev \
    python-setuptools \
    libssl-dev \
    libcurl4-openssl-dev \
    libjpeg-dev \
    libz-dev


# path
echo "Updating PATH..."
export PATH=$PATH:/usr/local/bin


echo "Setup OS : script complete!"
