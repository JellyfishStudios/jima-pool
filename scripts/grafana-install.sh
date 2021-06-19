#!/bin/bash -xe

######
##
## Prometheus and Grafana Dashboard
##
######

sudo yum install -y prometheus-node-exporter 
sudo systemctl enable prometheus-node-exporter.service

if [ !$isBlockProducer ] 
then

# RELAY
sudo yum install -y prometheus prometheus-node-exporter

wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

echo "deb https://packages.grafana.com/oss/deb stable main" > grafana.list
sudo mv grafana.list /etc/apt/sources.list.d/grafana.list

sudo yum update && sudo yum install -y grafana

cat > prometheus.yml << EOF
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label job=<job_name> to any timeseries scraped from this config.
  - job_name: 'prometheus'

    static_configs:
      - targets: ['localhost:9100']
      - targets: ['10.0.2.5:9100']
      - targets: ['10.0.2.5:12798']
        labels:
          alias: 'block-producer-node'
          type:  'cardano-node'
      - targets: ['localhost:12798']
        labels:
          alias: 'relaynode'
          type:  'cardano-node'
EOF
sudo mv prometheus.yml /etc/prometheus/prometheus.yml

sudo systemctl enable grafana-server.service
sudo systemctl enable prometheus.service
sudo systemctl enable prometheus-node-exporter.service

fi
 
cd $NODE_HOME
sed -i ${NODE_CONFIG}-config.json -e "s/127.0.0.1/0.0.0.0/g"  