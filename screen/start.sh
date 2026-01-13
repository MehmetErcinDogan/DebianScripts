echo -e "Connecting to the phone\n";
ADB_DEVICES=$(adb devices | grep -w "device" | wc -l)

if [ $ADB_DEVICES -eq 0 ]; then
	echo -e "There are not any android devices\n"
	exit 1
fi

echo -e "Reversing Ports\n";
adb reverse tcp:1701 tcp:1701
adb reverse tcp:9001 tcp:9001

read -p "Enter access code:" access_code

ACCESS_CODE_ARG=""
if [ -n "$access_code" ]; then
    ACCESS_CODE_ARG="--access-code $access_code"
fi

echo -e "Starting Weylus. You can stop CTRL+C\n"

weylus --no-gui --try-nvenc --bind-address "127.0.0.1" $ACCESS_CODE_ARG &

timeout 1s scrcpy --start-app=com.opera.browser

