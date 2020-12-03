# Using Climate Model Output for Engineering Applications

Collection of Python and R scripts to access and retrieve data from climate model output with an application to updating Intensity-Duration-Frequency (IDF) or Depth-Duration-Frequency curves used in infrastructure design.

This repository features a workflow for examining changes in *precipitation extremes* projected by downscaled climate model output and use these to create future DDF curves. The workflow is composed of four main components.

1. The first component downloads climate model data and clips the data to a desired study domain.
2. The second access the climate model output file, extracts time series of a desired variable for a user-specified time period (e.g., 1950 to 2000) and further extracts the partial duration series (PDS), in other words, the largest __n__ independent events in the time series, where __n__ is the number of years in the series.  Two events are independent if they are at least __m__ days apart. __m__ can be controlled by the user. The default value is 7 days.
3. The third component uses the R library extRemes to model the PDS. The extRemes library allows the user to select different extreme value theory distributions and fitting methods to model the PDS. The current setting is set to *Generalized Extreme Value* distributio, which is often used to model extreme events, and the fitting method is set to the *Generalized Maximum Likelihood Estimator*, described in [(Martins and Stedinger, 2000)](http://onlinelibrary.wiley.com/doi/10.1029/1999WR900330/abstract).


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

    * `START_YEAR` corresponds to the beginning year from when to extract the PDS
    * `END_YEAR` corresponds to the end year up to when extract the PDS

    The `code/extract_pds.py` takes a few arguments, including:
    * `--data`: Dataset source of downscaled climate projections. At the moment, the supported datasets are: BCCA v.2, LOCA, MACA and NA-CORDEX.
    * `--timereso`: Time resolution of the data: daily or subdaily.
    * `--window`: Number of days extreme events must be apart.
    For help, please run `python extract_pds.py --help`.


    Note: Usually, downscaled climate model output stored in a server is logically organized according to its parent GCM model, the RCP scenario, etc (e.g., https://tds.ucar.edu/thredds/fileServer/datazone/cordex/data/raw/NAM-44/1hr/WRF/MPI-ESM-LR/rcp85/pr/pr.rcp85.MPI-ESM-LR.WRF.1hr.NAM-44.raw.nc). The `scripts/batch_pds.sh` script takes advantage of this storing architecture to take the name of the model and scenario and make directories in your computer to store the data in a similar fashion.
    If the url to your climate data does not look like the one above, you will need to additionally specify the following variables:

    * `GCM` corresponds to the name of the GCM model
    * `SCENARIO` corresponds to the simulation scenario, either hist, rcp4.5 or rcp8.5
    * `DATASET` dataset source of downscaled climate projections. At the moment, the supported datasets are: BCCA v.2, LOCA, MACA and NA-CORDEX.

## Notes

This repository is under construction, and we plan to extend the features supported here. If you have any question or suggestion, please [contact us](mailto:tlopez@andrew.cmu.edu).
