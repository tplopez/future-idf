library(extRemes)
library(glue)

# suppressMessages(library(extRemes))
# suppressMessages(library(glue))

args = commandArgs(trailingOnly=TRUE)

# dataset = args[1]
# if (dataset =='loca'){
#     models <- c("IPSL-CM5A-MR", "ACCESS1-3", "MRI-CGCM3", "HadGEM2-CC", "CNRM-CM5", "CanESM2",
#                     "ACCESS1-0", "HadGEM2-AO", "CSIRO-Mk3-6-0", "IPSL-CM5A-LR", "FGOALS-g2",
#                     "inmcm4", "CESM1-CAM5", "HadGEM2-ES", "GFDL-ESM2G", "CMCC-CMS", "MIROC-ESM-CHEM", "CESM1-BGC",
#                     "GFDL-ESM2M", "CMCC-CM", "GISS-E2-R", "bcc-csm1-1-m", "CCSM4", "EC-EARTH",
#                     "bcc-csm1-1", "MPI-ESM-MR", "MIROC5", "NorESM1-M", "MPI-ESM-LR", "GFDL-CM3", "MIROC-ESM")
# } else if (dataset) == 'bcca'){

#     models <- c('IPSL-CM5A-LR_r3i1p1', 'MIROC5_r3i1p1', 'MPI-ESM-MR_r1i1p1', 'CanESM2_r3i1p1', 'CSIRO-Mk3-6-0_r4i1p1', 'bcc-csm1-1',
#                     'CanESM2_r2i1p1', 'CSIRO-Mk3-6-0_r5i1p1', 'CCSM4_r1i1p1', 'IPSL-CM5A-LR_r2i1p1', 'MIROC5_r2i1p1', 'CESM1-BGC', 'CSIRO-Mk3-6-0_r10i1p1', 'CSIRO-Mk3-6-0_r7i1p1',
#                     'IPSL-CM5A-MR', 'MIROC-ESM-CHEM', 'CNRM-CM5', 'MIROC-ESM', 'IPSL-CM5A-LR_r1i1p1',
#                     'MIROC5_r1i1p1', 'CSIRO-Mk3-6-0_r6i1p1', 'CanESM2_r1i1p1', 'MPI-ESM-LR_r2i1p1',
#                     'GFDL-ESM2M', 'CCSM4_r2i1p1', 'CanESM2_r4i1p1', 'CSIRO-Mk3-6-0_r3i1p1', 'IPSL-CM5A-LR_r4i1p1', 'MPI-ESM-LR_r1i1p1', 'GFDL-ESM2G', 'MRI-CGCM3', 'CanESM2_r5i1p1',
#                     'ACCESS1-0', 'CSIRO-Mk3-6-0_r2i1p1', 'NorESM1-1M', 'MPI-ESM-LR_r3i1p1', 'CSIRO-Mk3-6-0_r9i1p1', 'CSIRO-Mk3-6-0_r1i1p1', 'inmcm4', 'CSIRO-Mk3-6-0_r8i1p1')
# } else if (dataset) == ''

path = args[1]
savepath = args[2]
bnn = args[3]

for (f in list.files(path)) {

    savefile_params = glue('{savepath}/param_{f}')
    message(savefile_params)
    savefile_depth =glue('{savepath}/depth_{f}')
    params_estimated = FALSE
    if (file.exists(savefile_params) == FALSE){

        params_estimated = TRUE

        pds <- read.csv(file=glue('{path}/{f}'), header=T, sep=',')
        pds2 <- pds[ , apply(pds, 2, function(x) !any(is.na(x)))]
        pds3 <- pds2[, colSums(pds2 != 0) > 0]

        message('Finished reading...')

        model.name <- colnames(pds3)

        f = (length(model.name))

        model.name <- colnames(pds3)[c(2:f)]
        params <- data.frame(matrix(ncol = 10, nrow = length(model.name)))
        colnames(params) <- c("models", "L_loc", "loc", "U_loc",
                            "L_scale", "scale", "U_scale",
                            "L_shape", "shape", "U_shape")
        params[1] <- as.vector(model.name)
        message('Starting fit...')
        for (model in 2:f) {
            md = as.vector(pds3[, (model)])
            id_ <- model.name[model-1]
            tryCatch({
                fit_mle <- fevd(md, method='MLE', type='GEV')

                param.loc <- as.vector(ci(fit_mle, alpha=0.05, type='parameter')[1,])
                param.scale <- as.vector(ci(fit_mle, alpha=0.05, type='parameter')[2,])
                param.shape <- as.vector(ci(fit_mle, alpha=0.05, type='parameter')[3,])

                params.single <- c(param.loc,param.scale, param.shape)
                params[model-1, c(2:10)] <- params.single},
                error = function(e){ message(" ", glue('There was an error at: {id_}'))
                })
            }
        message('End fit, writing csv')
        write.csv(params, savefile_params)}
    if (file.exists(savefile_depth) == FALSE){

        if (params_estimated == FALSE){
            params <- read.csv(file=savefile_params, header=T, sep=',')
        }

        message("Estimating precipitation depth...")

        if (bnn == 'U_'){
            df = subset(params, select = -c(L_loc, loc, L_scale, scale, L_shape,shape))
        } else if (bnn == 'L_'){
            df = subset(params, select = -c(U_loc, loc, U_scale, scale, U_shape,shape) )
        } else if (bnn == 'best'){
            df = subset(params, select = -c(U_loc, L_loc, U_scale, L_scale, U_shape, L_shape))
        }
        params <- t(df)
        model.name <- params["models", ]

        #message(" ", model.name)

        f = (length(model.name))
        depth.cals <- data.frame(matrix(ncol = 7, nrow =length(model.name) ))
        colnames(depth.cals) <- c("models", "2-yr", "5-yr",
                                            "10-yr", "25-yr", "50-yr",
                                            "100-yr")
        depth.cals[1] <- as.vector(model.name)

        for (model in 1:f){

            pmodel <- params[, (model)]
            pmodel <- pmodel[!is.na(pmodel)]
            tryCatch({
                if (params_estimated == FALSE){
                    loc = as.double(pmodel[3])
                    scale = as.double(pmodel[4])
                    shape = as.double(pmodel[5])
                } else if (params_estimated == TRUE){
                    loc = as.double(pmodel[2])
                    scale = as.double(pmodel[3])
                    shape = as.double(pmodel[4])
                }
            depth.cals.single <- as.vector(rlevd(period=c(2,5,10,25,50,100),
                loc = loc, scale=scale, shape=shape))
            depth.cals[model, c(2:7)] <- depth.cals.single
            }, error = function(e){})
        }
        message("End estimation, writing csv")
        write.csv(depth.cals, savefile_depth)

    }

    }
