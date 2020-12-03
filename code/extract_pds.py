"""
    File name: extract_pds
    Author: Tania Paola Lopez Cantu
    E-mail: tlopez@andrew.cmu.edu
    Date created: 11.05.2020
    Date last modified: 12.02.2020

    ##############################################################
    Purpos:

    Extract PDS from gridded climate model output

    returns: csv file with partial duration series by grid
"""

import argparse
import glob
import itertools
import math
import os
import sys
from datetime import timedelta

import netCDF4
import numpy as np
import pandas as pd
from netCDF4 import Dataset


def get_timestamps(ncfile):
    """
    This function outputs a timestamp series using the Time variable from the ncfile, and its origin
    ---
    input: .nc file
    output: [array] timestamps starting from the .nc file Time variable origin
    """
    timev = []
    for i, j in ncfile.variables["time_bnds"][:]:
        timev.append(i)
    timeunit_ncfile = timeunit_ncfile = ncfile.variables["time"].units.split(" ")[0]
    timeorigin = pd.Timestamp(" ".join(ncfile.variables["time"].units.split(" ")[2:]))
    timeorigin = timeorigin.tz_localize(None)

    if "day" in timeunit_ncfile:
        timeunit = "D"
        timestamps = pd.to_datetime(
            timev,
            unit=timeunit,
            origin=timeorigin,
        )

    elif "hour" in timeunit_ncfile:
        timeunit = "h"
        timestamps = pd.to_datetime(timev, unit=timeunit, origin=timeorigin)

    else:
        print("")
        sys.exit(
            "Unsupported data temporal resolution. Only daily and subdaily available."
        )
    timestamps = timestamps.round("60min")
    return timestamps


def get_pds(df, fr, pr_col, date_col):
    """Create a new df with col of partial duration series with
    with values that occur more than **fr** days apart.
    If a given event occurs less than **fr** days after (before) the previous
    (following) event, include the event with the higher precipitation"""

    N = len(df)

    n = int(math.floor(N / 365.25))  # Sample size of largest daily precip values
    omega = float((365.25 * n) / N)  # Average frequency

    sorted_df = df.sort_values(by=pr_col, ascending=False)  # Sort pr values descending

    largest = sorted_df.reset_index(drop=True).loc[
        0 : (n - 1), :
    ]  # Get largest n values

    days = timedelta(fr)
    # Sort by date to check whether events
    largest = largest.sort_values(by=date_col)
    # occur within the defined time window

    largest["delta_1"] = largest[date_col] - largest[date_col].shift()
    largest["delta_-1"] = largest[date_col] - largest[date_col].shift(periods=-1)
    largest["delta_-1"] = largest["delta_-1"].apply(lambda x: -x)

    fill_delta = timedelta(fr + 3)
    largest = largest.fillna(fill_delta)

    # Filter events that occur with more than specified days apart
    largest_filt = largest[(largest["delta_1"] > days) & (largest["delta_-1"] > days)]

    # Get events that happened with less than fr days
    dates_invalid_1 = largest[(largest["delta_1"] < days)]  # After
    dates_invalid_2 = largest[(largest["delta_-1"] < days)]  # Before

    invalid = [dates_invalid_1, dates_invalid_2]
    invalid_dates = pd.concat(invalid).sort_values(date_col)  # concat both

    # Need to take the event with higher pr value from those than occurred with less
    # than *fr* days appart

    # Group events that occurred within the fr days
    invalid_dates["group_max"] = (
        invalid_dates[date_col].diff() > pd.Timedelta(days=7)
    ).cumsum()

    # Get max event:
    valid = invalid_dates.groupby(["group_max"]).apply(lambda x: x.max())

    # Clean df above
    valid_2 = valid[[x for x in valid.columns if x != "group_max"]].reset_index(
        drop=True
    )

    # Merge with other events that met criteria
    largest_filt = pd.concat([largest_filt, valid_2]).reset_index(drop=True)

    # If selected events are less than n, need to search for additional events

    # Check difference:
    diff = n - len(largest_filt)
    events_filtered = n

    if diff == 0:
        return largest_filt[[pr_col]].sort_values(by=pr_col, ascending=False)

    while diff > 0:

        # Get additional events from timeseries other than the n events filtered at the
        # beginning:

        largest_additional = sorted_df.reset_index(drop=True)[events_filtered:]

        # filter necessary additional events:
        largest_2_sorted = largest_additional[0:diff].sort_values(by=date_col)

        # Repeat process above:
        largest_2_sorted["delta_1"] = (
            largest_2_sorted[date_col] - largest_2_sorted[date_col].shift()
        )
        largest_2_sorted["delta_-1"] = largest_2_sorted[date_col] - largest_2_sorted[
            date_col
        ].shift(periods=-1)
        largest_2_sorted["delta_-1"] = largest_2_sorted["delta_-1"].apply(lambda x: -x)
        largest_2_sorted = largest_2_sorted.fillna(fill_delta)
        largest_filt2 = largest_2_sorted[
            (largest_2_sorted["delta_1"] > days) & (largest_2_sorted["delta_-1"] > days)
        ]

        data = [
            largest_filt.reset_index(drop=True),
            largest_filt2.reset_index(drop=True),
        ]

        pds = pd.concat(data).reset_index(drop=True)

        if len(pds) == n:
            return pds[[pr_col]].sort_values(by=pr_col, ascending=False)

        else:
            events_filtered += diff
            diff = n - len(pds)
            largest_filt = pds


def main(args):
    dataset = args.data
    timereso = args.timereso
    dataset = dataset.upper()
    all_d = []
    timestamps = []

    if not os.path.isdir(args.ncdir):
        ncdir = "{}".format(args.ncdir)
    else:
        ncdir = "{}/*".format(args.ncdir)
    print(ncdir)
    savename = args.savename
    window = int(args.window)

    print("Extracting PDS from...{}".format(ncdir))

    if "BCCA" in dataset:
        var_name = "prec"
        lat_name = "latitude"
        lon_name = "longitude"
    elif "LOCA" in dataset:
        var_name = "pr"
        lat_name = "lat"
        lon_name = "lon"
    elif "CORDEX" in dataset:
        var_name = "pr"
        lat_name = "lat"
        lon_name = "lon"
    elif "MACA" in dataset:
        var_name = "precipitation"
        lat_name = "lat"
        lon_name = "lon"

        lat0 = 263
        lat1 = 421
        lon0 = 979
        lon1 = 1267

    if dataset == "other":
        var_name = args.query_variable
        names = {}
        for k, v in ncfile.variables.items():
            if "bnds" in k:
                continue
            else:
                names[k] = v.long_name

        for k, v in names.items():
            if "lon" in v:
                lon_name = k
            if "lat" in v:
                lat_name = k

    for ncpath in glob.glob(ncdir):
        ncfile = Dataset(ncpath, "r", fmt="NETCDF4")
        timenc = get_timestamps(ncfile)

        if "MACA" in dataset:
            lonlen = len(ncfile.variables["lon"][lon0:lon1])
            latlen = len(ncfile.variables["lat"][lat0:lat1])
            pr = np.ma.getdata(
                ncfile.variables["precipitation"][:, lat0:lat1, lon0:lon1]
            )

        else:
            lonlen = len(ncfile.variables[lon_name][:])
            latlen = len(ncfile.variables[lat_name][:])
            pr = np.ma.getdata(ncfile.variables[var_name][:, :, :]).squeeze()

        lonarr = np.arange(0, lonlen)
        latarr = np.arange(0, latlen)

        r = {}
        for i, j in itertools.product(latarr, lonarr):
            r["id{}_{}".format(i, j)] = np.ma.getdata(pr[:, i, j])

        full_domain = pd.DataFrame(r)
        cols = full_domain.columns

        timestamps.extend(timenc)

        all_d.append(full_domain)

    full_domain_temp = pd.concat(all_d)
    # Remove NA values
    # Read NA value from the ncfile and identify in dataframe
    try:
        ncfile_nan_value = ncfile.variables[var_name]._FillValue
    except AttributeError:
        ncfile_nan_value = netCDF4.default_fillvals["f8"]
    full_domain_temp.replace(to_replace=ncfile_nan_value, value=np.nan, inplace=True)

    # Comment line below if not LOCA. Needed to multiply because LOCA units are kgm2s-1

    if dataset == "LOCA":
        full_domain_temp = full_domain_temp * 86400

    if timereso == "subdaily":
        full_domain_temp = full_domain_temp * 86400 / 24

    full_domain_temp["date"] = timestamps

    full_domain_temp = full_domain_temp.dropna(
        how="all", axis=0, subset=[x for x in full_domain_temp.columns if x != "date"]
    )
    full_domain_temp = full_domain_temp.dropna(how="all", axis=1)

    full_domain_temp.set_index("date", inplace=True)

    # Match periods that we decided on
    full_domain = full_domain_temp[args.start_year : args.end_year].reset_index()

    print("Time series were extracted")

    # import ipdb

    # ipdb.set_trace()
    print("Procceding to extracting PDS")
    grid_cols = [x for x in full_domain if x != "date"]

    pds_dict = {}
    for grid in grid_cols:
        pds_dict[grid] = get_pds(full_domain[[grid, "date"]], window, grid, "date")[
            grid
        ].values

    pds = pd.DataFrame.from_dict(pds_dict)
    pds = pds.round(2)

    pds.to_csv(savename)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        "Get PDS for each grid in downscaled climate projections. Available options are BCCAv.2, LOCA, MACA and NA-CORDEX. For other datasets, use other and also specify argument query_variable to specify the name of the variable for which PDS will be extracted."
    )
    parser.add_argument(
        "--data",
        type=str,
        required=True,
        help="Name of source of downscaled climate projections. Available options are: BCCAv.2, LOCA, MACA and NA-CORDEX. For other, use other.",
    )
    parser.add_argument(
        "--query_variable",
        type=str,
        required=False,
        help="Variable name in nc file for which PDS will be extracted if dataset other than available.",
    )
    parser.add_argument(
        "--timereso",
        type=str,
        required=True,
        help="Temporal resolution of the input data. Examples: daily or subdaily.",
    )
    parser.add_argument(
        "--ncdir",
        type=str,
        required=True,
        help="Directory where glob will loop to read nc files.",
    )
    parser.add_argument(
        "--window", type=str, required=True, help="Number of days events must be apart"
    )
    parser.add_argument(
        "--start_year",
        type=str,
        required=False,
        help="Start year for extracting PDS. Must be a valid year within the model time series.",
    )
    parser.add_argument(
        "--end_year",
        type=str,
        required=False,
        help="End year for extracting PDS. Must be a valid year within the model time series.",
    )
    parser.add_argument(
        "--savename", type=str, required=True, help="Save name with full path"
    )

    args = parser.parse_args()

    main(args)
