source("make_links.R")

gene_set_enrichment_types <- function() {
  list(
    "GO Biological process" = "gobp",
    "GO Molecular function" = "gomf",
    "GO Cellular component" = "gocc",
    "Reactome pathways" = "reactome",
    "Disease Ontology" = "do",
    "DisGeNET" = "disgenet"
  )
}

gene_set_enrichment <- function(genes, universe, type, pvalueCutoff, qvalueCutoff) {
  library(DOSE)
  library(clusterProfiler)
  library(ReactomePA)

  if(type == "gobp") {
    enrichGO(genes, universe=universe, OrgDb="org.Hs.eg.db", ont="BP", pvalueCutoff=pvalueCutoff, qvalueCutoff=qvalueCutoff)
  } else if(type == "gomf") {
    enrichGO(genes, universe=universe, OrgDb="org.Hs.eg.db", ont="MF", pvalueCutoff=pvalueCutoff, qvalueCutoff=qvalueCutoff)
  } else if(type == "gocc") {
    enrichGO(genes, universe=universe, OrgDb="org.Hs.eg.db", ont="CC", pvalueCutoff=pvalueCutoff, qvalueCutoff=qvalueCutoff)
  } else if(type == "reactome") {
    enrichPathway(genes, universe=universe, organism="human", pvalueCutoff=pvalueCutoff, qvalueCutoff=qvalueCutoff)
  } else if(type == "do") {
    enrichDO(genes, universe=universe, pvalueCutoff=pvalueCutoff, qvalueCutoff=qvalueCutoff)
  } else if(type == "disgenet") {
    enrichDGN(genes, universe=universe, pvalueCutoff=pvalueCutoff, qvalueCutoff=qvalueCutoff)
  }
}

get_gene_set_enrichment_links <- function(D, type) {
  if(type == "gobp" || type == "gomf" || type == "gocc") {
    D$ID <- make_links(D$ID, "amigo")
  } else if(type == "reactome") {
    D$ID <- make_links(D$ID, "reactome")
  } else if(type == "do") {
    D$ID <- make_links(D$ID, "do")
  }
  D$geneID <- make_links_list(D$geneID, "ncbi_gene", "/", "/")
  return(D)
}
