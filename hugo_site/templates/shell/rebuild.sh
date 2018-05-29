#!/bin/bash

# Install Hugo

cd /tmp
wget https://github.com/spf13/hugo/releases/download/v${hugo_version}/hugo_${hugo_version}_Linux-64bit.tar.gz
tar -xzvf *.gz hugo
rm *.gz

# Clone content repository, install dependencies, rebuild site.

git clone --recursive ${git_repo} ${repo_dir}

# Do preprocessing.

${preprocess}

./hugo -s ${repo_dir} --theme=hugo-hcb-personal --baseURL=https://${site_name}/

# Do postprocessing.

${postprocess}

# Sync site to S3 bucket.

aws s3 sync --delete ${repo_dir}/public s3://${site_name}

# Shut down so the EC2 instance is terminated.

sudo halt