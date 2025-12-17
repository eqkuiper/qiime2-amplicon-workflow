library(tidyverse)

metadata_fp <- "data/metadata/Osburn10_eqk_2.tsv"

metadata_raw <- read_tsv(metadata_fp)

metadata_tidy <- metadata_raw %>% 
  mutate(sample_name = str_replace_all(sample_name, "_", ".")) %>%
  mutate(sample_name = str_replace_all(sample_name, " ", "."))

write_tsv(metadata_tidy, "data/metadata/Osburn10-EQK.tsv")
