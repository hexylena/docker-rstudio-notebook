
#' gx_put
#'
#' This function uploads a dataset to the current Galaxy history
#'
#' @param Path to file

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
}
