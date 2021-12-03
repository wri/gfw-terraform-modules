{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:ListBucket", "s3:PutBucketLifecycleConfiguration"],
            "Resource": "${bucket_arn}"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*Object",
            "Resource": [
                "${bucket_arn}/${prefix}*"
            ]
        }
    ]
}