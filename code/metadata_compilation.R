library(tidyverse)
library(readxl)

barcode_fp <- "data/metadata/BarcodeMasterList.xlsx"
metadata_fp <- "data/metadata/osburn10_metadata_eqk.csv"

# read in data
barcodes <- read_xlsx(barcode_fp)
metadata_raw <- read_csv(metadata_fp)

# prep and join barcodes to metadata
metadata <- metadata_raw %>% 
  mutate(`barcode plate` = paste0("BC", `barcode plate`),
    `barcode plate position` =  str_replace(`barcode position`, "(\\d+)([A-Z])", "\\2\\1"),
    sample_name = `sample name`,
    .keep = "unused") %>% 
  select(sample_name, `barcode plate position`, `barcode plate`) %>% 
  left_join(barcodes, by = c("barcode plate", "barcode plate position"))

# save complete metadata file as tsv
write_tsv(metadata, "data/metadata/Osburn10_eqk.tsv")
