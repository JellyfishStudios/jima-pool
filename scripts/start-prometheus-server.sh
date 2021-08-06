#!/usr/bin/env bash
export PROMETHEUS_DIR=/home/docker/node/config/monitoring/prometheus/

mkdir -p $PROMETHEUS_DIR/data
sleep 3

if [ -f "/config/monitoring/prometheus/prometheus.yml" ]; then
    pm2 start prometheus --log /home/docker/node/logs/prometheus.logs -- --config.file=$PROMETHEUS_DIR/prometheus.yml --storage.tsdb.path=$PROMETHEUS_DIR/data --web.listen-address="0.0.0.0:$PROMETHEUS_WEB_PORT"
else
    echo "No $PROMETHEUS_DIR/prometheus.yml file, not starting prometheus server"
fi
