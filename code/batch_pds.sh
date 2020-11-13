
    # File name: batch_pds.sh
    # Author: Tania Paola Lopez Cantu
    # E-mail: tlopez@andrew.cmu.edu
    # Date created: 11.01.2020
    # Date last modified: 11.01.2020

    # ##############################################################
    # Purpos:

    # Using extract_pds.py script, batch extract pds from several climate model outputs. Code below needs to be adapted to your specific paths.

    # returns: csv file with partial duration series by grid



for name in /Volumes/MyBook/Tania/project_4_climate_data/ches_climate_data/cordex22/rcp45/*;
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
