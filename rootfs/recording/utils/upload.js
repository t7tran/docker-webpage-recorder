// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

const AWS = require('aws-sdk');

/**
 * S3Upload Class
 * Upload a recording artifact to S3
 */
class S3Uploader {
    /**
     * @constructor
     * @param {*} bucket - the S3 bucket name uploaded to
     * @param {*} key - the file name in S3 bucket
     */
    constructor(bucket, key) {
        this.bucket = bucket;
        this.key = key;
        this.s3Uploader = new AWS.S3({ params: { Bucket: bucket, Key: key } });
        console.log(`[upload process] constructed an S3 object at: s3://${this.bucket}/${this.key}`);
    }

    uploadStream(stream, tags) {
        const managedUpload = this.s3Uploader.upload({ Body: stream }, { tags }, (err, data) => {
            if (err) {
                console.error('[stream upload process] failure - error handling on failure', err);
            } else {
                console.log(`[stream upload process] success - uploaded the file to: ${data.Location}`);
                process.exit();
            }
        });
        managedUpload.on('httpUploadProgress', function (event) {
            console.log(`[stream upload process] uploaded ${event.loaded} bytes`);
        });
    }
}

module.exports = {
    S3Uploader
};