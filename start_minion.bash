#!/bin/bash

# This function will launch a consul instance and try to connect to
# a provided cluster
function launchConsul {
    docker run -p 8301:8301 consul agent -dev -retry-join=$MASTER_IP
    echo 'success'
}


function main {
    echo 'launching consul in development mode'
    launchConsul
}

main
