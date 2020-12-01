# Future IDF Curves

Collection of Python and R scripts to manipulate downscaled climate model output and use it to update Intensity-Frequency-Duration curves used in infrastructure design.

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

    The Climate Data Operators (CDO) (https://code.mpimet.mpg.de/projects/cdo/) tools must also be installed in your computer.
    For Mac users, you can install the CDO tools via `brew`. For other systems, please visit the CDO official website for installation guidance.

2. Download and clip netCDF files to a specific domain.
    - Create a text file named *urls.txt* where each line is a url to download your selected GCM output. In this repository, we have one example *urls.txt* file that you can modify.
    - Download and clip GCM data to your specific domain (in case it covers a larger domain). The default bounding box in `scripts/download_and_clip.sh` is
    -84,-72,36,44 which covers the Ohio River Basin, Virginia and partially covers other states in the surrounding area. If you are interested in a different domain, modify the script accordingly.
    Running this script will create a `climate_data` directory under the repository home directory and will download the file to this folder.
3. Extract Partial Duration Series for each grid cell center of the gridded GCM output.
    - Use `scripts/batch_pds.sh` for running in batch, or `code/extract_pds.py` for a single netCDF file.

    If running in batch, you need to specify a few options in the `scripts/batch_pds.sh` to your desired configuration before running.

        *`START_YEAR` corresponds to the beginning year from when to extract the PDS
        *`END_YEAR` corresponds to the end year up to when extract the PDS

    The `code/extract_pds.py` takes a few arguments, including:
        *data: Dataset source of downscaled climate projections. At the moment, the supported datasets are: BCCA v.2, LOCA, MACA and NA-CORDEX.
        *timereso: Time resolution of the data: daily or subdaily.
        *window: Number of days extreme events must be apart.
    For help, please run `python extract_pds.py --help`.


    Note: Usually, downscaled climate model output stored in a server is logically organized according to its parent GCM model, the RCP scenario, etc. For example, https://tds.ucar.edu/thredds/fileServer/datazone/cordex/data/raw/NAM-44/1hr/WRF/MPI-ESM-LR/rcp85/pr/pr.rcp85.MPI-ESM-LR.WRF.1hr.NAM-44.raw.nc
    The `scripts/batch_pds.sh` script takes advantage of this storing architecture to take the name of the model and scenario and make directories in your computer to store the data in a similar fashion.
    If the url to your climate data does not look like the one above, you will need to additionally specify the following variables:
        *`GCM` corresponds to the name of the GCM model
        *`SCENARIO` corresponds to the simulation scenario, either hist, rcp4.5 or rcp8.5
        *`DATASET` dataset source of downscaled climate projections. At the moment, the supported datasets are: BCCA v.2, LOCA, MACA and NA-CORDEX.

## Notes

This repository is under construction, and we plan to extend the features supported here. If you have any question or suggestion, please [contact us](mailto:tlopez@andrew.cmu.edu).
