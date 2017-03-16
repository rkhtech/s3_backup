#!/bin/bash

docker pull rkhtech/awscli
docker build -t rkhtech/s3backup .
