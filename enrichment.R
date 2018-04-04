source("make_links.R")

gene_set_enrichment_types <- function(species) {
  out <- list(
    "GO Biological process" = "gobp",
    "GO Molecular function" = "gomf",
    "GO Cellular component" = "gocc",
    "KEGG pathways" = "kegg",
    "Reactome pathways" = "reactome"
  )
  if(species == "human") out <- c(out, list(
    "Disease Ontology" = "do",
    "DisGeNET" = "disgenet"
  ))
  return(out)
}

gene_set_enrichment <- function(genes, species, type, pvalueCutoff, qvalueCutoff) {
  library(DOSE)
  library(clusterProfiler)
  library(ReactomePA)
  
  get_orgdb <- function(x) {
    if(x == "human") "org.Hs.eg.db"
    else if(x == "mouse") "org.Mm.eg.db"
    else if(x == "rat") "org.Rn.eg.db"
    else stop("Could not find annotation database for species ", x)
  }

  if(type == "gobp") {
    enrichGO(genes, OrgDb=get_orgdb(species), ont="BP", pvalueCutoff=pvalueCutoff, qvalueCutoff=qvalueCutoff)
  } else if(type == "gomf") {
    enrichGO(genes, OrgDb=get_orgdb(species), ont="MF", pvalueCutoff=pvalueCutoff, qvalueCutoff=qvalueCutoff)
  } else if(type == "gocc") {
    enrichGO(genes, OrgDb=get_orgdb(species), ont="CC", pvalueCutoff=pvalueCutoff, qvalueCutoff=qvalueCutoff)
  } else if(type == "kegg") {
    enrichKEGG(genes, keyType="ncbi-geneid", organism=species, pvalueCutoff=pvalueCutoff, qvalueCutoff=qvalueCutoff)
  } else if(type == "reactome") {
    enrichPathway(genes, organism=species, pvalueCutoff=pvalueCutoff, qvalueCutoff=qvalueCutoff)
  } else if(type == "do") {
    enrichDO(genes, pvalueCutoff=pvalueCutoff, qvalueCutoff=qvalueCutoff)
  } else if(type == "disgenet") {
    enrichDGN(genes, pvalueCutoff=pvalueCutoff, qvalueCutoff=qvalueCutoff)
  }
}

get_gene_set_enrichment_links <- function(D, type) {
  if(type == "gobp" || type == "gomf" || type == "gocc") {
    D$ID <- make_links(D$ID, "amigo")
  } else if(type == "kegg") {
    D$ID <- make_links(D$ID, "kegg_pathway")
  } else if(type == "reactome") {
    D$ID <- make_links(D$ID, "reactome")
  } else if(type == "do") {
    D$ID <- make_links(D$ID, "do")
  }
  D$geneID <- make_links_list(D$geneID, "ncbi_gene", "/", "/")
  return(D)
}
