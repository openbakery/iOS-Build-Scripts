#!/bin/sh

chmod +x *.sh
./keychain-prepare.sh %@  || { echo "prepare keychain failed"; exit 1; } 
./xcode-build.sh %@ || { echo "xcode-build failed"; exit 1; } 
./hockeykit-manifest.sh %@  || { echo "creating hockeykit manifest failed"; exit 1; } 
./hockeykit-image.sh -o build/Icon.png %@ || { echo "hockeyimage failed"; exit 1; } 
./hockeykit-releasenotes.sh %@ || { echo "creating hockeykit releasenotes failed"; exit 1; }
./keychain-cleanup.sh %@ || { echo "cleanup keychain failed"; exit 1; }