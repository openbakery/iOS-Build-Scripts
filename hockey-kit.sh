
if [ $WORKING_DIRECTORY ]; then
  PROJECT_DIRECTORY=${WORKSPACE}/${WORKING_DIRECTORY}/build/${CONFIGURATION}-${SDK}
else
  PROJECT_DIRECTORY=${WORKSPACE}/build/${CONFIGURATION}-${SDK}
fi

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

plutil -convert xml1 "$BINARY_INFO_PLIST" -o "${INFO_PLIST}.plist"


bundle_version=$(defaults read "$INFO_PLIST" CFBundleVersion)
bundle_short_version=$(defaults read "$INFO_PLIST" CFBundleShortVersionString)
export BUNDLE_ID=$(defaults read "$INFO_PLIST" CFBundleIdentifier)


#ICON_SMALL=`defaults read "${INFO_PLIST}" CFBundleIconFiles | grep png | cut -f2 -d \" | head -n1`
#ICON_LARGE=`defaults read "${INFO_PLIST}" CFBundleIconFiles | grep png | cut -f2 -d \" | tail -n1`

ICON_SMALL=`/usr/libexec/PlistBuddy "${INFO_PLIST}.plist" -c "Print :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:0"`
ICON_LARGE=`/usr/libexec/PlistBuddy "${INFO_PLIST}.plist" -c "Print :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles:1"`

#echo "ICON_SMALL: $ICON_SMALL"
#echo "ICON_LARGE: $ICON_LARGE"

/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/pngcrush "${APP_DIRECTORY}/$ICON_SMALL" "${PROJECT_DIRECTORY}/$ICON_SMALL"
/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/pngcrush "${APP_DIRECTORY}/$ICON_LARGE" "${PROJECT_DIRECTORY}/$ICON_LARGE"

if [ ! "$HOCKE_KIT_APP_NAME" ]; then
  HOCKEY_KIT_APP_NAME=`$TARGET`
fi 

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
               <string>#$BUILD_NUMBER</string>
               <key>kind</key>
               <string>software</string>
               <key>title</key>
               <string>$HOCKEY_KIT_APP_NAME</string>
               <key>subtitle</key>
               <string>$bundle_short_version</string>
           </dict>
       </dict>
   </array>
</dict>
</plist>
EOF


BUNDLE_DIRECTORY="$PROJECT_DIRECTORY/$BUNDLE_ID"

echo $BUNDLE_DIRECTORY/$BUILD_NUMBER

mkdir -p "$BUNDLE_DIRECTORY/$BUILD_NUMBER"
mv "$PROJECT_DIRECTORY/${APPLICATION_NAME}.ipa" "$BUNDLE_DIRECTORY/$BUILD_NUMBER/${BUNDLE_ID}-${BUILD_ID}.ipa"
mv "$PROJECT_DIRECTORY/${APPLICATION_NAME}.plist" "$BUNDLE_DIRECTORY/$BUILD_NUMBER/${BUNDLE_ID}-${BUILD_ID}.plist"
mv "$PROJECT_DIRECTORY/${ICON_SMALL}" "$BUNDLE_DIRECTORY/"
mv "$PROJECT_DIRECTORY/${ICON_LARGE}" "$BUNDLE_DIRECTORY/"

rm -rf "${APP_DIRECTORY}"                                                                                                                                                                                                    
rm -rf "${APP_DIRECTORY}.dSYM"

rm "${INFO_PLIST}.plist"

# creating release notes for HockeyKit (has to be added manually in build settings to be transferred to HockeyKit)
echo "create release notes for HockeyKit"

if [ ! "$CHANGELOG" ]; then
  CHANGELOG="No changes."
fi 
  
cat << EOF > releasenotes.html
<!DOCTYPE HTML>
<html>
    <head>
        <meta charset="utf-8">
    </head>
    <body>
      $CHANGELOG
    </body>
</html>
EOF

echo "create manifest finished"
