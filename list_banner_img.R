# Directory containing the images
img_dir <- "C:/Users/aubre/Box/Hobbies/dlrml/docs/img/banners"

# Get list of image files (filter for jpg/jpeg/png etc. if needed)
image_files <- list.files(path = img_dir, pattern= ".jpg$",
                          full.names = FALSE)

# Generate JavaScript-style image object strings
js_array <- paste0(
  "    {path: '", "img/banners", "/", image_files, "', position: 'center 50%'}"
)

# Combine into final JavaScript array syntax
js_output <- c(
  "<script>",
  "    // Array of image paths",
  "    var images = [",
  paste(js_array, collapse = ","),
  "    ];"
)

# Print to console (or use writeLines(js_output, "output.js") to save)
writeLines(js_output, "C:/Users/aubre/Box/Hobbies/dlrml/overrides/output.txt",
           useBytes = TRUE)
