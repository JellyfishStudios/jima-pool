#!/bin/bash -xe

######
##
## Cardano Node, CLI & Dependencies installation
##
######

# Installing dependent libs
sudo yum install git gcc gcc-c++ tmux gmp-devel make tar xz wget zlib-devel libtool autoconf -y
sudo yum install systemd-devel ncurses-devel ncurses-compat-libs -y

# Installing libsoldium from source
mkdir $HOME/git
cd $HOME/git
git clone https://github.com/input-output-hk/libsodium
cd libsodium
git checkout 66f017f1
./autogen.sh
./configure
make
sudo make install

# For some reason, systemctl will fail to load libsodium from LD_LIBRARY_PATH
# Ref: https://forum.cardano.org/t/error-while-loading-shared-libraries-libsodium-so-23/55495/5
sudo ln -s /usr/local/lib/libsodium.so.23 /lib64/libsodium.so.23

export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

# Installing GHCup (GHC install manager)
cd $HOME
wget https://downloads.haskell.org/~ghcup/x86_64-linux-ghcup 
chmod 777 x86_64-linux-ghcup
sudo mv x86_64-linux-ghcup /usr/local/bin/ghcup
export PATH="$HOME/.cabal/bin:$HOME/.ghcup/bin:$PATH"
source .bashrc

# Installing Cabal
ghcup upgrade
ghcup install cabal 3.4.0.0
ghcup set cabal 3.4.0.0

# Installing GHC
ghcup install ghc 8.10.4
ghcup set ghc 8.10.4

# Updating cabal and verifying the correct versions were installed successfully.
cabal update
cabal --version
ghc --version

# Updating PATH to include Cabal and GHC and add exports
echo PATH="$HOME/.local/bin:$PATH" >> $HOME/.bashrc
echo export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" >> $HOME/.bashrc
echo export NODE_HOME=$HOME/cardano-my-node >> $HOME/.bashrc
echo export NODE_CONFIG=mainnet>> $HOME/.bashrc
echo export NODE_BUILD_NUM=$(curl https://hydra.iohk.io/job/Cardano/iohk-nix/cardano-deployment/latest-finished/download/1/index.html | grep -e "build" | sed 's/.*build\/\([0-9]*\)\/download.*/\1/g') >> $HOME/.bashrc
source $HOME/.bashrc

# Download source code and switch to the latest tag.
cd $HOME/git
git clone https://github.com/input-output-hk/cardano-node.git
cd cardano-node
git fetch --all --recurse-submodules --tags
git checkout tags/1.26.2

# Configure build options
cabal configure -O0 -w ghc-8.10.4

# Update the cabal config, project settings, and reset build folder.
echo -e "package cardano-crypto-praos\n flags: -external-libsodium-vrf" > cabal.project.local
sed -i $HOME/.cabal/config -e "s/overwrite-policy:/overwrite-policy: always/g"
rm -rf $HOME/git/cardano-node/dist-newstyle/build/x86_64-linux/ghc-8.10.4

# Build the cardano-node from source code.
cabal build cardano-cli cardano-node

# Copy cardano-cli and cardano-node files into bin directory.
sudo cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-cli") /usr/local/bin/cardano-cli
sudo cp $(find $HOME/git/cardano-node/dist-newstyle/build -type f -name "cardano-node") /usr/local/bin/cardano-node

# Verify cardano-cli and cardano-node are the expected versions.
cardano-node version
cardano-cli version

# Somewhere to store our utility scripts
mkdir $NODE_HOME

# Install gLiveView (a 'gui' for your node!)
cd $NODE_HOME
sudo yum install jq -y
sudo yum install tcptraceroute -y
curl -s -o gLiveView.sh https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/gLiveView.sh
curl -s -o env https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/env
chmod 755 gLiveView.sh

######
##
## Cardano Node configuration
##
######

# Grab the config.json, genesis.json, and topology.json files needed to configure the node.
cd $NODE_HOME
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-byron-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-topology.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-shelley-genesis.json
wget -N https://hydra.iohk.io/build/${NODE_BUILD_NUM}/download/1/${NODE_CONFIG}-config.json

# Run the following to modify mainnet-config.json and update TraceBlockFetchDecisions to "true"
sed -i ${NODE_CONFIG}-config.json \
    -e "s/TraceBlockFetchDecisions\": false/TraceBlockFetchDecisions\": true/g"

# Update .bashrc shell variables.
echo export CARDANO_NODE_SOCKET_PATH="$NODE_HOME/db/socket" >> $HOME/.bashrc
source $HOME/.bashrc

# Node startup script
cat > $NODE_HOME/startNode.sh << EOF 
#!/bin/bash
DIRECTORY=$NODE_HOME
PORT=6000
HOSTADDR=0.0.0.0
TOPOLOGY=\${DIRECTORY}/${NODE_CONFIG}-topology.json
DB_PATH=\${DIRECTORY}/db
SOCKET_PATH=\${DIRECTORY}/db/socket
CONFIG=\${DIRECTORY}/${NODE_CONFIG}-config.json
/usr/local/bin/cardano-node run --topology \${TOPOLOGY} --database-path \${DB_PATH} --socket-path \${SOCKET_PATH} --host-addr \${HOSTADDR} --port \${PORT} --config \${CONFIG}
EOF

chmod +x $NODE_HOME/startNode.sh 

# Create a systemd unit file to define yourcardano-node.service configuration.
cat > $NODE_HOME/cardano-node.service << EOF 
# The Cardano node service (part of systemd)
# file: /etc/systemd/system/cardano-node.service 

[Unit]
Description     = Cardano node service
Wants           = network-online.target
After           = network-online.target 

[Service]
User            = ${USER}
Type            = simple
WorkingDirectory= ${NODE_HOME}
ExecStart       = /bin/bash -c '${NODE_HOME}/startNode.sh'
KillSignal=SIGINT
RestartKillSignal=SIGINT
TimeoutStopSec=2
LimitNOFILE=32768
Restart=always
RestartSec=5
SyslogIdentifier=cardano-node

[Install]
WantedBy	= multi-user.target
EOF

sed -i env \
    -e "s/\#CONFIG=\"\${CNODE_HOME}\/files\/config.json\"/CONFIG=\"\${NODE_HOME}\/mainnet-config.json\"/g" \
    -e "s/\#SOCKET=\"\${CNODE_HOME}\/sockets\/node0.socket\"/SOCKET=\"\${NODE_HOME}\/db\/socket\"/g"

# Deploy the systemd script
sudo mv $NODE_HOME/cardano-node.service /etc/systemd/system/cardano-node.service
sudo chmod 644 /etc/systemd/system/cardano-node.service

# Enable the new service
sudo systemctl daemon-reload
sudo systemctl enable cardano-node
