#!/bin/bash

######
##
## Script to fetch relay node buddies and update the topology file (run when registered - after 4 hours) 
##
######

BLOCKPRODUCING_IP=10.0.2.5
BLOCKPRODUCING_PORT=6000
curl -s -o $NODE_HOME/${NODE_CONFIG}-topology.json "https://api.clio.one/htopology/v1/fetch/?max=20&customPeers=\${BLOCKPRODUCING_IP}:\${BLOCKPRODUCING_PORT}:1|relays-new.cardano-mainnet.iohk.io:3001:2"