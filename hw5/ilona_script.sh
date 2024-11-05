#!/bin/bash

IMAGE_NAME="190119/my-nginx:latest"

docker pull $IMAGE_NAME

docker run -d -p 80:80 $IMAGE_NAME

echo "Script is finished..."
