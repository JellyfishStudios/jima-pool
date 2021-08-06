#!/usr/bin/env bash

IMAGE="karatakos/cardano-node"
VERSION="latest"

CURR_DIR=$(dirname "${BASH_SOURCE[0]}")
ABS_CURR_DIR=$(realpath $CURR_DIR)

# if node, producer or relay, forward arguments to /cmd/start-node-with-shell.sh
if [ "$1" == "producer" ]
then
    docker container rm producer 2> /dev/null
    docker run \
        --name producer \
        --network=host \
        --restart unless-stopped \
        -v $ABS_CURR_DIR/docker/logs/:/home/docker/node/log/ \
        -v $ABS_CURR_DIR/docker/config/:/home/docker/node/config/ \
        -v $ABS_CURR_DIR/docker/scripts/:/home/docker/node/scripts/ \
        -v $ABS_CURR_DIR/docker/keys/:/home/docker/node/keys/ \
        -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
        -it $IMAGE:$VERSION -c "cd /home/docker; source scripts/env.sh; scripts/start-blockproducer.sh 2>&1 | multilog n100 logs/cardano-node &; scripts/start-prometheus-exporter.sh 2>&1 | multilog n100 logs/monitoring &; /bin/bash"

    # BLOCK PRODUCER topology configuration
    cat > $ABS_CURR_DIR/docker/config/mainnet-topology.json << EOF 
    {
        "Producers": [
            {
                "addr": "127.0.0.1",
                "port": 3000,
                "valency": 1
            }
        ]
    }
EOF

else
    docker container rm relay 2> /dev/null
    docker run \
        --name relay \
        --network=host \
        --restart unless-stopped \
        -v $ABS_CURR_DIR/docker/logs/:/home/docker/node/log/ \
        -v $ABS_CURR_DIR/docker/config/:/home/docker/node/config/ \
        -v $ABS_CURR_DIR/docker/scripts/:/home/docker/node/scripts/ \
        -v $ABS_CURR_DIR/docker/keys/:/home/docker/node/keys/ \
        -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
        -it $IMAGE:$VERSION -c "cd /home/docker; source scripts/env.sh; scripts/start-relay.sh 2>&1 | multilog n100 logs/cardano-node &; scripts/start-prometheus-exporter.sh 2>&1 | multilog n100 logs/monitoring &; scripts/start-prometheus-server.sh 2>&1 | multilog n100 logs/monitoring &; scripts/start-grafana-server.sh 2>&1 | multilog n100 logs/monitoring &; scripts/start-rtview.sh 2>&1 | multilog n100 logs/monitoring &; /bin/bash"

    # RELAY topology configuration
    cat > $ABS_CURR_DIR/docker/config/mainnet-topology.json << EOF 
    {
        "Producers": [
            {
                "addr": "127.0.0.1",
                "port": 3000,
                "valency": 1
            },
            {
                "addr": "relays-new.cardano-mainnet.iohk.io",
                "port": 3001,
                "valency": 2
            }
        ]
  }
EOF

fi