
# Script to execute MD file creation

# Source functions ----
stem <- "C:/Users/aubre/Box/Hobbies/dlrml"
source(file.path(stem, "create_md_source.R"))

# Iterate across databases ----

iterate_venues <- function(x) {
  file_name <- list.files(file.path(stem, "assets"),
                          pattern = paste0("^", x, ".*\\.csv$"),
                          full.names = TRUE)
  loop_db <- read_csv(file_name, show_col_types = FALSE)
  
  out_loc <- file.path(stem, "docs", "explore", x)
  if(dir.exists(out_loc)) unlink(out_loc, recursive = TRUE, force = TRUE)
  dir.create(out_loc)
  
  plyr::a_ply(unique(loop_db$Loop), 1, create_md, loop_db, 
              out_loc,
              .progress = "text")
}

now <- Sys.time()

iterate_venues("Disneyland")
iterate_venues("DCA")
iterate_venues("Other")

now -Sys.time()