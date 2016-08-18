#' gx_put
#'
#' This function uploads a dataset to the current Galaxy history
#'
#' @param filename, path to file
#' @param file_type, auto-detect otherwise specify string filetype

gx_put <- function(filename, file_type="auto"){
    command <- paste("/usr/local/bin/put", "-p", filename, "-t", file_type)
    system(command)
}

#' gx_get
#'
#' Download a dataset from the current Galaxy history by ID #
#'
#' @param file_id, Dataset ID number for current history

gx_get <- function(file_id){
    command <- paste("/usr/local/bin/get", "-i", file_id)
    system(command)
    return(paste("/import/", file_id, sep=""))
}


#' gx_save
#'
#' Save the notebook .RData and .RHistory to Galaxy. Convenience function which wraps save.image and gx_put
#'
#' @param session_name, default "workspace"

gx_save <- function(session_name="workspace"){
    workspace <- paste("/tmp/",session_name,".RData",sep="")
    hist <- paste("/tmp/",session_name,".RHistory",sep="")
    save.image(workspace)
    savehistory(hist)
    gx_put(workspace)
    gx_put(hist)
}


#' gx_restore
#'
#' Restore the notebook from a .RData and .RHistory object from the current Galaxy history.
#' @param .RData ID number
#' @param .RHistory ID number

gx_restore <- function(rdata_id,rhistory_id){
    rdata <- gx_get(rdata_id)
    rhistory <- gx_get(rhistory_id)
    load(rdata,envir=.GlobalEnv)
    loadhistory(rhistory)
}
