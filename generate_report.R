generate_report <- function(species, assembly, filenames, summary_table, results, outfile) {
  info <- list(
    "Species" = species,
    "Assembly" = assembly,
    "Files" = paste0("`", filenames, "`", collapse=", ")
  )
  
  regions <- regions(results)
  
  if(results$model == "statistical") {
    info[["Model"]] <- "Statistical"
    info[["P-value cutoff"]] <- formatC(results$p.cutoff)
    regions$pvalue <- formatC(regions$pvalue, digits=3)
  }
  if(results$model == "query") {
    info[["Predicate 1"]] <- paste0("`", results$pred1, "`")
    info[["Predicate 2"]] <- paste0("`", results$pred2, "`")
  }
  if(results$merge) {
    info[["Merge adjacent regions"]] <- "Yes"
    info[["Merge threshold"]] <- results$merge.threshold
  } else {
    info[["Merge adjacent regions"]] <- "No"
  }
  if(results$qvalues) {
    info[["Q-value repetitions"]] <- formatC(results$qvalues.rep)
    regions$qvalue <- formatC(regions$qvalue, digits=3)
  }
  
  myparams <- list(
    info=info,
    summary_table=summary_table,
    regions=regions
  )
  rmarkdown::render("report_template.Rmd", params=myparams, output_format="pdf_document", output_file=outfile)
}