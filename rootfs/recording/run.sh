#!/bin/bash

# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

if [[ ! -z "$WAITFOR_HOST" && ! -z "$WAITFOR_PORT" ]]; then
	for (( i=1; i<=${TIMEOUT:-120}; i++ )); do nc -zw1 $WAITFOR_HOST $WAITFOR_PORT && break || sleep 1; done
fi

SIGNALS='SIGHUP SIGINT SIGQUIT SIGTERM'
_terminating() {
	trap - $SIGNALS 

	if [[ -n "$FF_PID" ]]; then
		sleep ${FF_SHUTDOWN_GRACE:-3} &
		SLEEP_PID=$!
		echo Shutdown Firefox $FF_PID
		kill $FF_PID
	fi
	[[ -n "$XVFB_PID" ]] && kill $XVFB_PID
	pulseaudio --kill &>/dev/null

	wait $SLEEP_PID
	echo Terminated
}
trap _terminating $SIGNALS

set -xeo pipefail

SCREEN_WIDTH=${RECORDING_SCREEN_WIDTH:-'1280'}
SCREEN_HEIGHT=${RECORDING_SCREEN_HEIGHT:-'720'}
SCREEN_RESOLUTION=${SCREEN_WIDTH}x${SCREEN_HEIGHT}
COLOR_DEPTH=24
X_SERVER_NUM=1
S3_BUCKET_NAME=${RECORDING_ARTIFACTS_BUCKET}

# Start PulseAudio server so Firefox will have somewhere to which to send audio
pulseaudio -D --exit-idle-time=-1
pacmd load-module module-virtual-sink sink_name=v1  # Load a virtual sink as `v1`
pacmd set-default-sink v1  # Set the `v1` as the default sink device
pacmd set-default-source v1.monitor  # Set the monitor of the v1 sink to be the default source

# Start X11 virtual framebuffer so Firefox will have somewhere to draw
Xvfb :${X_SERVER_NUM} -ac -screen 0 ${SCREEN_RESOLUTION}x${COLOR_DEPTH} > /dev/null 2>&1 &
XVFB_PID=$!
export DISPLAY=:${X_SERVER_NUM}.0
sleep 0.5  # Ensure this has started before moving on

# Create a new Firefox profile for capturing preferences for this
firefox --no-remote --new-instance --createprofile "foo4 /opt/firefox"

# Set the Firefox preferences to enable automatic media playing with no user
# interaction and the use of the OpenH264 plugin.
cat <<EOF >> /opt/firefox/prefs.js
user_pref("media.autoplay.default", 0);
user_pref("media.autoplay.enabled.user-gestures-needed", false);
user_pref("media.navigator.permission.disabled", true);
user_pref("media.gmp-gmpopenh264.abi", "x86_64-gcc3");
user_pref("media.gmp-gmpopenh264.lastUpdate", 1571534329);
user_pref("media.gmp-gmpopenh264.version", "1.8.1.1");
user_pref("doh-rollout.doorhanger-shown", true);
user_pref("permissions.default.microphone", 1);
user_pref("permissions.default.camera", 1);
user_pref("media.devices.insecure.enabled", true);
user_pref("media.getusermedia.insecure.enabled", true);
user_pref("devtools.toolbox.selectedTool", "${FF_DEVTOOLS_TAB:-webconsole}");
user_pref("browser.sessionstore.interval", ${FF_SESSIONSTORE_INTERVAL:-15000});
EOF

# Start Firefox browser and point it at the URL we want to capture
#
# NB: The `--width` and `--height` arguments have to be very early in the
# argument list or else only a white screen will result in the capture for some
# reason.

firefox \
  -P foo4 \
  --width ${SCREEN_WIDTH} \
  --height ${SCREEN_HEIGHT} \
  --new-instance \
  --first-startup \
  --foreground \
  --kiosk \
  ${FF_DEVTOOLS_VISIBLE:+--devtools} \
  ${FF_JSCONSOLE_VISIBLE:+--jsconsole} \
  --ssb ${RECORDING_URL} \
  &

FF_PID=$!
echo Firefox PID $FF_PID
sleep 0.5  # Ensure this has started before moving on
xdotool mousemove 1 1 click 1  # Move mouse out of the way so it doesn't trigger the "pause" overlay on the video tile

[[ -z "$START_HASH" && -z "$STOP_HASH" && -z "$EXIT_HASH" ]] &&  
	exec node /recording/record.js ${S3_BUCKET_NAME} ${SCREEN_WIDTH} ${SCREEN_HEIGHT}

set +x

REC_PID=
SHUTTINGDOWN=

start() {
	[[ -n "$REC_PID" || -n "$SHUTTINGDOWN" ]] && return
	echo Start recording
	node /recording/record.js ${S3_BUCKET_NAME} ${SCREEN_WIDTH} ${SCREEN_HEIGHT} &
	REC_PID=$!
}
stop() {
	[[ -z "$REC_PID" ]] && return
	echo Stop recording $REC_PID
	kill -TERM $REC_PID
	wait $REC_PID
	REC_PID=
}
_shutdown() {
	trap - $SIGNALS

	echo Shutting down
	SHUTTINGDOWN=yes
	stop
	
	_terminating
}

trap _shutdown $SIGNALS

SESSION_FILE=/opt/firefox/sessionstore-backups/recovery.jsonlz4
for (( i=1; i<=60; i++ )); do [[ -f $SESSION_FILE || -n "$SHUTTINGDOWN" ]] && break || sleep 1; done
[[ ! -f $SESSION_FILE && -z "$SHUTTINGDOWN" ]] && echo Firefox session file $SESSION_FILE not found && exit 1

while [[ -z "$SHUTTINGDOWN" ]]; do
	sleep 1
	url=`lz4jsoncat $SESSION_FILE | jq -r '[.windows[].tabs[].entries[] | select( .url | contains("mozilla.org") | not )][0].url'`
	case $url in
		*#${START_HASH:-START})
			start
			;;
		*#${STOP_HASH:-STOP})
			stop
			;;
		*#${EXIT_HASH:-SHUTDOWN})
			_shutdown
			;;
	esac
done

