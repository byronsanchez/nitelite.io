#!/usr/bin/env bash

docker run --init -it --rm -p 8080:8080 -p 35729:35729 -v ${pwd}/nitelite.io-web:/home/wintersmith/nitelite.io -m 300M --memory-swap 1G byronsanchez/nitelite.io $args

