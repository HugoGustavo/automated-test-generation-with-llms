# ======================================================================
# Heatmap Generator for Systematic Mapping Study
#
# Author: Felipe N. Gaia
# Purpose:
#   Read files named "rq*.txt" (e.g. rq1.txt, RQ2.txt...), extract the
#   Research Question id and publication year from each line, build a
#   Year × RQ frequency matrix and export multiple heatmap variants
#   as PNG and PDF.
#
# Outputs:
#   - PNG and PDF files under "heatmaps_output/"
#   - Printed summary frequency table in the console
#
# Expectations:
#   - Input files must match pattern /^rq[0-9]+\.txt$/ (case-insensitive)
#   - Each non-empty line of each file should end with a 4-digit year (YYYY)
#
# Usage examples:
#   - In RStudio: open script and click Source
#   - From terminal: Rscript generate_heatmaps.R
#
# ======================================================================

# ======================================================================
# Dependencies: install if missing
# ======================================================================
required_pkgs <- c("ggplot2", "dplyr", "stringr", "readr", "tidyr")
for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
  library(pkg, character.only = TRUE)
}

# ======================================================================
# Helper: determine path of the current script in multiple contexts
# - works for: Rscript, source(), RStudio (if available)
# ======================================================================
get_script_path <- function() {
  # 1) When run with Rscript --file=...
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- "--file="
  match_idx <- grep(file_arg, cmd_args)
  if (length(match_idx) > 0) {
    return(normalizePath(sub(file_arg, "", cmd_args[match_idx][1])))
  }
  
  # 2) When sourced via source("script.R")
  if (!is.null(sys.frames()[[1]]$ofile)) {
    return(normalizePath(sys.frames()[[1]]$ofile))
  }
  
  # 3) Try RStudio API (if installed and available)
  if ("rstudioapi" %in% rownames(installed.packages())) {
    try_path <- tryCatch(rstudioapi::getActiveDocumentContext()$path,
                         error = function(e) "")
    if (nzchar(try_path)) {
      return(normalizePath(try_path))
    }
  }
  
  # 4) Give up with a friendly message
  stop("Unable to determine the script path. Please run the script from RStudio, via Rscript, or use source().")
}

# ======================================================================
# Set working directory to script directory (so relative paths are stable)
# ======================================================================
script_path <- get_script_path()
script_dir  <- dirname(script_path)
setwd(script_dir)
message("== Script directory: ", script_dir)

# ======================================================================
# Output directory
# ======================================================================
output_dir <- "heatmaps_output"
if (!dir.exists(output_dir)) dir.create(output_dir)

# ======================================================================
# 1) Locate input files matching rq*.txt (case-insensitive)
# ======================================================================
input_pattern <- "^rq[0-9]+\\.txt$"
input_files <- list.files(pattern = input_pattern, ignore.case = TRUE, full.names = TRUE)

message("== Current working directory ==")
print(getwd())
message("== Found files matching pattern: ", input_pattern)
print(basename(input_files))

if (length(input_files) == 0) {
  stop(paste0("ERROR: No files matching pattern '", input_pattern, "' found in ", getwd()))
}

# ======================================================================
# 2) Read files and extract RQ id and Year from each non-empty line
# ======================================================================
parsed_files <- lapply(input_files, function(fpath) {
  # Extract RQ id from filename (rq + digits)
  rq_id <- stringr::str_extract(basename(fpath), "(?i)(?<=rq)\\d+")
  if (is.na(rq_id)) rq_id <- "0"
  
  lines <- readr::read_lines(fpath)
  lines <- stringr::str_trim(lines)
  lines <- lines[lines != "" & !is.na(lines)]
  
  if (length(lines) == 0) {
    return(data.frame(RQ = character(0), Paper = character(0), Year = integer(0), stringsAsFactors = FALSE))
  }
  
  # Extract 4-digit year at end of each line (YYYY)
  years <- stringr::str_extract(lines, "(19|20)[0-9]{2}$")
  data.frame(
    RQ = paste0("RQ", rq_id),
    Paper = lines,
    Year  = as.integer(years),
    stringsAsFactors = FALSE
  )
})

# Combine into single data.frame
papers_df <- dplyr::bind_rows(parsed_files)

if (nrow(papers_df) == 0) {
  stop("ERROR: No paper entries were parsed from input files.")
}

# ======================================================================
# 3) Build Year × RQ frequency matrix (count occurrences)
# ======================================================================
freq_matrix <- papers_df %>%
  dplyr::filter(!is.na(Year)) %>%
  dplyr::group_by(RQ, Year) %>%
  dplyr::summarise(count = n(), .groups = "drop")

# Fill missing combinations (ensure complete grid)
freq_matrix <- freq_matrix %>%
  tidyr::complete(RQ, Year, fill = list(count = 0)) %>%
  dplyr::arrange(RQ, Year)

# ======================================================================
# 4) Prepare ordered factors for consistent axis ordering
# ======================================================================
rq_numbers <- freq_matrix$RQ %>%
  stringr::str_extract("\\d+") %>%
  as.integer()

rq_levels <- rq_numbers %>%
  sort() %>%
  unique() %>%
  paste0("RQ", .)

# Use reversed RQ levels on y-axis so RQ1 is on top by default in typical plots
freq_matrix$RQ <- factor(freq_matrix$RQ, levels = rev(rq_levels))

year_levels <- freq_matrix$Year %>%
  as.integer() %>%
  sort() %>%
  unique()

freq_matrix$Year <- factor(freq_matrix$Year, levels = year_levels)

# Color scale bounds
min_count <- min(freq_matrix$count, na.rm = TRUE)
max_count <- max(freq_matrix$count, na.rm = TRUE)

# ======================================================================
# 5) Helper: export PNG + PDF for each ggplot object
# ======================================================================
save_plot_variants <- function(plot_obj, name_base, width = 10, height = 6) {
  png_path <- file.path(output_dir, paste0(name_base, ".png"))
  pdf_path <- file.path(output_dir, paste0(name_base, ".pdf"))
  ggsave(png_path, plot_obj, width = width, height = height, dpi = 300)
  ggsave(pdf_path, plot_obj, width = width, height = height)
  message("Saved: ", png_path, " and ", pdf_path)
}

# ======================================================================
# 6) Generate heatmaps: several visual styles
# ======================================================================

# 6.1 Blue gradient (labels hidden for zero)
plot_blue <- ggplot2::ggplot(freq_matrix, ggplot2::aes(x = Year, y = RQ, fill = count)) +
  ggplot2::geom_tile(color = "white") +
  # Add count labels inside each heatmap cell
  ggplot2::geom_text(
    ggplot2::aes(label = ifelse(count == 0, "", count),
                 color = ifelse(count > (min_count + max_count) / 2, "light", "dark")),
    size = 3,
    show.legend = FALSE
  ) +
  ggplot2::scale_color_manual(values = c("dark" = "black", "light" = "white")) +
  ggplot2::scale_fill_gradient(low = "#f7fbff", high = "#08306b", limits = c(min_count, max_count)) +
  ggplot2::labs(title = "Heatmap of Studies", x = "Year", y = "Research Question", fill = "Count") +
  ggplot2::theme_minimal() +
  ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
                 axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

save_plot_variants(plot_blue, "heatmap_year_rq_blue")

# 6.2 Red → Green gradient
plot_red_green <- ggplot2::ggplot(freq_matrix, ggplot2::aes(x = Year, y = RQ, fill = count)) +
  ggplot2::geom_tile(color = "white") +
  ggplot2::scale_fill_gradient(low = "red", high = "green", limits = c(min_count, max_count)) +
  ggplot2::labs(title = "Heatmap of Studies", x = "Year", y = "Research Question", fill = "Count") +
  ggplot2::theme_minimal() +
  ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
                 axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

save_plot_variants(plot_red_green, "heatmap_year_rq_red_green")

# 6.3 Grayscale (colorblind-friendly / print)
plot_gray <- ggplot2::ggplot(freq_matrix, ggplot2::aes(x = Year, y = RQ, fill = count)) +
  ggplot2::geom_tile(color = "black", linewidth = 0.25) +
  ggplot2::scale_fill_gradient(low = "#f0f0f0", high = "#252525", limits = c(min_count, max_count)) +
  ggplot2::labs(title = "Heatmap of Studies", x = "Year", y = "Research Question", fill = "Count") +
  ggplot2::theme_classic() +
  ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
                 axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

save_plot_variants(plot_gray, "heatmap_year_rq_gray")

# 6.4 Viridis palette
if (!requireNamespace("viridis", quietly = TRUE)) install.packages("viridis")
library(viridis)

plot_viridis <- ggplot2::ggplot(freq_matrix, ggplot2::aes(x = Year, y = RQ, fill = count)) +
  ggplot2::geom_tile(color = "white", linewidth = 0.3) +
  viridis::scale_fill_viridis(option = "D", limits = c(min_count, max_count), direction = 1) +
  ggplot2::labs(title = "Heatmap of Studies", x = "Year", y = "Research Question", fill = "Count") +
  ggplot2::theme_minimal() +
  ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
                 axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

save_plot_variants(plot_viridis, "heatmap_year_rq_viridis")

# 6.5 Viridis with swapped axes (RQ on x)
plot_viridis_swapped <- ggplot2::ggplot(freq_matrix, ggplot2::aes(x = RQ, y = Year, fill = count)) +
  ggplot2::geom_tile(color = "white", linewidth = 0.3) +
  # Add numeric labels (including zeros) inside each heatmap cell
  ggplot2::geom_text(ggplot2::aes(label = count), size = 3, color = "black") +
  ggplot2::scale_x_discrete(limits = rev(levels(freq_matrix$RQ))) +
  viridis::scale_fill_viridis(option = "D", limits = c(min_count, max_count), direction = 1) +
  ggplot2::labs(title = "Heatmap of Studies", x = "Research Question", y = "Year", fill = "Count") +
  ggplot2::theme_minimal() +
  ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
                 axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

save_plot_variants(plot_viridis_swapped, "heatmap_rq_year_viridis_swapped")

# 6.6 Blue with swapped axes
plot_blue_swapped <- ggplot2::ggplot(freq_matrix, ggplot2::aes(x = RQ, y = Year, fill = count)) +
  ggplot2::geom_tile(color = "white", linewidth = 0.3) +
  ggplot2::geom_text(ggplot2::aes(label = ifelse(count == 0, "0", count),
                                  color = ifelse(count > (min_count + max_count) / 2, "light", "dark")),
                     size = 3, show.legend = FALSE) +
  ggplot2::scale_color_manual(values = c("dark" = "black", "light" = "white")) +
  ggplot2::scale_x_discrete(limits = rev(levels(freq_matrix$RQ))) +
  ggplot2::scale_fill_gradient(low = "#f7fbff", high = "#08306b", limits = c(min_count, max_count)) +
  ggplot2::labs(title = "Heatmap of Studies", x = "Research Question", y = "Year", fill = "Count") +
  ggplot2::theme_minimal() +
  ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
                 axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

save_plot_variants(plot_blue_swapped, "heatmap_rq_year_blue_swapped")

# ======================================================================
# 7) Final: print summary table and completion message
# ======================================================================
print(freq_matrix)
message("Year × RQ heatmaps saved to: ", normalizePath(output_dir))

# Optionally show a compact session info for reproducibility (uncomment if needed)
# message(sessionInfo())
