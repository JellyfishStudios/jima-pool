#!/usr/bin/env bash

while true; do
    echo "Starting block-producing node"
    cardano-node run \
        --topology $NODE_HOME/config/mainnet-topology.json \
        --config $NODE_HOME/config/mainnet-config.json \
        --database-path $NODE_HOME/config/db \
        --socket-path $NODE_HOME/config/db/socket \
        --host-addr 0.0.0.0 \
        --port 3000 \
        --shelley-kes-key $NODE_HOME/config/kes.key \
        --shelley-vrf-key $NODE_HOME/config/vrf.key \ 
        --shelley-operational-certificate $NODE_HOME/config/node.cert
done