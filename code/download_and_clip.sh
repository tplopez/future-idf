

    # File name: download_and_clip.sh
    # Author: Tania Paola Lopez Cantu
    # E-mail: tlopez@andrew.cmu.edu
    # Date created: 10.15.2020
    # Date last modified: 10.15.2020

    # ##############################################################
    # Purpos:

    # Download gridded climate model output from urls in "urls.txt" file stored in the home directory.
    # Clip the model ouput to a certain domain (specified with min, max lat and lon) and remove full domain file to save storage space.




while read line target;
    do
        dir="$line"
        fname="$(basename $dir)";   # Gets the name of the folder where the data will be stored from the model nc file name
        echo $fname       # This command prints in the terminal the name of the folder where the data will be stored
        wget -nc "$line"; # This command starts the download of the model data hosted in each line of the url.txt file
        label="clipped" # Label to rename the downloaded file, serves to identify that the file is a subset of the original
        cdo sellonlatbox,-84,-72,36,44 $fname "./${label}_${fname}"; # CDO command to cut nc file to box defined by lon0,lon1,lat0,lat1
        rm -rf $fname; # Remove original model data

    done < "$HOME/urls.txt" # File with urls to download model data, urls.txt file must be stored at your home directory
