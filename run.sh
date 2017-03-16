#!/bin/bash

aws_key=$(aws-get-key)
aws_secret=$(aws-get-secret)

docker rm -f s3backup
docker run -d --name s3backup \
	-e S3_BUCKET=s3rkh \
	-e S3_PREFIX=s3backup-test \
	-e BACKUP_PATH=/bin \
	-e BACKUP_START_HOUR_UTC=18 \
	-e AWS_ACCESS_KEY_ID=$aws_key \
	-e AWS_SECRET_ACCESS_KEY=$aws_secret \
	-e AWS_DEFAULT_REGION=us-west-2 \
	-e HELLO=world \
	rkhtech/s3backup

