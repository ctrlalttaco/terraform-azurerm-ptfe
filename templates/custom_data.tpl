#!/usr/bin/env bash
set -x

curl -o install.sh https://install.terraform.io/ptfe/stable
bash ./install.sh \
    no-proxy \
    private-address=${lb_private_ip_address} \
    public-address=${lb_private_ip_address}
