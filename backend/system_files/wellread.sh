#!/bin/bash

# This script is used to start the wellread server
# Save it to /usr/local/sbin/wellread.sh
# Make it executable with chmod +x /usr/local/sbin/wellread.sh

cd /home/ubuntu/wellread2
python3 -m gunicorn backend.app:app \
	--bind 0.0.0.0:5000 \
	--timeout 3000 \
	--workers 1 \
	--log-file "-" \
	--access-logfile "-"
