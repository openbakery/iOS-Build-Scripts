curl -L -C - -o scripts.zip https://github.com/openbakery/iOS-Build-Scripts/zipball/master
unzip -j scripts.zip

chmod +x *.sh
./prepareKeychain.sh %@  || { echo "bootstrap failed"; exit 1; } 
./xcode-build.sh %@ || { echo "xcode-build failed"; exit 1; } 
./hockey-kit.sh %@  || { echo "hockey-kit failed"; exit 1; } 
./hockeyimage.sh -o build/Icon.png %@ || { echo "hockeyimage failed"; exit 1; } 
./cleanupKeychain.sh %@ || { echo "cleanup failed"; exit 1; }