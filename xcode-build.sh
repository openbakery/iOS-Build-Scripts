#!/bin/sh


function fail {
    echo "$*" >&2
    exit 1
}

function section_print {
    echo "\n=== $* ==="
}

function xcode_build {
	BUILD_DIRECTORY=${WORKSPACE}/build
	
	echo xcodebuild -configuration "$CONFIGURATION" -sdk "$SDK" -target "$TARGET" DSTROOT="${BUILD_DIRECTORY}" OBJROOT="${BUILD_DIRECTORY}/objects" SYMROOT="${BUILD_DIRECTORY}" SHARED_PRECOMPS_DIR="${BUILD_DIRECTORY}/shared" "$*" || fail "xcodebuild failed" 
	#xcodebuild -configuration "$CONFIGURATION" -sdk "$SDK" -target "$TARGET" DSTROOT="${BUILD_DIRECTORY}" OBJROOT="${BUILD_DIRECTORY}/objects" SYMROOT="${BUILD_DIRECTORY}" SHARED_PRECOMPS_DIR="${BUILD_DIRECTORY}/shared" OTHER_CODE_SIGN_FLAGS="--keychain /Users/groundkeeper/Library/Keychains/jenkins.keychain" "$*" || fail "xcodebuild failed" 
	xcodebuild -configuration "$CONFIGURATION" -sdk "$SDK" -target "$TARGET" DSTROOT="${BUILD_DIRECTORY}" OBJROOT="${BUILD_DIRECTORY}/objects" SYMROOT="${BUILD_DIRECTORY}" SHARED_PRECOMPS_DIR="${BUILD_DIRECTORY}/shared" "$*" || fail "xcodebuild failed" 
}

if [ -z "$CONFIGURATION" ]; then
	fail "Configration ERROR: CONFIGURATION missing"
	exit 1
fi


if [ -z "$SDK" ]; then
    fail "Configration ERROR: No SDK specified"
    exit 1
fi

if [ -z "$TARGET" ]; then
    fail "Configration ERROR: No TARGET specified"
    exit 1
fi

#echo $WORKING_DIRECTORY;

if [ $WORKING_DIRECTORY ]; then
  echo cd ${WORKING_DIRECTORY}
  cd ${WORKING_DIRECTORY}
fi


section_print "Building $CONFIGURATION using sdk $SDK"

#strange way to force backslash
if [ $PROJECT_DIRECTORY ]; then
    PROJECT_DIRECTORY=${PROJECT_DIRECTORY%/}
    PROJECT_DIRECTORY="$PROJECT_DIRECTORY/"

    section_print "Project Directory is specified and is $PROJECT_DIRECTORY"
    cd "$PROJECT_DIRECTORY" || fail "no directory $PROJECT_DIRECTORY"
    pwd
fi

if [ -z "$INFO_PLIST" ]; then
    INFO_PLIST=`ls *Info.plist | head -n1`
fi

INFO_PLIST=`cd "${PROJECT_DIRECTORY}" ; pwd`/${INFO_PLIST%.*}


#section_print "Cleaning up previous build"
#xcode_build clean
#rm -rf "${WORKSPACE}/build"


# Modify the bundle identifier (only in build configuration Debug and bundle identifier has to be set)
if [ $CONFIGURATION = "Debug" ] && [ "$BUNDLE_IDENTIFIER" ]; then
    section_print "Setting Bundle Identifer to $BUNDLE_IDENTIFIER"
    
    # modify bundle identifier
    /usr/libexec/PlistBuddy "$INFO_PLIST.plist" -c "Set :CFBundleIdentifier $BUNDLE_IDENTIFIER"
    
    plutil -convert xml1 "$INFO_PLIST".plist
fi

# Modify bundle version for Hockey Kit builds in build configuration Debug
if [ $CONFIGURATION = "Debug" ]; then
  section_print "Setting build number to bundle version for HockeyKit builds"

  BUNDLE_VERSION=`/usr/libexec/PlistBuddy "$INFO_PLIST.plist" -c "Print :CFBundleVersion"`
  /usr/libexec/PlistBuddy "$INFO_PLIST.plist" -c "Set :CFBundleVersion #$BUILD_NUMBER"
fi

section_print "Building $CONFIGURATION"

if [ -n "$PROVISIONING" ] && [ -n "$SIGN_IDENTITY" ]; then
	BUILD_PARAMETERS="${BUILD_PARAMETERS} CODE_SIGN_IDENTITY=$SIGN_IDENTITY"
fi

if [ -n "$XCODE_SETTINGS" ]; then
	BUILD_PARAMETERS="${BUILD_PARAMETERS} $XCODE_SETTINGS"
fi 

xcode_build "${BUILD_PARAMETERS}"

#xcodebuild -sdk iphonesimulator -configuration ELO-DMS -target UnitTests TEST_AFTER_BUILD=YES

section_print "Packaging ipa"


PROJECT_DIRECTORY=${WORKSPACE}/build/${CONFIGURATION}-${SDK}

if [ ! -d "$PROJECT_DIRECTORY" ]; then
    echo "No Release build found: $PROJECT_DIRECTORY"
    section_print "Build Successful"
    exit
fi

#printenv


APPLICATION_NAME=`ls -1 "$PROJECT_DIRECTORY" | grep ".*\.app$" | head -n1`
APPLICATION_NAME=${APPLICATION_NAME%.*}

export CODESIGN_ALLOCATE="/Applications/Xcode.app/Contents/Developer/usr/bin/codesign_allocate"

if [ -n "$PROVISIONING" ] && [ -n "$PROVISIONING_URL" ] && [ -n "$SIGN_IDENTITY" ]; then
	section_print "Sign the Application"
	xcrun -sdk "$SDK" PackageApplication -v "${PROJECT_DIRECTORY}/${APPLICATION_NAME}.app" -o "${PROJECT_DIRECTORY}/${APPLICATION_NAME}.ipa" --sign "${SIGN_IDENTITY}" --embed "${PROVISIONING}.mobileprovision"
else
  section_print "SIGN SKIPPED because PROVISIONING or SIGN_IDENTITY are not configured properly"
  exit
fi


if [ -z "$VERSION_NUMBER" ]; then
    APPLICATION_ID=${APPLICATION_NAME}-${BUILD_ID};
else
    APPLICATION_ID=${APPLICATION_NAME}-${VERSION_NUMBER};
fi
    
mv "${PROJECT_DIRECTORY}/${APPLICATION_NAME}.app" "${PROJECT_DIRECTORY}/${APPLICATION_ID}.app"
mv "${PROJECT_DIRECTORY}/${APPLICATION_NAME}.app.dSYM" "${PROJECT_DIRECTORY}/${APPLICATION_ID}.app.dSYM"
mv "${PROJECT_DIRECTORY}/${APPLICATION_NAME}.ipa" "${PROJECT_DIRECTORY}/${APPLICATION_ID}.ipa"

cd "${PROJECT_DIRECTORY}"
zip -r "${APPLICATION_ID}.zip" . -i "${APPLICATION_ID}.app*"


section_print "Build Successful"

