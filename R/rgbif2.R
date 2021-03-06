#' Gets occurrence data from GBIF
#'
#' This function uses the rgbif package to get occurrence data of a species.
#'
#' @param dir Path to directory where the file will be saved. Default is to create a "results/" directory
#' @param filename Name of the output file
#' @param species Genus and specific epithet separated by space. Accepts author if inserted correctly. Either a single value or a vector
#' @param force Logical. Force downloading data for more than 10 species in a loop. Default `force = FALSE`
#' @param remove_na Logical. Defalt `TRUE` removes NA in columns decimalLatitude and decimalLongitude
#' @param save Logical. Save output to filename? Defaults to TRUE
#' @param ... Any argument from occ_search in rgbif package
#'
#' @return A data.frame with the search result. Also saves the output on disk
#'
#' @author Sara Mortara & Andrea Sánchez-Tapia
#'
#' @examples
#' \dontrun{
#' ex_rgbif <- rgbif2(filename = "ex-gbif",
#'                    species =  "Asplenium truncorum")
#' }
#' @importFrom rgbif name_backbone
#' @importFrom rgbif occ_search
#' @importFrom utils write.table
#' @importFrom dplyr bind_rows
#' @export
#' @author Sara Mortara & Andrea Sánchez-Tapia
#'
rgbif2 <- function(dir = "results/",
                   filename = "output",
                   species,
                   force = FALSE,
                   remove_na = TRUE,
                   save = TRUE,
                   ...) {
  if (length(species) > 9) {
    if (!force) {
      stop("Use force = TRUE if you still want to download data for more than 10 species")
    }
  }
  key <- sapply(species, function(x) rgbif::name_backbone(name = x)$speciesKey)
  key_pointer <- sapply(key, function(x) !is.null(x))
  # Adding message if any species not found
  if (!all(key_pointer)) {
    message("\nSpecies not found: ", species[!key_pointer],
            "\nReturning data only for: ",
            paste(species[key_pointer], collapse = ", "), "\n")
  }
  # Loop for each valid species
  gbif_data <- list()
  for (i in 1:length(key_pointer)) {
    if (key_pointer[i]) {
      message("Making request to GBIF...")
      gbif_data[[i]] <- tryCatch(cbind(rgbif::occ_search(hasCoordinate = TRUE,
                                                   hasGeospatialIssue = FALSE,
                                                   taxonKey = key[i])$data,
                                       download = "succeded"),
                                 error = function(e){data.frame(download = "failed",
                                                                stringsAsFactors = FALSE)})
    } else {gbif_data[[i]] <- data.frame(key = NA, dowload = "no_species_key")}
  }
  names(gbif_data) <- species
  all_data <- as.data.frame(dplyr::bind_rows(gbif_data, .id = "species_search"))
  if (remove_na) {
    all_data <- all_data[!is.na(all_data$decimalLongitude)
                         & !is.na(all_data$decimalLatitude), ]
  }
  if (save) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  fullname <- paste0(dir, filename, ".csv")
  message(paste0("Writing ", fullname, " on disk."))
  write.table(all_data,
              fullname,
              sep = ",",
              row.names = FALSE,
              col.names = TRUE)
  }
  return(all_data)
}
