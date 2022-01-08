#!/usr/bin/env bash

set -eo pipefail

# import the deployment helpers
. $(dirname $0)/common.sh

# Deploy.
Interval=1
CounterAddr=$(deploy Counter $Interval)
log "Counter deployed at:" $CounterAddr
