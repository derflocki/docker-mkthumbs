#!/bin/bash
#to get all file-types
#find -type f -exec basename {} \; | awk -F . '{print $NF}' | tr '[A-Z]' '[a-z]' | sort | uniq
BC=$(which bc)
if [ -z "$BC" ] ; then
	echo "bc is not installed"
	exit 1
fi

FFMPEG=$(which ffmpeg)
if [ -z "$FFMPEG" ] ; then
	echo "ffmpeg is not installed"
	exit 1
fi
FFPROBE=$(which ffprobe)
if [ -z "$FFPROBE" ] ; then
	echo "ffprobe is not installed"
	exit 1
fi
MOGRIFY=$(which mogrify)
if [ -z "$MOGRIFY" ] ; then
	echo "mogrify is not installed"
	exit 1
fi
dir=/videos
FILES=$(find "$@" -type f | grep -E -i "(3gp|avi|divx|flv|m4v|mkv|mp4|mpeg|mpg|ogm|ogv|wmv)$" | sort)
IFS='
'
for f in $FILES
do :
	echo $f
	dst="$f.jpg"
	if [ -e "$dst" ]; then
		echo "dst exists"
		echo "" > /dev/null
	else
		echo $f
		#check for a nfo with an image link
		nfo=${f%.*}".nfo"
		#echo "nfo "$nfo
		notdownloaded=1
		if [ -e $nfo ]; then
			echo "nfo exists"
			urls=$(cat $nfo | grep '<image' | cut -d '>' -f 2 | cut -d '<' -f 1)
			for url in $urls
			do :
				wget --quiet $url -O $dst"-orig" && notdownloaded="" && convert "$dst-orig" -resize 320x320 "$dst" && rm $dst"-orig" ; break
			done
		fi
		if [ $notdownloaded ]; then

			ffprobe=$($FFPROBE -show_files 2>/dev/null "$f")
			duration=$(ffprobe "$f" 2>&1 | grep Duration | awk '{print $2}' | tr -d ,)
			POS=$(echo -e "$ffprobe" | grep -m 1 "duration" | echo "scale=0; $(cut -d= -f2)/2" | $BC -l 2>/dev/null)
			if [ -z "$POS" ]; then
				POS=90
			fi
			if [ -n "$POS" ]; then
				#echo "DST "$dst
				echo $FFMPEG -y -ss "$POS" -i "$f" -vcodec mjpeg -pix_fmt yuvj420p -vframes 1 -an -f rawvideo "$dst" 2>/dev/null
				$FFMPEG -y -ss "$POS" -i "$f" -vcodec mjpeg -pix_fmt yuvj420p -vframes 1 -an -f rawvideo "$dst" && $MOGRIFY -resize 320x320 $dst
			fi
		fi
	fi
done
