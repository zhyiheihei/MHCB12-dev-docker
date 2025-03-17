# 使用官方镜像作为基础
FROM ubuntu:22.04

LABEL maintainer="zhyi4 <molishanguang@outlook.com>"

# 备份并替换源列表为中科大镜像
RUN cp -a /etc/apt/sources.list /etc/apt/sources.list.bak \
    && sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list


# 安装基础工具、编译依赖和 tini
RUN apt-get update && apt-get install -y git
# 克隆仓库
WORKDIR /root
RUN git clone https://git.zhyi.cc:5000/zhyi/MHCB12.git
# 安装基础工具、编译依赖和 tini
RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends\
        autoconf \
        automake \
        bison \
        build-essential \
        default-jdk \
        dfu-util \
        genromfs \
        flex \
        gperf \
        kconfig-frontends \
        rsync \
        inotify-tools \
        dos2unix \
        file \
        tini \
        repo \
        python3-pip \
        lib32ncurses5-dev \
        libc6-dev-i386 \
        libx11-dev \
        libx11-dev:i386 \
        libxext-dev \
        libxext-dev:i386 \
        net-tools \
        pkgconf \
        unionfs-fuse \
        zlib1g-dev \
        software-properties-common \
        libpulse-dev:i386 \
        libasound2-dev:i386 \
        libasound2-plugins:i386 \
        libusb-1.0-0-dev \
        libusb-1.0-0-dev:i386 \
        unzip \
    && add-apt-repository ppa:ubuntu-toolchain-r/test \
    && apt-get update \
    && apt-get install -y --no-install-recommends sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 传入编译和同步脚本并赋予执行权限
COPY sh/build.sh /root/build.sh
COPY sh/sync.sh /root/sync.sh
COPY sh/convert_file.sh /root/convert_file.sh
RUN chmod +x /root/sync.sh /root/build.sh /root/convert_file.sh

# 设置符号链接以便于直接使用
RUN ln -s /root/build.sh /usr/local/bin/build

# 再次更新包列表并安装任何未安装的依赖
RUN apt-get update \
    && apt-get install -y -f \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /root/workspace

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/root/sync.sh"]
