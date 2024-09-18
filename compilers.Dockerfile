FROM ruby:3.3.5

# Check for latest version here: https://gcc.gnu.org/releases.html, https://ftpmirror.gnu.org/gcc
ENV GCC_VERSIONS="14.2.0"
RUN set -xe && \
    for VERSION in $GCC_VERSIONS; do \
    curl -fSsL "https://ftpmirror.gnu.org/gcc/gcc-$VERSION/gcc-$VERSION.tar.gz" -o /tmp/gcc-$VERSION.tar.gz && \
    mkdir /tmp/gcc-$VERSION && \
    tar -xf /tmp/gcc-$VERSION.tar.gz -C /tmp/gcc-$VERSION --strip-components=1 && \
    rm /tmp/gcc-$VERSION.tar.gz && \
    cd /tmp/gcc-$VERSION && \
    ./contrib/download_prerequisites && \
    { rm *.tar.* || true; } && \
    tmpdir="$(mktemp -d)" && \
    cd "$tmpdir"; \
    /tmp/gcc-$VERSION/configure \
    --disable-multilib \
    --enable-languages=c,c++ \
    --prefix=/usr/local/gcc-$VERSION && \
    make -j$(nproc) && \
    make -j$(nproc) install-strip && \
    rm -rf /tmp/*; \
    done

# Check for latest version here: https://www.php.net/downloads
ENV PHP_VERSIONS=8.3.11
RUN set -xe && \
    apt-get update && \
    apt-get install -y --no-install-recommends bison re2c && \
    rm -rf /var/lib/apt/lists/* && \
    for VERSION in $PHP_VERSIONS; do \
    curl -fSsL "https://www.php.net/distributions/php-$VERSION.tar.gz" -o /tmp/php-$VERSION.tar.gz && \
    mkdir /tmp/php-$VERSION && \
    tar -xf /tmp/php-$VERSION.tar.gz -C /tmp/php-$VERSION --strip-components=1 && \
    rm /tmp/php-$VERSION.tar.gz && \
    cd /tmp/php-$VERSION && \
    ./buildconf --force && \
    ./configure \
    --prefix=/usr/local/php-$VERSION && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    rm -rf /tmp/*; \
    done

ENV LTS_NODE_VERSION=20.17.0
# Check for latest version here: https://nodejs.org/en
ENV NODE_VERSIONS="${LTS_NODE_VERSION}"
RUN set -xe && \
    for VERSION in $NODE_VERSIONS; do \
    curl -fSsL "https://nodejs.org/dist/v$VERSION/node-v$VERSION.tar.gz" -o /tmp/node-$VERSION.tar.gz && \
    mkdir /tmp/node-$VERSION && \
    tar -xf /tmp/node-$VERSION.tar.gz -C /tmp/node-$VERSION --strip-components=1 && \
    rm /tmp/node-$VERSION.tar.gz && \
    cd /tmp/node-$VERSION && \
    ./configure \
    --prefix=/usr/local/node-$VERSION && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    rm -rf /tmp/*; \
    done

RUN ln -s /usr/local/${LTS_NODE_VERSION}/bin/node /usr/bin/node

# Check for latest version here: https://www.python.org/downloads
ENV PYTHON_VERSIONS=3.12.6
RUN set -xe && \
    for VERSION in $PYTHON_VERSIONS; do \
    curl -fSsL "https://www.python.org/ftp/python/$VERSION/Python-$VERSION.tar.xz" -o /tmp/python-$VERSION.tar.xz && \
    mkdir /tmp/python-$VERSION && \
    tar -xf /tmp/python-$VERSION.tar.xz -C /tmp/python-$VERSION --strip-components=1 && \
    rm /tmp/python-$VERSION.tar.xz && \
    cd /tmp/python-$VERSION && \
    ./configure \
    --prefix=/usr/local/python-$VERSION && \
    make -j$(nproc) && \
    make -j$(nproc) install && \
    rm -rf /tmp/*; \
    done

RUN set -xe && \
    apt-get update && \
    apt-get install -y --no-install-recommends locales && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

RUN set -xe && \
    apt-get update && \
    apt-get install -y --no-install-recommends git libcap-dev pkg-config libsystemd-dev && \
    rm -rf /var/lib/apt/lists/* && \
    git clone https://gitlab.com/ChenAlejandro/isolate-docker.git /tmp/isolate && \
    cd /tmp/isolate && \
    git checkout c0cf4414d198f71ffc127149d235ea3dbc11b179 && \
    make -j$(nproc) install && \
    rm -rf /tmp/*

# Instructions when using cgroup v2 and isolate v2:
# 1. change the default.cf cg_root variable to point to the docker container's cgroup
# 2. create a new leaf directory in the docker container's cgroup
# 3. move the main process and the current process ($$) to the leaf directory's cgroup.procs file.
# 4. execute "echo '+cpuset +memory' > cgroup.subtree_control" in the docker container's cgroup

ENV BOX_ROOT=/var/local/lib/isolate
