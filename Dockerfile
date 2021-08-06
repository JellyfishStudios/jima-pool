FROM debian:stable-slim

# version of cardano-node to build
ARG CARDANO_NODE_VERSION=1.27.0
ARG CNCLI_VERSION=2.0.3
ARG GHC_VERSION=8.10.4
ARG CABAL_VERSION=3.4.0.0

# based on arradev/cardano-node
LABEL maintainer="adrian.c.dunne@gmail.com"

# Use bash as the default shell
SHELL ["/bin/bash", "-c"]

# Install software-properties-common to get add-apt-repository command
RUN apt-get update -y && apt-get install -y software-properties-common && apt-get clean

# Install build dependencies
RUN apt-get update -y \
    && apt-get install -y sudo automake build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ \
    tmux git jq wget gpg libncursesw5 libtool autoconf vim procps dnsutils bc curl nano cron python3 python3-pip htop unzip grc dbus prometheus \
    prometheus-node-exporter software-properties-common node.js npm daemontools \
    && apt-get clean

RUN pip3 install pytz

RUN adduser docker && \
    echo "docker ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/docker && \
    chmod 0440 /etc/sudoers.d/docker

# Swtich to new user for application container
USER docker
WORKDIR /home/docker

# Add config volume
RUN mkdir -p /home/docker/config/
VOLUME /home/docker/config/

# Add logs volume
RUN mkdir -p /home/docker/logs/
VOLUME /home/docker/logs/

# Add scripts volume
RUN mkdir -p /home/docker/scripts/
VOLUME /home/docker/scripts/

# Add keys volume
RUN mkdir -p /home/docker/keys/
VOLUME /home/docker/keys/

# Add tmp volume
RUN mkdir -p /home/docker/tmp/
VOLUME /home/docker/tmp/

# Install PM2: process manager to auto-restart prometheus-node-exporter of grafana on crash
RUN sudo npm install -g pm2

# Install Grafana
RUN sudo curl https://packages.grafana.com/gpg.key | sudo apt-key add - \
    && sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main" \
    && sudo apt-get update \
    && sudo apt-get install -y grafana \
    && sudo apt-get clean

# ENV variables
ENV NODE_PORT="3000" \
    NODE_NAME="node1" \
    NODE_TOPOLOGY="" \
    NODE_RELAY="False" \
    CARDANO_NETWORK="main" \
    EKG_PORT="12788" \
    PROMETHEUS_HOST="127.0.0.1" \
    PROMETHEUS_PORT="12798" \
    RESOLVE_HOSTNAMES="False" \
    REPLACE_EXISTING_CONFIG="False" \
    POOL_PLEDGE="100000000000" \
    POOL_COST="10000000000" \
    POOL_MARGIN="0.03" \
    METADATA_URL="" \
    PUBLIC_RELAY_IP="TOPOLOGY" \
    WAIT_FOR_SYNC="True" \
    AUTO_TOPOLOGY="True" \
    LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}" \
    CARDANO_NODE_SOCKET_PATH="DEFAULT" \
    PATH="~/.cabal/bin:~/.ghcup/bin:~/.local/bin:~/scripts:~/scripts/functions:${PATH}"

# Installing GHCup (GHC install manager)
RUN wget https://downloads.haskell.org/~ghcup/x86_64-linux-ghcup \ 
    && chmod 777 x86_64-linux-ghcup \
    && sudo mv x86_64-linux-ghcup /usr/local/bin/ghcup \
    && ghcup upgrade

# Installing Cabal
RUN ghcup install cabal $CABAL_VERSION \
    && ghcup set cabal $CABAL_VERSION \
    && cabal update \
    && cabal --version 

# Installing GHC
RUN ghcup install ghc $GHC_VERSION \
    && ghcup set ghc $GHC_VERSION \
    && ghc --version

# Install libsodium
RUN cd tmp \
    && git clone https://github.com/input-output-hk/libsodium \
    && cd libsodium \
    && git checkout 66f017f1 \
    && ./autogen.sh \
    && ./configure \
    && make \
    && sudo make install \
    && cd .. && rm -rf libsodium

ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" \
    PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"

# Install cardano-node
RUN cd tmp \
    && echo "Fetching tags/$CARDANO_NODE_VERSION..." \
    && git clone https://github.com/input-output-hk/cardano-node.git \
    && cd cardano-node \
    && git fetch --all --tags \
    && git checkout tags/$CARDANO_NODE_VERSION \
    && echo "Building version $CARDANO_NODE_VERSION" \
    && cabal build all \
    && mkdir -p ~/.cabal/bin/ \
    && find . -name cardano-node \
    && find . -name cardano-cli \
    && cp cardano-node/dist-newstyle/build/x86_64-linux/ghc-${GHC_VERSION}/cardano-node-${CARDANO_NODE_VERSION}/x/cardano-node/build/cardano-node/cardano-node ~/.cabal/bin/ \
    && cp cardano-node/dist-newstyle/build/x86_64-linux/ghc-${GHC_VERSION}/cardano-cli-${CARDANO_NODE_VERSION}/x/cardano-cli/build/cardano-cli/cardano-cli ~/.cabal/bin/ \
    && rm -rf ~/.cabal/packages \
    && rm -rf /usr/local/lib/ghc-${GHC_VERSION}/ \
    && rm -rf ~/.cabal/store/ghc-${GHC_VERSION} \
    && rm -rf cardano-node/dist-newstyle/

# Install RTView
RUN mkdir rtview \
    && cd rtview \
    && wget https://github.com/input-output-hk/cardano-rt-view/releases/download/0.3.0/cardano-rt-view-0.3.0-linux-x86_64.tar.gz \
    && tar xzvf cardano-rt-view-0.3.0-linux-x86_64.tar.gz \
    && rm cardano-rt-view-0.3.0-linux-x86_64.tar.gz

ENV PATH="~/RTView/:${PATH}"

# Remove /etc/profile, so it doesn't mess up our PATH env
RUN sudo rm /etc/profile

# Install cargo
RUN mkdir -p .cargo/bin \
    && chown -R $USER\: .cargo \
    && touch .profile \
    && chown $USER\: .profile \
    && curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y \
    && source .cargo/env \
    && rustup install stable \
    && rustup default stable \
    && rustup update \
    && rustup component add clippy rustfmt \
    && source .cargo/env
 
# Install cncli
RUN cd tmp \
    && git clone --recurse-submodules https://github.com/AndrewWestberg/cncli \
    && cd cncli \
    && git checkout v${CNCLI_VERSION} \
    && cargo install --path . --force \
    && cd ..

# install leaderlog script
RUN pip3 install pytz
RUN mkdir -p scripts/pooltool \
    && cd scripts/pooltool \
    && git clone https://github.com/papacarp/pooltool.io

# Fetch latest node configs
RUN cd config \
    && NODE_BUILD_NUM=$(curl https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g') \
    && wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/mainnet-byron-genesis.json \
    && wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/mainnet-shelley-genesis.json \
    && wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/mainnet-alonzo-genesis.json \
    && wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/mainnet-topology.json \
    && wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/mainnet-config.json \
    && sed -i mainnet-config.json -e "s/TraceBlockFetchDecisions\": false/TraceBlockFetchDecisions\": true/g"

# Copy node scripts
COPY scripts/ ~/scripts/
RUN sudo chmod -R +x ~/scripts

# Expose ports
## cardano-node, EKG, Prometheus
EXPOSE 3000 8090 12788 12798 13004 13005 13006 13007

ENTRYPOINT ["/bin/bash", "-l"]