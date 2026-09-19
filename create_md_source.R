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
  safe_name <- str_replace_all(name, "\\[[^\\]]*\\]", "") |>       # Remove text in brackets
    str_replace_all("[^A-Za-z0-9]+", "_") |>                       # Replace non-alphanumeric characters with underscores
    str_replace_all("_+", "_") |>                                  # Replace multiple underscores with a single underscore
    str_replace_all("^_|_$", "") |>                                # Remove leading or trailing underscores
    stringr::str_remove_all(",")                                   # Remove commas
  
  if(nchar(safe_name) > 70) safe_name <- stringr::str_trunc(safe_name, 
                                                            70,
                                                            side = "right",
                                                            ellipsis = "")
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
  if (!is.character(x)) return(x)
  vapply(x, url_to_md_one, character(1), USE.NAMES = FALSE)
}

url_to_md_one <- function(text) {
  if (is.na(text) || !nzchar(text)) return(text)
  # Protect existing markdown links with placeholders
  md_link_pat <- "\\[[^]]+\\]\\([^)]+\\)"
  placeholders <- character()
  idx <- 0L
  while (grepl(md_link_pat, text, perl = TRUE)) {
    idx <- idx + 1L
    m <- regexpr(md_link_pat, text, perl = TRUE)
    key <- sprintf("<<MDLINK_%d>>", idx)
    placeholders[key] <- regmatches(text, m)
    regmatches(text, m) <- key
  }
  # Split duplicated URLs pasted together in CSV (e.g. ...post-123https://...)
  # but preserve archive.org URLs with embedded http:// in their path
  text <- gsub(
    "(https?://(?:web\\.)?archive\\.org/web/\\d+/)(https?://)",
    "\\1<<ARCHPROTO>>",
    text, perl = TRUE
  )
  text <- gsub("(https?://[^\\s]+?)(https?://)", "\\1 \\2", text, perl = TRUE)
  text <- gsub("<<ARCHPROTO>>", "http://", text, fixed = TRUE)
  # Deduplicate identical adjacent URLs (copy-paste artifacts in CSV)
  text <- gsub("(https?://\\S+)\\s+\\1", "\\1", text, perl = TRUE)
  bare_pat <- "https?://[^\\s<>\"'\\[\\]()]+"
  hits <- gregexpr(bare_pat, text, perl = TRUE)[[1]]
  if (hits[1] != -1) {
    lengths <- attr(hits, "match.length")
    for (i in rev(seq_along(hits))) {
      start <- hits[i]
      raw <- substr(text, start, start + lengths[i] - 1L)
      url <- sub("[.,;:!?]+$", "", raw)
      trailing <- substring(raw, nchar(url) + 1L)
      repl <- paste0("[", url, "](", url, ")", trailing)
      text <- paste0(
        substr(text, 1L, start - 1L),
        repl,
        substr(text, start + lengths[i], nchar(text))
      )
    }
  }
  for (key in names(placeholders)) {
    text <- sub(key, placeholders[[key]], text, fixed = TRUE)
  }
  # Insert space before (year) that abuts a closing link paren
  text <- gsub("\\)\\(([0-9]{4})\\)", ") (\\1)", text)
  text
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
  if ("Disney Gallery Location" %in% names(loop_df)) {
    location <- toString(unique(loop_df$`Disney Gallery Location`))
    split_folders <- stringr::str_split(location, ", ")[[1]]
    location_parts <- c(location_parts, glue("**Location**: {location}"))
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
    arrange(`Track No.`) |>
    mutate(across(any_of(c("Loop Notes", "Track Notes", "Album", "Loop Total Length")), url_to_md))
  
  loop_des <- create_description(loop_df)
  loop_description <- loop_des[[1]]
  split_folders <- loop_des[[2]]
  track_lines <- create_tracklist(loop_df)
  
  md <- glue::glue("
# {loop_name}

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
