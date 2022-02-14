#!/bin/bash

tmp=$(mktemp)
YJ="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../bin/yj"
JQ="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../bin/jq"
$YJ -yj < config/crd/bases/rabbitmq.com_superstreamconsumers.yaml | $JQ 'delpaths([.. | paths(scalars)|select(contains(["spec","versions",0,"schema","openAPIV3Schema","properties","spec","properties","consumerPodSpec","description"]))])' | $YJ -jy > "$tmp"
mv "$tmp" config/crd/bases/rabbitmq.com_superstreamconsumers.yaml
