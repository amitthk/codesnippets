#!/bin/bash
# Update /etc/passwd to support arbitrary user IDs
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /home/appadmin/passwd.template > /tmp/passwd
export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/etc/group

# Check if AWS credentials are provided
if [[ -n "$AWS_ACCESS_KEY_ID" && -n "$AWS_SECRET_ACCESS_KEY" ]]; then
    # Configure AWS CLI
    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
    aws configure set default.region $AWS_REGION
    
    # Download the artifact from AWS S3
    if [[ -n "$S3_BUCKET" && -n "$S3_OBJECT" ]]; then
        echo "Downloading $S3_OBJECT from S3 bucket $S3_BUCKET..."
        aws s3 cp s3://$S3_BUCKET/$S3_OBJECT /workspace --region $AWS_REGION
        
        # Set permissions for downloaded jar file
        if [[ -f "/workspace/$S3_OBJECT" ]]; then
            chmod 755 "/workspace/$S3_OBJECT"
            echo "Downloaded and set permissions for $S3_OBJECT"
        else
            echo "Warning: Failed to download $S3_OBJECT"
        fi
    else
        echo "Warning: S3_BUCKET and/or S3_OBJECT not specified"
    fi
else
    echo "Warning: AWS credentials not provided"
fi

# Execute the run.sh script with any arguments passed to this script
exec "$@"
