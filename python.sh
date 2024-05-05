#!/bin/bash

# Update package list and install dependencies
sudo apt update
sudo apt install -y \
    wget \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libgdbm-dev \
    libdb5.3-dev \
    libbz2-dev \
    libexpat1-dev \
    liblzma-dev \
    tk-dev \
    libffi-dev \
    uuid-dev \
    libffi-dev

# Download Python source
wget https://www.python.org/ftp/python/3.11.0/Python-3.11.0.tgz

# Extract Python source
tar -xf Python-3.11.0.tgz

# Navigate to Python source directory
cd Python-3.11.0

# Configure Python build with optimizations and ensure shared library is enabled
./configure --enable-optimizations --enable-shared

# Build and install Python
make -j $(nproc)
sudo make altinstall

# Clean up downloaded files
cd ..
rm -rf Python-3.11.0 Python-3.11.0.tgz

# Install Python3-pip
sudo apt install python3-pip -y
