#!/bin/bash

# For security
INDIR=/tmp/uploads
OUTDIR=/tmp/uploads/previews

# chmod of file && dir
CHMOD=0777

create_preview() {
    #echo -n "Processing"

    INFILE=$INDIR/$1
    OUTFILE=$OUTDIR/$1
    # check file exists
    if [ ! -f "$INFILE" -o -e "$OUTFILE" ]; then
      echo "File $INFILE not exists. Or $OUTFILE was processed" >&2
      return 1;
    fi  

    # check dirs
    # ../../../../etc/passwd
    _filepath=$(cd -P -- `dirname -- $INFILE` && pwd -P)/$(basename $INFILE)
    _filepath=$(echo $_filepath | sed "s#^${INDIR}[/]*##g")

    INFILE="$INDIR/$_filepath"
    OUTFILE="$OUTDIR/$_filepath"

    if [ ! -f "$INFILE" -o -e "$OUTFILE" ]; then
      echo "File $INFILE not exists. Or $OUTFILE was processed" >&2
      return 1;
    fi  

    # create preview directory
    [ -d `dirname $OUTFILE` ] || mkdir -m $CHMOD -p `dirname $OUTFILE` >/dev/null 2>&1

    ( ffmpeg -y -i "$INFILE" -ss 0:00:30 -t 0:00:33 \
      -f aiff - | sox -t aiff - \ 
      -t aiff - fade 1 0:30 3 | ffmpeg -y -i - -ab 192k "$OUTFILE" ) >/dev/null 2>&1 && echo "Successful created preview for $1"

    chmod $CHMOD $OUTFILE
}

# DEBUG:
# create_preview ../../../../etc/passwd
# create_preview R.E.M._-_Loosing_my_religion.mp3
# exit;

create_preview $@

#exit 0;
