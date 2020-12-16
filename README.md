# Using Climate Model Output for Engineering Applications

Collection of Python and R scripts to access and retrieve data from climate model output with an application to updating Intensity-Duration-Frequency (IDF) or Depth-Duration-Frequency curves used in infrastructure design.

This repository features a workflow for examining changes in *precipitation extremes* projected by downscaled climate model output and use these to create future DDF curves. Because downscaled climate simulations have inherited biases and the spatial resolution does not match that of the precipitation records used to create DDF curves, we cannot directly use these simulations to study what will occur in the future at a specific location. There exists several techniques to address this challenge, and in this tool we use the Empirical Quantile Delta Change, in which we investigate changes between historical and future simulations for specific quantiles of the extreme rainfall distribution. These changes or most commonly called, *change factors* are applied to the point-scale extreme rainfall quantiles, assuming that changes at the native downscaled projections grid will occur at the station scale.

## What is in this repository?

1. You can download climate model data and clip the data to a desired study domain. You must have installed in your computer the [Climate Data Operators (CDO)](https://code.mpimet.mpg.de/projects/cdo/) tool. See below for further details.
2. You can extracts time series of a desired variable for a user-specified time period (e.g., 1950 to 2000) and further extracts the partial duration series (PDS), in other words, the largest __n__ independent events in the time series, where __n__ is the number of years in the series.  Two events are independent if they are at least __m__ days apart. __m__ can be controlled by the user. The default value is 7 days.
3. You can fit a parametric distribution to model PDS. The third component uses the R library extRemes to model the PDS. The extRemes library allows the user to select different extreme value theory distributions and fitting methods to model the PDS. The current setting is set to *Generalized Extreme Value* (GEV) distribution, which is often used to model extreme events, and the fitting method is set to the *Generalized Maximum Likelihood Estimator*, described in [(Martins and Stedinger, 2000)](http://onlinelibrary.wiley.com/doi/10.1029/1999WR900330/abstract). Besides fitting a GEV model, this component also estimates the return levels for several exceedance probabilities. The default quantiles correspond to the 2-, 5-, 10-, 25-, 50-, and 100-year average recurrence intervals. This will be later adapted to accept user-specified exceedance probabilities.

4. You can estimate change factors (future/historical) between different periods. Once return levels for desired exceedance probabilities have been estimated for both the historical and future simulations in component 3, this component computes the change factor (the ratio between future and historical) for each member of a given downscaled climate model data set. It also gives the option to compute an ensemble statistic over the change factors of each member. The statistic can be controlled by the user, but the default value is set to median. The change factors are stored in CSV and text file format.
5. You can convert the text change factors to raster format. You can also estimate areal change factors by specifiying the polygons (from a shapefile) over to estimate the areal change factor. The method currently relies on the R libraries raster, rmapshaper and exactextractr. The data can be either stored as a shapefile or a geojson file (requires geojsonio library).


## Requirements
* Python 3.6+
* R 3.5+
* CDO tools

## How to use this repository?

1. Clone this repository, and install dependencies.
    ```bash
    git clone https://github.com/tplopez/future_idf.git
    cd future_idf
    # Python requirements
    pip install -r requirements.txt
    # R requirements
    rscript install_r_packages.r
    ```
    We recommend installing Python requirements in a virtual enviroment and specify where to install R packages to prevent conflicting package versions.

    The Climate Data Operators (CDO) (https://code.mpimet.mpg.de/projects/cdo/) tools must also be installed in your computer.
    For Mac users, you can install the CDO tools via `brew`. For other systems, please visit the CDO official website for installation guidance.

2. Download and clip netCDF files to a specific domain.
    - Create a text file (e.g., `scripts/urls.txt`) where each line is a url to download your selected GCM output.
    - Download and clip GCM data to your specific domain (in case it covers a larger domain) `./scripts/download_and_clip.sh /path/to/urls.txt`. The default bounding box in the script is
    -84,-72,36,44 which covers the Ohio River Basin, Virginia and partially covers other states in the surrounding area. If you are interested in a different domain, modify the script accordingly.
    Running this script will create a `climate_data` directory under the repository home directory and will download the file to this folder.
3. Extract Partial Duration Series for each grid cell center of the gridded downscaled GCM output.
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
4. Fit a Generalized Extreme Distribution to each gridcell in each member for a specific downscaled climate data set.
    - Use `code/gev_fit.r` to fit the GEV distribution.

    This script takes a few arguments, and should be specified when calling the function in the same order as listed below:
    * `path`: Path to folder where PDS are stored (Note: These files were generated in the previous step.)
    * `savepath`: Path where to store the parameters and return levels from the fitted model.
    * `--bound`: Bound (lower or upper) of the 95% confidence interval range of the estimated GEV parameters to use for calculating the return levels.

5. Estimate the change between the future and the historical simulations.
    - Use `code/estimate_cf.py`. This script takes a few arguments, including:
        * `--hist_path`: Path to where historical rainfall depth files per model are stored. (Note: These files are generated in step above.)
        * `--fut_path`: Path to where future rainfall depth files per model are stored. (Note: These files are generated in step above.)
        * `--save_path`: Directory where change factor files will be stored.
        * `--statistic`: Ensemble statistic returned.
6. Convert change factors to raster files.
    - Use `code/rasterize_gridded_cf.r`.

        This script takes a few arguments, and should be specified when calling the function in the same order as listed below:

        * `path`: Path to folder where change factors text files are stored (Note: These files were generated in the previous step.)
        * `filename`: Name for the raster file.
        * `savepath`: Path to where the raster file will be stored.
        * `polygonspath`: Path to shapefile containing the polygons for computation of areal change factors.
        * `save_geojson`: Boolean variable, TRUE if areal change factors over polygons should be stored as GeoJSON files.


## Notes

This repository is under construction, and we plan to extend the features supported here. If you have any question or suggestion, please [contact us](mailto:tlopez@andrew.cmu.edu).
