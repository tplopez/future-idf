for name in /Volumes/MyBook/Tania/project_4_climate_data/ches_climate_data/cordex22/rcp45/ches_GFDL-ESM2M.CRCM5-OUR.nc;
    do
    gcm=$(basename $name);
    scenario_dir=$(dirname $name)
    scenario=$(basename $scenario_dir)
    dataset_dir=$(dirname $scenario_dir)
    dataset=$(basename $dataset_dir)
    start_year=2050
    end_year=2100
    python extract_pds.py --data $dataset --ncdir $name --window 7 --start_year $start_year --end_year $end_year --savename "/Users/tanialopez/Documents/cmu/research/WorkingProjects/Chesapeake/datasets/pds/cordex22/${scenario}/${start_year}-${end_year}/${gcm}.csv"

    done
