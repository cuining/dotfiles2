#!/bin/bash
# setup.d/packages-linux.sh — Debian/Ubuntu apt 包安装

_echo "installing runtime deps"
apt update && apt install -y git gpg bash curl locales gnupg software-properties-common

_echo "installing packages"
apt update &&
  DEBIAN_FRONTEND=noninteractive apt install -y \
    apparmor \
    apt-utils \
    autoconf \
    automake \
    bash \
    bash-completion \
    bc \
    bind9-host \
    bsdutils \
    build-essential \
    ca-certificates \
    clamav-base \
    cmake \
    cmatrix \
    coreutils \
    curl \
    dash \
    dbus \
    dbus-user-session \
    debianutils \
    diffutils \
    dnsutils \
    doxygen \
    dpkg \
    e2fsprogs \
    eslint \
    ethtool \
    expect \
    fail2ban \
    findutils \
    fzf \
    g++ \
    gawk \
    gcc \
    gettext \
    git \
    golang \
    golang-doc \
    golang-src \
    gpg \
    gpg-agent \
    gpgv \
    gzip \
    htop \
    iptables \
    iputils-ping \
    isc-dhcp-client \
    jq \
    keychain \
    libevent-dev \
    libncurses5-dev \
    libprotobuf-dev \
    libssl-dev \
    libtool \
    libtool-bin \
    libutempter-dev \
    libx11-dev \
    libxfixes-dev \
    lsb-base \
    lua5.4 \
    luajit \
    luarocks \
    man-db \
    manpages \
    mawk \
    ncurses-base \
    ncurses-bin \
    ncurses-term \
    net-tools \
    netbase \
    ninja-build \
    nmap \
    ocproxy \
    openconnect \
    openssh-client \
    openssh-server \
    openssl \
    pciutils \
    perl \
    perl-base \
    pkg-config \
    protobuf-compiler \
    proxychains4 \
    psmisc \
    python3 \
    python3-pip \
    python3-venv \
    ripgrep \
    rkhunter \
    rsyslog \
    secure-delete \
    shellcheck \
    silversearcher-ag \
    socat \
    stow \
    sudo \
    tar \
    tcpdump \
    tmux \
    toilet \
    traceroute \
    tree \
    tzdata \
    unzip \
    util-linux \
    uuid-runtime \
    vim-tiny \
    vpnc \
    whiptail \
    whois \
    xsel \
    xvfb \
    xz-utils \
    zlib1g \
    zlib1g-dev \
    zsh \
    zsh-syntax-highlighting

_ok "apt 包安装完成"
