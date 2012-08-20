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

echo "creating of release notes fininshed"