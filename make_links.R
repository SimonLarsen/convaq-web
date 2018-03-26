make_links <- function(ids, type) {
  link <- switch(type,
    amigo = "http://amigo.geneontology.org/amigo/term/%s",
    reactome = "https://reactome.org/content/detail/%s",
    do = "http://disease-ontology.org/term/%s",
    drugbank = "https://www.drugbank.ca/drugs/%s",
    ncbi_gene = "https://www.ncbi.nlm.nih.gov/gene/%s",
    ttd = "https://db.idrblab.org/ttd/drug/%s",
    pubchem_cid = "https://pubchem.ncbi.nlm.nih.gov/compound/%s",
    pubchem_sid = "https://pubchem.ncbi.nlm.nih.gov/substance/%s",
    mirtarbase = "http://mirtarbase.mbc.nctu.edu.tw/php/detail.php?mirtid=%s",
    pubmed = "https://www.ncbi.nlm.nih.gov/pubmed/?term=%s",
    kegg_drug = "http://www.genome.jp/dbget-bin/www_bget?%s"
  )
  fmt <- sprintf("<a href=\"%s\" target=_blank>%%s</a>", link)
  sapply(ids, function(x) if(is.na(x)) NA else sprintf(fmt, x, x))
}

make_links_list <- function(ids, type, separator="/", collapse="/") {
  sapply(ids, function(x) {
    if(is.na(x)) NA
    else {
      y <- unlist(strsplit(x, separator))
      paste(make_links(y, type), collapse=collapse)
    }
  })
}
