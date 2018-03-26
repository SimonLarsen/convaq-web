get_genes <- function(regions, species, assembly) {
  library(GenomicRanges)
  library(GenomicFeatures)
  library(data.table)
  
  D <- fread(sprintf("data/genes/%s.csv", assembly), header=TRUE, colClasses=c("numeric","numeric","character","character"))
  all.genes <- makeGRangesFromDataFrame(D, keep.extra.columns=TRUE)
  
  regions[,c("chr","start","end")]
  my.ranges <- makeGRangesFromDataFrame(regions)
  
  found.genes <- subsetByOverlaps(all.genes, my.ranges)
  entrez <- mcols(found.genes)[["gene"]]
  
  if(species == "human") {
    library(org.Hs.eg.db)
    egdb <- org.Hs.eg.db
  }
  else if(species == "mouse") {
    library(org.Mm.eg.db)
    egdb <- org.Mm.eg.db
  }
  else if(species == "rat") {
    library(org.Rn.eg.db)
    egdb <- org.Rn.eg.db
  }
  
  names <- if(length(entrez) > 0) mapIds(egdb, entrez, "SYMBOL", "ENTREZID") else character()
  
  data.frame(
    id = entrez,
    name = names,
    chr = seqnames(found.genes)
  )
}