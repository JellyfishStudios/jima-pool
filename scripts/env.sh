#!/usr/bin/env bash

# cardano-node simple configuration for local use
export NODE_PATH="/home/docker/node"
export NODE_SOCKET_PATH="$NODE_PATH/config/node.socket"
export NODE_IP="127.0.0.1"
export NODE_PORT="3000"

# cardano-node relay configuration
export RELAY_IP="10.0.1.5"
export RELAY_PORT="3000"
export RELAY_USE_TOPOLOGY_UPDATER=1

# cardano-node block-producer configuration
export BLOCK_IP="10.0.2.5"
export BLOCK_PORT="3000"

# RTView port
export RTVIEW_PORT="13004"

# prometheus export
export PROMETHEUS_WEB_PORT="9090"
export PROMETHEUS_CARDANO_PORT="12789" # must be configured in mainnet-topology.json
export PROMETHEUS_NODE_PORT="12790"

# grafana config
export GRAFANA_ADMIN_USER="admin"
export GRAFANA_ADMIN_PASSWORD="cardano-is-great" # default password, change it later when configuring grafana

# required for cardano-node to function correctly
export CARDANO_NODE_SOCKET_PATH=$NODE_SOCKET_PATH