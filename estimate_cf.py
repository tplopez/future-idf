import pandas as pd
import glob
import numpy as np
import os
import argparse
import sys


def main(args):

    path_hist = args.hist_path
    path_fut = args.fut_path
    savepath = args.save_path
    all_models = []

    models_more_realizations_fut = {}
    for f in glob.glob("{}/depth*".format(path_fut)):
        filesplit = f.split("/")
        file = filesplit[-1]
        period = filesplit[-2]
        scen = filesplit[-3]

        if "i1p1" in file:

            if file not in models_more_realizations_fut.keys():

                models_more_realizations_fut[file] = [
                    pd.read_csv(f, index_col=["models"])
                ]
            else:
                models_more_realizations_fut[file].append(
                    pd.read_csv(f, index_col=["models"])
                )
    models_more_realizations_hist = {}
    for f in glob.glob("{}/depth*".format(path_hist)):
        filesplit = f.split("/")
        file = filesplit[-1]
        print(file)
        period = filesplit[-2]
        scen = filesplit[-3]
        if "i1p1" in file:
            if file not in models_more_realizations_hist.keys():
                models_more_realizations_hist[file] = [
                    pd.read_csv(f, index_col=["models"])
                ]
            else:
                models_more_realizations_hist.append(
                    pd.read_csv(f, index_col=["models"])
                )
    added_data = dict.fromkeys(models_more_realizations_hist.keys(), 0)

    period_check = path_fut.split("/")[-2]
    scen_check = path_fut.split("/")[-3]

    savecf_filename = "{}/{}".format(
        savepath, "cf_{}_{}_{}.csv".format(scen_check, period_check, args.statistic)
    )
    print(savecf_filename)

    if os.path.exists(savecf_filename):
        sys.exit(0)
    else:
        if not os.path.isdir(savepath):
            os.makedirs(savepath)

        for f in glob.glob("{}/depth*".format(path_fut)):
            print(f)
            # Get information from file for saving later
            filesplit = f.split("/")
            file = filesplit[-1]
            gcm_rcm = ".".join(file.split(".")[2:4])
            period = filesplit[-2]
            scen = filesplit[-3]
            if file in models_more_realizations_fut.keys():
                if added_data[file] == 0:

                    df_fut1 = (
                        pd.concat(models_more_realizations_fut[file])
                        .reset_index()
                        .groupby("models")
                        .mean()
                    )
                    df_hist1 = (
                        pd.concat(models_more_realizations_hist[file])
                        .reset_index()
                        .groupby("models")
                        .mean()
                    )
                    df = df_fut1 / df_hist1
                    df.drop(["Unnamed: 0"], axis=1, inplace=True)
                    all_models.append(df.reset_index())

                    added_data[file] = 1
                if added_data[file] == 1:
                    continue
            if scen in file:
                file = file.replace(".{}".format(scen), ".hist")

            df_fut = pd.read_csv(f, index_col=["models"])
            df_hist = pd.read_csv("{}/{}".format(path_hist, file), index_col=["models"])
            df = df_fut / df_hist
            df.drop(["Unnamed: 0"], axis=1, inplace=True)

            if args.statistic == "None":
                df.round(2).to_csv(
                    "{}/cf_{}_{}_{}.csv".format(savepath, gcm_rcm, scen, period)
                )

            all_models.append(df.reset_index())

        df_cf = pd.concat(all_models)
        # df_cf.to_csv("./test.csv")
        if args.statistic != "None":
            if args.statistic == "median":
                df_save = df_cf.groupby("models").median()

            else:
                p = args.statistic.split(".")[1]
                df_save = df_cf.groupby("models").agg(
                    lambda x: np.percentile(x, int(p))
                )

            df_save.round(2).to_csv(
                "{}/{}".format(
                    savepath, "cf_{}_{}_{}.csv".format(scen, period, args.statistic)
                )
            )

        # index_lat = []
        # index_lon = []
        # if not os.path.isdir("{}/txt".format(savepath)):
        #     os.makedirs("{}/txt".format(savepath))
        # df_temp = df_save.reset_index()
        # for index in df_temp.models.values:
        #     idx = index.replace("id", "")
        #     index_lat.append(int(idx.split("_")[0]))
        #     index_lon.append(int(idx.split("_")[1]))

        # for rp in [2, 5, 10, 25, 50, 100]:
        #     idx_lat = set(index_lat)
        #     idx_lon = set(index_lon)
        #     raster_matrix = np.zeros((max(idx_lat) + 1, max(idx_lon) + 1))

        #     for index in df_temp.models.values:
        #         idx = index.replace("id", "")
        #         i = int(idx.split("_")[0])
        #         j = int(idx.split("_")[1])

        #         value = df_temp[df_temp.models == index]["{}".format(rp)].values
        #         raster_matrix[i, j] = value

        #     raster_matrix = np.array(list(reversed([i for i in raster_matrix])))

        #     np.savetxt(
        #         "{}/txt/cf_{}_{}_{}_{}.txt".format(
        #             savepath, scen, period, args.statistic, rp
        #         ),
        #         raster_matrix,
        #         fmt="%1f",
        #         delimiter=" ",
        #         newline="\n",
        #     )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        "Estimate change factor for rainfall depth in historical and future scenarios."
    )
    parser.add_argument(
        "--hist_path",
        type=str,
        required=True,
        help="Path to where historical rainfall depth files per model are stored.",
    )
    parser.add_argument(
        "--fut_path",
        type=str,
        required=False,
        help="Path to where future rainfall depth files per model are stored.",
    )
    parser.add_argument(
        "--save_path",
        type=str,
        required=True,
        help="Directory where cf files will be saved.",
    )

    parser.add_argument(
        "--statistic",
        type=str,
        required=True,
        help="Ensemble statistic returned.",
    )
    args = parser.parse_args()

    main(args)
