#!/bin/bash

tmp=$(mktemp)
YJ="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../bin/yj"
$YJ -yj < config/crd/bases/rabbitmq.com_superstreamconsumers.yaml | jq 'delpaths([.. | paths(scalars)|select(contains(["spec","versions",0,"schema","openAPIV3Schema","properties","spec","properties","consumerPodSpec","description"]))])' | $YJ -jy > "$tmp"
mv "$tmp" config/crd/bases/rabbitmq.com_superstreamconsumers.yaml
