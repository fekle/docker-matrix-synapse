#!/bin/bash
set -euf

# name and tags
name="fekle/matrix-synapse"
tags=("${name}:$(<VERSION)" "${name}:latest")

# allow to disable cache
if [[ "${aa:-}" == "nocache" ]]; then extra="--no-cache"; fi

# build
docker build --pull --tag ${tags[0]} --tag ${tags[1]} ${extra:-} .

# push
docker push ${tags[0]}
docker push ${tags[1]}
