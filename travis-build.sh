#!/bin/bash

set -e 

#
# Development build and tests
#

# bioplatforms-composer runs as this UID, and needs to be able to
# create output directories within it
mkdir -p data/
sudo chown 1000:1000 data/

./develop.sh build latest
./develop.sh skeleton
./develop.sh build latest
