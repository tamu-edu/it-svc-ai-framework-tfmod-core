#!/usr/bin/env bash

set -e

eval "$(jq -r '@sh "WEBUI_TAG=\(.openwebui_image_tag) NEW_IMAGE_NAME=\(.new_image_name) ASSETS_DIR=\(.assets_dir) DOCKERFILE_LOCATION=\(.dockerfile_location)"')"

export WEBUI_TAG
echo "WEBUI_TAG: $WEBUI_TAG" 1>&2

export NEW_IMAGE_NAME
echo "NEW_IMAGE_NAME: $NEW_IMAGE_NAME" 1>&2

export ASSETS_DIR
echo "ASSETS_DIR: $ASSETS_DIR" 1>&2

export DOCKERFILE_LOCATION
echo "DOCKERFILE_LOCATION: $DOCKERFILE_LOCATION" 1>&2

cd "$DOCKERFILE_LOCATION"
docker compose build --build-arg WEBUI_TAG=$WEBUI_TAG 1>&2
if [ $? -ne 0 ]; then
  exit 1
fi

jq -n --arg image_name "${NEW_IMAGE_NAME}:${WEBUI_TAG}" '{"image_name":$image_name}'