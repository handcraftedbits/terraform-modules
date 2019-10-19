#!/bin/bash

# Install dependencies, start Docker.

sudo yum install -y docker git
sudo service docker start

# Clone site and build.

git clone https://github.com/handcraftedbits/curtisshoward.com
cd curtisshoward.com
sudo bin/site build

# Copy to S3.

aws s3 sync --delete dist s3://curtisshoward.com

# Shutdown so EC2 will terminate the instance.

sudo halt
