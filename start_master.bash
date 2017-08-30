#!/bin/bash

# This function will launch a consul instance and try to connect to
# a provided cluster
function launchConsul {
    docker run -p 8301:8301 -d consul agent -dev -bind $MASTER_IP -node consul-server
    echo 'success'
}


function main {
    echo 'launching consul in development mode'
    launchConsul
}

main
