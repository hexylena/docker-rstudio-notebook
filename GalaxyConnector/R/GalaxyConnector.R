
#' put
#'
#' This function uploads a dataset to the current galaxy history
#'
#' @param path to file

put <- function(filename){
    library(yaml)
    conf <- yaml.load_file("/import/conf.yaml")
    command <- paste("python", "/usr/local/bin/upload_to_history.py", conf$api_key, conf$galaxy_url,
                     conf$history_id, filename)
    system(command)
}
