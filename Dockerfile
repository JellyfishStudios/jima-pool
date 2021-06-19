FROM amazonlinux:latest

RUN yum update -y && \
    yum -y install sudo \
    yum install shadow-utils

RUN adduser appuser && \
    echo "appuser ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/appuser && \
    chmod 0440 /etc/sudoers.d/appuser

# Set working directory to install folder, we will move all install scripts here
WORKDIR /install

# Copy over install scripts
COPY scripts/cardanonode-install.sh ./
RUN chmod +x cardanonode-install.sh

# Swtich to appuser
USER appuser

# Install Cardano node
RUN ./cardanonode-install.sh