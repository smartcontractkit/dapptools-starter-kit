#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
# Currently hardcoded for kovan
PriceFeedConsumerAddr=$(deploy PriceFeedConsumer 0x9326BFA02ADD2366b30bacB125260Af641031331)
log "PriceFeedConsumer deployed at:" $PriceFeedConsumerAddr
