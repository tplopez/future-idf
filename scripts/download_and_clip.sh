

    # File name: download_and_clip.sh
    # Author: Tania Paola Lopez Cantu
    # E-mail: tlopez@andrew.cmu.edu
    # Date created: 10.15.2020
    # Date last modified: 10.15.2020

    # ##############################################################
    # Purpos:

    # Download gridded climate model output from urls in "urls.txt" file stored in the home directory.
    # Clip the model ouput to a certain domain (specified with min, max lat and lon) and remove full domain file to save storage space.

#!/usr/bin/env bash

URL_PATH=$1  # first commandline argument
[ ! -f $URL_PATH ] && echo "File not found." && exit  # check if the file exists, exit otherwise

while read line target;
    do
        URL="$line"
        FILE_NAME="$(basename $dir)";   # Gets the name of the file that will be downloaded
        wget -nc "$URL" -P "./climate_data"; # This command starts the download of the model data hosted in each line of the url.txt file, -nc option means that it will not download the file if it already exists
        LABEL="clipped" # Label to rename the downloaded file, serves to identify that the file is a subset of the original
        cdo sellonlatbox,-84,-72,36,44 $FILE_NAME "./${LABEL}_${FILE_NAME}"; # CDO command to cut nc file to box defined by lon0,lon1,lat0,lat1
        rm -rf $FILE_NAME; # Remove original model data

    done < $URL_PATH # File with urls to download model data, urls.txt file must be stored at your home directory
