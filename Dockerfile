FROM amazonlinux:latest

RUN yum update -y && \
    yum -y install sudo \
    yum install shadow-utils

RUN adduser adanode && \
    echo "adanode ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/adanode && \
    chmod 0440 /etc/sudoers.d/adanode

# Swtich to adanode
USER adanode

# Set working directory to users home
WORKDIR /home/adanode

# Copy over install & configuration scripts
COPY install/ ./install/
COPY utility/ ./utility/

# Scripts need to be executable
RUN sudo chmod -R +x utility/
RUN sudo chmod -R +x install/

# Install & configure Cardano node
RUN ./install/cardanonode-install.sh

# Install & configure Grafana node
RUN ./install/grafana-install.sh