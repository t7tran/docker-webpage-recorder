# docker-webpage-recorder

A web page recorder using Firefox inside a container.

The initial code base is heavily borrowed from https://github.com/aws-samples/amazon-chime-sdk-recording-demo. Hence it inherits the Apache 2.0 license.

### How to run

Prepare `.env` file with the following:

	MEETING_URL=https://the.website.to.record.com
	RECORDING_ARTIFACTS_BUCKET=s3-bucket-name
	AWS_ACCESS_KEY_ID=AWSACCESSKEYIDINHERE
	AWS_SECRET_ACCESS_KEY=ENTERTHEAWSSECRETACCESSKEYINTHISPOSITION

Required actions on the bucket:

	s3:GetObject
	s3:PutObject
	s3:CreateMultipartUpload
	s3:AbortMultipartUpload
	s3:CompleteMultipartUpload
	s3:UploadPart

If the bucket has encryption with a custom master key, `kms:Decrypt` and `kms:GenerateDataKey*` actions on the key are required.

See https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuAndPermissions.html.

Then start recording:

	docker run --name recording -it --rm \
	  --env-file .env \
	  --shm-size=1g \
	  -v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket \
	  coolersport/webpage-recorder:1.1

To stop recording, run the following in another terminal:

	docker stop recording