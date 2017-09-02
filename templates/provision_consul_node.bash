#!/bin/bash

readonly CONSUL_VERSION='0.9.2'

function apt-get-install {
    apt-get clean
    sleep 10
    apt-get update
    sleep 10
    apt-get install -f -yq zip unzip
}

function open_firewall {
    ufw allow 8300
    ufw allow 8301
    ufw allow 8302
    ufw allow 8400
    ufw allow 8500
    ufw allow 8600
}

function downloadConsul {
    curl 'https://releases.hashicorp.com/consul/'$CONSUL_VERSION'/consul_'$CONSUL_VERSION'_linux_386.zip' > consul.zip
    ls
    unzip consul.zip
    chmod +x consul
    rm consul.zip
    mv consul /usr/local/bin
}

function setupConsulData {
    mkdir /consul-data
}

function launchConsul {
    systemctl enable consul.service
    systemctl start  consul.service
}

function main {
    set -x
    set -e
    apt-get-install
    open_firewall
    setupConsulData
    downloadConsul
    launchConsul
}

main
