# This script takes a data.frame with one loop
# and parses it to create a formatted .md file

# 5/21/25

# Load libraries ----
suppressPackageStartupMessages({
  library(tidyverse)
  library(glue)
})

# Functions ----
make_safe_filename <- function(name, extension = NULL, to_lower = FALSE) {
  # Replace any non-alphanumeric character with underscore
  safe_name <- str_replace_all(name, "[^A-Za-z0-9]+", "_") |>
  # Replace multiple underscores with a single underscore
    str_replace_all("_+", "_") |>
  # Remove leading or trailing underscores
    str_replace_all("^_|_$", "") |>
  # Remove commas
    stringr::str_remove_all(",")
  
  if (to_lower) safe_name <- tolower(safe_name)
  if (!is.null(extension)) {
    if (!startsWith(extension, ".")) {
      extension <- paste0(".", extension)
    }
    safe_name <- paste0(safe_name, extension)
  }
  return(safe_name)
}

url_to_md <- function(x) {
  if (!is.character(x)) return(x)  # Leave non-character columns unchanged
  str_replace_all(x, "(https?://[^\\s)]+)", "[\\1](\\1)")
}

sanitize_folder_name <- function(x) {
  x %>%
    # Replace invalid characters with underscore
    str_replace_all('[<>:"/\\\\|?*]', "") %>%
    # Trim trailing spaces and periods
    str_replace_all("[ \\.]+$", "") %>%
    # Optionally trim leading/trailing whitespace
    str_trim()
}

create_description <- function(loop_df) {
  loop_meta <- loop_df[1, ]
  # Dynamically collect location fields
  location_parts <- c()
  if ("Land" %in% names(loop_df)) {
    land <- toString(unique(loop_df$Land))
    split_folders <- stringr::str_split(land, ", ")[[1]]
    if (land == "Main Street U.S.A.") land <- "Main Street, U.S.A."
    location_parts <- c(location_parts, glue("**Land(s)**: {land}"))
  }
  if ("Area" %in% names(loop_df)) {
    area <- toString(unique(loop_df$Area))
    split_folders <- stringr::str_split(area, ", ")[[1]]
    location_parts <- c(location_parts, glue("**Area**: {area}"))
  }
  if ("District/Neighborhood" %in% names(loop_df)) {
    district <- toString(unique(loop_df$`District/Neighborhood`))
    if (district != "NA") location_parts <- 
        c(location_parts, glue("**District/Neighborhood**: {district}"))
  }
  
  loop_length <- loop_meta$`Loop Total Length`
  dates <- unique(loop_df$Dates)
  holiday <- toString(na.omit(unique(loop_df$`Holiday/Special Event`)))
  loop_notes <- loop_meta$`Loop Notes`
  
  # Build Loop description dynamically, omit fields if NA or empty
  description_lines <- c(
    location_parts,
    if (!is.na(loop_length) && loop_length != "") glue("**Loop Total Length**: {loop_length}"),
    if (!all(is.na(dates)) && any(dates != "")) glue("**Dates**: {toString(dates[!is.na(dates) & dates != ''])}"),
    if (!is.na(holiday) && holiday != "") glue("**Holiday/Special Event**: {holiday}"),
    if (!is.na(loop_notes) && loop_notes != "") glue("{loop_notes}")
  )
  
  loop_description <- paste(description_lines, collapse = "\n\n")
  return(list(loop_description, split_folders))
}

create_tracklist <- function(loop_df) {
  track_lines <- loop_df %>%
    rowwise() %>%
    mutate(
      `Track` = gsub("\n", "", `Track`),
      `Track` = gsub("  ", " ", `Track`),
      track_info = if (!is.na(Track)) {
        artist_part <- if (!is.na(`Track Artist`) && `Track Artist` != "") paste0(" – ", `Track Artist`) else ""
        album_part <- if (!is.na(Album) && Album != "") paste0(" – ", Album) else ""
        paste0(`Track No.`, "\\. ", Track, artist_part, album_part)
      } else "",
      
      track_details = list({
        details <- c()
        if (!is.na(`Loop Track Length`)) details <- c(details, glue("- Loop Track Length: {`Loop Track Length`}"))
        if (!is.na(`Track Notes`))       details <- c(details, glue("- Track Notes: {`Track Notes`}"))
        if (!is.na(`Album Track Number`))details <- c(details, glue("- Album Track Number: {`Album Track Number`}"))
        if (!is.na(`Album Disc Number`)) details <- c(details, glue("- Album Disc Number: {`Album Disc Number`}"))
        if (!is.na(`Album Label`))       details <- c(details, glue("- Album Label: {`Album Label`}"))
        paste(details, collapse = "\n")
      })
    ) %>%
    ungroup() %>%
    mutate(
      entry = ifelse(
        track_info != "",
        paste0(track_info, "\n\n", track_details),  # <-- here: two newlines to get a blank line
        track_details
      )
    ) %>%
    pull(entry)
  
  return(track_lines)
}


create_md <- function(loop_name, loop_db, out_loc) {
  loop_df <- loop_db |> 
    filter(Loop == loop_name) |>
    mutate(across(everything(), url_to_md))
  
  loop_des <- create_description(loop_df)
  loop_description <- loop_des[[1]]
  split_folders <- loop_des[[2]]
  track_lines <- create_tracklist(loop_df)
  
  md <- glue::glue("
# {loop_name}

## Description

{loop_description}

## Tracklist
")
  md_full <- paste(md, paste(track_lines, collapse = "\n\n"), sep = "\n\n")
  
  # Write to Markdown file, nested in land/area folders...
  file_out <- paste0(make_safe_filename(loop_name), ".md")
  write_out_file <- function(this_folder) {
    path_out <- file.path(out_loc, sanitize_folder_name(this_folder))
    if(!dir.exists(path_out)) dir.create(path_out)
    writeLines(md_full, file.path(path_out, file_out))
  }
  if (all(is.na(split_folders))) {
    writeLines(md_full, file.path(path_out, file_out))
  } else sapply(split_folders, write_out_file)
}
