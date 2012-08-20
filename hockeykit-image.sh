#!/bin/sh

echo $@

# Gets the icon file names from specified Info.plist, uncrushes them and finds
# the best one to use for HockeyKit server. If none with 114x114 exist then
# the next higher resolution one is resized appropriately
# (c)2012 Cocoanetics

# defaults
OUTPUT_FILE=""
WORKING_DIR=${WORKSPACE}

USAGE="Usage: hockeyimage.sh -p <Info.plist> -o <Output Image> [-w <Working Dir>]\n"

# check the parameters
while getopts "p:o:w:h" opt; do
    case $opt in
	    p)
			INFO_PLIST="$OPTARG";;
    
	    o)
			OUTPUT_FILE="$OPTARG";;

        w)
            WORKING_DIR="$OPTARG";;

 		h)  echo $USAGE
			exit 0;;
			
		\? ) echo $USAGE
			exit 1;;
    esac
done

if [ -d "$WORKING_DIR" ]
then
	echo "Work Space: $WORKING_DIR"
	cd "$WORKING_DIR"
fi

if [ -z "$OUTPUT_FILE" ]
then
	echo "Assuming HockeyIcon.png as output file name"
	OUTPUT_FILE="HockeyIcon.png"
fi

if [ -z "$INFO_PLIST" ]
then
    echo "No Info.plist specified, aborting."
    exit 1
fi

if [ ! -f "$INFO_PLIST" ]
then
    echo "No file found at $INFO_PLIST"
    exit 1
fi

# retrieve the names of the icons  
CFBUNDLEICONFILES=`/usr/libexec/PlistBuddy $INFO_PLIST -c "Print :CFBundleIconFiles" -c "Print :CFBundleIcons:CFBundlePrimaryIcon:CFBundleIconFiles" | grep -v "{" | grep -v "}" | sed -e "s/^[ ]*//g" | sort -u`

# make tmp dir
WORK_DIR=$TMPDIR/$$
mkdir $WORK_DIR
ICON_SIZES_LIST="$WORK_DIR/icons.txt"

for FILE in $CFBUNDLEICONFILES
do
	echo "Checking $FILE"
	
	if [ -f $FILE ]
	then
		# uncrush
		xcrun -sdk iphoneos pngcrush -dir $WORK_DIR -revert-iphone-optimizations -q $FILE
	
		UNCRUSHED_FILE=$WORK_DIR/$FILE
	
		IMAGE_WIDTH=`/usr/bin/sips --getProperty pixelWidth $UNCRUSHED_FILE | cut -f2 -d":"`
		echo $FILE $IMAGE_WIDTH >> "$ICON_SIZES_LIST"	
	else
		echo "Warning, referenced icon file $FILE does not exist"
	fi
done

# sort the icons by width (column 3)
SORTED_SIZES=`cat $ICON_SIZES_LIST | sort -k3 -n -t" " | sed -e "s/ /|/g"`

SUCCESS=0

for FILE in $SORTED_SIZES
do
	IMAGE_NAME=`echo $FILE | cut -f1 -d"|"`
	IMAGE_PATH=`echo $FILE | cut -f2 -d"|"`
	IMAGE_WIDTH=`echo $FILE | cut -f3 -d"|"`

	# first icon with a width >= 114 is chosen
	if [ $IMAGE_WIDTH -ge 114 ]
	then
		echo "Found $IMAGE_NAME with width $IMAGE_WIDTH"
		
		if [ $IMAGE_WIDTH -eq 114 ]
		then
			echo "$IMAGE_NAME has needed size, copying to output"
			cp $IMAGE_PATH $OUTPUT_FILE
			SUCCESS=1
			break
		else
			echo "$IMAGE_NAME has width $IMAGE_WIDTH, resampling to 114"
			/usr/bin/sips --resampleWidth 200 $IMAGE_PATH --out $IMAGE_PATH.new.png > /dev/null
			cp $IMAGE_PATH.new.png $OUTPUT_FILE
			SUCCESS=1
			break
		fi
	fi
done

if [ $SUCCESS -eq 0 ]
then
	echo "Unable to find suitable candidate icon, aborting"
	exit 1
fi

# clean up
rm -rf $WORK_DIR
