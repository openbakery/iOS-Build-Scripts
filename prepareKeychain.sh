#!/bin/sh

function fail {
    echo "$*" >&2
    exit 1
}

function section_print {
    echo "\n=== $* ==="
}


CURL_CMD="curl -# -C - -o"


if [ -n "$PROVISIONING_URL" ] && [ -n "$PROVISIONING" ] && [ -n "$CERTIFICATES_PASSWORD" ]
then
	
	if [ -z "$KEYCHAIN_PASSWORD" ]; then
		KEYCHAIN_PASSWORD="thisisalongpasswordforthekeychain"
	fi

	section_print "Get Mobile Provisioning Profile"

	mkdir -p `dirname $PROVISIONING`

	$CURL_CMD $PROVISIONING.mobileprovision ${PROVISIONING_URL}/$PROVISIONING.mobileprovision
	
	if [ $? > 0 ]; then 
		fail "${PROVISIONING_URL}/$PROVISIONING.mobileprovision not found"
	fi
	
	$CURL_CMD $PROVISIONING.p12 ${PROVISIONING_URL}/$PROVISIONING.p12

	if [ $? > 0 ]; then 
		fail "${PROVISIONING_URL}/$PROVISIONING.p12 not found"
	fi

	# find the uuid in the provisioning profile
	UUID=`cat $PROVISIONING.mobileprovision | awk '/\<key\>UUID\<\/key\>/,/<\string\>.*\<\/string\>/' | tail -n1 | cut -f2 -d">"|cut -f1 -d"<"`

	#echo "UUID=$UUID"

	mkdir -p ~/Library/MobileDevice/"Provisioning Profiles"
	cp $PROVISIONING.mobileprovision ~/Library/MobileDevice/"Provisioning Profiles"/$UUID.mobileprovision

	section_print "Setup Keychain"

	KEYCHAIN_NAME=~/Library/Keychains/jenkins.keychain

	security delete-keychain "$KEYCHAIN_NAME"
	sleep 1
	security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"

	security default-keychain -s "$KEYCHAIN_NAME"
	# OD: following line is necessary if codesign also touches the login keychain, to avoid "user interaction not allowed"
	# workaround: specify --keychain in OTHER_CODE_SIGN_FLAGS
	security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_NAME

	section_print "Import Certificates to Keychain"
	security -v import $PROVISIONING.p12 -k $KEYCHAIN_NAME -P $CERTIFICATES_PASSWORD -T /usr/bin/codesign  

	security list-keychain 
	security show-keychain-info $KEYCHAIN_NAME
	

else
	section_print "No Signing is available in this build!"
fi



section_print "Keychain prepared"