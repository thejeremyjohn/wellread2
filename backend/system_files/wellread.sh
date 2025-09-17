#!/bin/bash

# This script is used to start the wellread server
# Save it to /usr/local/sbin/wellread.sh
# Make it executable with chmod +x /usr/local/sbin/wellread.sh

cd /home/ubuntu/wellread2
/home/ubuntu/miniconda3/envs/wellread/bin/python -m gunicorn backend.app:app \
	--bind 0.0.0.0:5000 \
	--timeout 3000 \
	--workers $(nproc --all | awk '{print $1*2+1}') \
	--log-file "-" \
	--access-logfile "-"
