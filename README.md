# docker-webpage-recorder

A web page recorder using Firefox inside a container.

The initial code base is heavily borrowed from https://github.com/aws-samples/amazon-chime-sdk-recording-demo. Hence it inherits the Apache 2.0 license.

### How to run

Prepare `.env` file with the following:

	RECORDING_URL=https://the.website.to.record.com
	RECORDING_ARTIFACTS_BUCKET=s3-bucket-name
	AWS_ACCESS_KEY_ID=AWSACCESSKEYIDINHERE
	AWS_SECRET_ACCESS_KEY=ENTERTHEAWSSECRETACCESSKEYINTHISPOSITION

**Optional variables:**

| Variable                 | Description                                              | Default    |
| ------------------------ | -------------------------------------------------------- | ---------- |
| VIDEO_BITRATE            | Video bit rate of the recording                          | 3000       |
| VIDEO_FRAMERATE          | Number of frame per second of the recording              | 30         |
| AUDIO_BITRATE            | Audio bit rate of the recording                          | 160k       |
| AUDIO_SAMPLERATE         | Audio sample rate of the recording                       | 44100      |
| AUDIO_CHANNELS           | Number of audio channels of the recording                | 2          |
| AUDIO_DELAY              | Delay audio channels if it's out-of-sync with video (ms) | 0          |
| FF_JSCONSOLE_VISIBLE     | Pass `--jsconsole` argument to Firefox launch if not empty | `empty`     |
| FF_DEVTOOLS_VISIBLE      | Pass `--devtools` argument to Firefox launch if not empty  | `empty`     |
| FF_DEVTOOLS_TAB          | Set default tab in Dev Tools                             | webconsole |
| FF_SESSIONSTORE_INTERVAL | How often session information is stored to profile (ms)  | 15000      |
| START_HASH               | if defined, start new recording when URL hash matched    | `empty`     |
| STOP_HASH                | if defined, stop current recording when URL hash matched | `empty`     |
| EXIT_HASH                | if defined, exit the container when URL hash matched     | `empty`     |
| tag_*                    | tags to be associated with recording object (max 10)     | N/A        |

**Required actions on the bucket:**

	s3:GetObject
	s3:PutObject
	s3:PutObjectTagging
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
	  t7tran/webpage-recorder:1.2

To stop recording, run the following in another terminal:

	docker stop recording