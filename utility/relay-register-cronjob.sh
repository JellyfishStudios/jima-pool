#!/bin/bash

######
##
## Script to generate cron job that will run topologyUpdater.sh every 33 minutes (after 4 hours we're registered) 
##
######

cat > $NODE_HOME/crontab-fragment.txt << EOF
33 * * * * ${NODE_HOME}/topologyUpdater.sh
EOF
crontab -l | cat - crontab-fragment.txt >crontab.txt && crontab crontab.txt
rm crontab-fragment.txt