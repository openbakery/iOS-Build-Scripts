#!/bin/sh

source common.sh

# check if hockeykit needs to be used
if [ $HOCKEYKIT ]; then

# creating release notes for HockeyKit (has to be added manually in build settings to be transferred to HockeyKit)
section_print "create release notes for hockeykit"

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

section_print "creating of hockeykit release notes fininshed"

fi