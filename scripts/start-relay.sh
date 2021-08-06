#!/usr/bin/env bash

while true; do
    echo "Starting relay node"
    cardano-node run \
        --topology $NODE_HOME/config/mainnet-topology.json \
        --config $NODE_HOME/config/mainnet-config.json \
        --database-path $NODE_HOME/config/db \
        --socket-path $NODE_HOME/config/db/socket \
        --host-addr 0.0.0.0 \
        --port 3000
done