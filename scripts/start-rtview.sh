#!/usr/bin/env bash

cd /home/docker/node/RTView

if [ -f "/home/docker/node/config/monitoring/RTView.json" ]; then
    pm2 start cardano-rt-view -l /home/docker/node/logs/rtview-std.log -- --port $RTVIEW_PORT --config /home/docker/node/config/monitoring/RTView.json --static /home/docker/node/RTView/static
else
    echo "No /home/docker/node/config/monitoring/RTView.json file, not starting RTView server"
fi