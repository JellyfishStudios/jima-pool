
#!/bin/bash -xe

# BLOCK PRODUCER topology configuration
cat > $NODE_HOME/${NODE_CONFIG}-topology.json << EOF 
 {
    "Producers": [
      {
        "addr": "10.0.1.5",
        "port": 6000,
        "valency": 1
      }
    ]
  } 
EOF