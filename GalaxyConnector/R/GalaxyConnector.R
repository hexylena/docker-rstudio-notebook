
#' gx_put
#'
#' This function uploads a dataset to the current Galaxy history
#'
#' @param Path to file
#' @param file_type, auto-detect otherwise

gx_put <- function(filename, file_type="auto"){
    command <- paste("python", "/usr/local/bin/galaxy.py", "put", filename, file_type)
    system(command)
}

#' gx_get
#'
#' Download a dataset from the current Galaxy history by ID #
#'
#' @param ID number

gx_get <- function(file_id){
    command <- paste("python", "/usr/local/bin/galaxy.py", "get", file_id)
    system(command)
    return(paste("/import/", file_id, sep=""))
}


#' gx_save
#'
#' Save the notebook to Galaxy. Convenience function which wraps save.image and gx_put
#'

gx_save <- function(){
    save.image("/tmp/workspace.RData")
    gx_put("/tmp/workspace.RData")
}
