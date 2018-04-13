options(shiny.maxRequestSize=100*1024^2)
options(spinner.type=5)

APP_VERSION <- "0.1.0"
    
types.pretty <- c("Gain","Loss","LOH")
types <- tolower(c("Gain","Loss","LOH"))

species <- c(
  "Homo sapiens" = "human",
  "Mus musculus" = "mouse",
  "Rattus norvegicus" = "rat",
  "Other" = "other"
)

assemblies <- list(
  human = c(
    "Dec. 2013 (GRCh38/hg38)" = "hg38",
    "Feb. 2009 (GRCh37/hg19)" = "hg19",
    "Mar. 2006 (NCBI36/hg18)" = "hg18"
  ),
  mouse = c(
    "Dec. 2010 (GRCm38/mm10)" = "mm10",
    "Jul. 2007 (NCBI37/mm9)" = "mm9"
  ),
  rat = c(
    "Jul. 2014 (RGSC 6.0/rn6)" = "rn6"
  ),
  other = c("None" = "None")
)
