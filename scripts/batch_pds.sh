
# File name: batch_pds.sh
# Author: Tania Paola Lopez Cantu
# E-mail: tlopez@andrew.cmu.edu
# Date created: 11.01.2020
# Date last modified: 11.01.2020

# ##############################################################
# Purpos:

# Using extract_pds.py script, batch extract pds from several climate model outputs. Code below needs to be adapted to your specific paths.
# returns: csv file with partial duration series by grid

for name in ../climate_data/*;
    do
    GCM=$(basename $name);
    SCENARIO_DIR=$(dirname $name)
    SCENARIO=$(basename $SCENARIO_DIR)
    DATASET_DIR=$(dirname $SCENARIO_DIR)
    DATASET=$(basename $DATASET_DIR)
    START_YEAR=2050
    END_YEAR=2100
    OUT_DIR="../output/${DATASET}/${SCENARIO}/${START-YEAR}-${END-YEAR}"
    mkdir -p $OUT_DIR
    python extract_pds.py --data $DATASET --ncdir $NAME --window 7 --start_year $START_YEAR --end_year $END_YEAR --savename "${OUT_DIR}/${gcm}.csv"

    done
