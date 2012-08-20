#!/bin/sh

source common.sh

# check if hockeykit needs to be used
if [ $HOCKEYKIT ]; then

# creates the complete manifest for hockeykit
if [ $WORKING_DIRECTORY ]; then
  PROJECT_DIRECTORY=${WORKSPACE}/${WORKING_DIRECTORY}/build/${CONFIGURATION}-${SDK}
else
  PROJECT_DIRECTORY=${WORKSPACE}/build/${CONFIGURATION}-${SDK}
fi

section_print "create hockeykit manifest"

echo "PROJECT_DIRECTORY=$PROJECT_DIRECTORY"


if [ ! -d "$PROJECT_DIRECTORY" ]; then
    echo "No Release build found: $PROJECT_DIRECTORY"
    echo "Build Successful"
fi


APPLICATION_NAME=`ls -1 "$PROJECT_DIRECTORY" | grep ".*\.app$" | head -n1`
APPLICATION_NAME=${APPLICATION_NAME%.*}

IPA_FILE=${APPLICATION_NAME}.ipa

APP_DIRECTORY="${PROJECT_DIRECTORY}/${APPLICATION_NAME}.app"
BINARY_INFO_PLIST="${APP_DIRECTORY}/Info.plist"
INFO_PLIST=`cd "${PROJECT_DIRECTORY}" ; pwd`/Info

echo "INFO_PLIST: $INFO_PLIST"
echo "APP_DIRECTORY: $APP_DIRECTORY"
echo "BUILD_NUMBER: $BUILD_NUMBER"

plutil -convert xml1 "$BINARY_INFO_PLIST" -o "${INFO_PLIST}.plist"

BUNDLE_ID=$(defaults read "$INFO_PLIST" CFBundleIdentifier)

BUNDLE_VERSION=$(defaults read "$INFO_PLIST" CFBundleVersion)
BUNDLE_SHORT_VERSION=$(defaults read "$INFO_PLIST" CFBundleShortVersionString)

if [ -z "$BUNDLE_SHORT_VERSION" ]
then
	echo "No short version string found in Info.plist, assuming $BUNDLE_VERSION"
	BUNDLE_SHORT_VERSION="$BUNDLE_VERSION"
fi


if [ -z "$HOCKEY_KIT_APP_NAME" ]; 
then
  HOCKEY_KIT_APP_NAME="$JOB_NAME"
fi 

echo "Manifest App Title: $HOCKEY_KIT_APP_NAME"
echo "Writing Manifest to $PROJECT_DIRECTORY/${APPLICATION_NAME}.plist"

cat << EOF > "$PROJECT_DIRECTORY"/${APPLICATION_NAME}.plist
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
   <key>items</key>
   <array>
       <dict>
           <key>assets</key>
           <array>
               <dict>
                   <key>kind</key>
                   <string>software-package</string>
                   <key>url</key>
                   <string>__URL__</string>
               </dict>
           </array>
           <key>metadata</key>
           <dict>
               <key>bundle-identifier</key>
               <string>$BUNDLE_ID</string>
               <key>bundle-version</key>
               <string>$BUNDLE_VERSION</string>
               <key>kind</key>
               <string>software</string>
               <key>title</key>
               <string>$HOCKEY_KIT_APP_NAME</string>
               <key>subtitle</key>
               <string>$BUNDLE_SHORT_VERSION</string>
           </dict>
       </dict>
   </array>
</dict>
</plist>
EOF


BUNDLE_DIRECTORY="$PROJECT_DIRECTORY/$BUNDLE_ID"

echo "Building here:--$BUNDLE_DIRECTORY--$BUILD_NUMBER--"

mkdir -p "$BUNDLE_DIRECTORY/$BUILD_NUMBER"
echo mv "$PROJECT_DIRECTORY/${APPLICATION_NAME}.ipa" "$BUNDLE_DIRECTORY/$BUILD_NUMBER/${BUNDLE_ID}-${BUILD_ID}.ipa"
mv "$PROJECT_DIRECTORY/${APPLICATION_NAME}.ipa" "$BUNDLE_DIRECTORY/$BUILD_NUMBER/${BUNDLE_ID}-${BUILD_ID}.ipa"
echo mv "$PROJECT_DIRECTORY/${APPLICATION_NAME}.plist" "$BUNDLE_DIRECTORY/$BUILD_NUMBER/${BUNDLE_ID}-${BUILD_ID}.plist"
mv "$PROJECT_DIRECTORY/${APPLICATION_NAME}.plist" "$BUNDLE_DIRECTORY/$BUILD_NUMBER/${BUNDLE_ID}-${BUILD_ID}.plist"

rm -rf "${APP_DIRECTORY}"                                                                                                                                                                                                    
rm -rf "${APP_DIRECTORY}.dSYM"

rm "${INFO_PLIST}.plist"

echo "create hockeykit manifest finished"

fi
