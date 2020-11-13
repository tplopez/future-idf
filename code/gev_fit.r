library(extRemes)
library(glue)



    # File name: gev_fit
    # Author: Tania Paola Lopez Cantu
    # E-mail: tlopez@andrew.cmu.edu
    # Date created: 11.02.2020
    # Date last modified: 11.02.2020

    # ##############################################################
    # Purpos:

    # Fit GEV using MLE to PDS/AMS

    # returns: csv file of GEV model parameters and depth for 2-,5-,10-,25-,50-,100-year ARI


args = commandArgs(trailingOnly=TRUE)



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
