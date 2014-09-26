
#' put
#'
#' This function uploads a dataset to the current Galaxy history
#'
#' @param Path to file

put <- function(filename, file_type="auto"){
    command <- paste("python", "/usr/local/bin/galaxy.py", "put", filename, file_type)
    system(command)
}

#' get
#'
#' Download a dataset from the current Galaxy history by ID #
#'
#' @param ID number

get <- function(file_id){
    command <- paste("python", "/usr/local/bin/galaxy.py", "get", file_id)
    system(command)
}
