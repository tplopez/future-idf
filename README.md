# Future IDF Curves

Collection of Python and R scripts to update historical IDF curves using downscaled climate model output.

## Requirements
* Python 3.6+
* R 3.5+

## Usage

1. Clone this repository, and install dependencies.
    ```bash
    git clone https://github.com/tplopez/future_idf.git
    cd future_idf
    # Python requirements
    pip install requirements.txt
    # R requirements
    rscript install_r_packages.r
    ```
    We recommend installing Python requirements in a virtual enviroment and specify where to install R packages to prevent conflicting package versions.

2. Download and clip netCDF files to a specific domain.
    - Create a text file named *urls.txt* where each line is a url to download your selected GCM output. In this repository, we have one example *urls.txt* file that you can modify.
    - Download anc clip GCM data to your specific domain (in case it covers a larger domain). The default bounding box in `scripts/download_and_clip.sh` is
    -84,-72,36,44 which covers the Ohio River Basin, Virginia and partially covers other states in the surrounding area. If you are interested in a different domain, modify the script accordingly.
3. To extract Partial Duration Series for each grid cell center of the gridded GCM output,
