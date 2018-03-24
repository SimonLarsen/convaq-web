library(GenomicRanges)
library(GenomicFeatures)
# other dependencies:
# TxDb.Hsapiens.UCSC.hg38.knownGene
# TxDb.Hsapiens.UCSC.hg19.knownGene
# TxDb.Hsapiens.UCSC.hg18.knownGene
# org.Hs.eg.db
# org.Mm.eg.db

get_genes <- function(regions, species, assembly) {
  if(assembly == "hg38") {
    all.genes <- genes(TxDb.Hsapiens.UCSC.hg38.knownGene::TxDb.Hsapiens.UCSC.hg38.knownGene)
  } else if(assembly == "hg19") {
    all.genes <- genes(TxDb.Hsapiens.UCSC.hg19.knownGene::TxDb.Hsapiens.UCSC.hg19.knownGene)
  } else if(assembly == "hg18") {
    all.genes <- genes(TxDb.Hsapiens.UCSC.hg18.knownGene::TxDb.Hsapiens.UCSC.hg18.knownGene)
  }
  regions[,c("chr","start","end")]
  regions$chr <- paste0("chr", regions$chr)
  
  my.ranges <- makeGRangesFromDataFrame(regions)
  found.genes <- subsetByOverlaps(all.genes, my.ranges)
  
  entrez <- mcols(found.genes)[["gene_id"]]
  
  if(species == "human") {
    library(org.Hs.eg.db)
    egdb <- org.Hs.eg.db
  }
  else if(species == "mouse") {
    library(org.Mm.eg.db)
    egdb <- org.Mm.eg.db
  }
  
  names <- if(length(entrez) > 0) mapIds(egdb, entrez, "SYMBOL", "ENTREZID") else character()
  
  data.frame(
    id = entrez,
    name = names,
    chr = gsub("^chr", "", seqnames(found.genes))
  )
}