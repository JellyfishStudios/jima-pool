#!/bin/bash -xe

sudo systemctl restart grafana-server.service
sudo systemctl restart prometheus.service