library(shiny)
library(DT)
library(shinyjs)
library(data.table)
library(convaq)

source("make_links.R")
source("enrichment.R")
source("generate_report.R")

read_data <- function(path) {
  lpath <- tolower(path)
  if(endsWith(lpath, ".xlsx")) {
    library(openxlsx)
    data.table(read.xlsx(path, colNames=TRUE, rowNames=FALSE, detectDates=FALSE, check.names=FALSE))
  } else {
    fread(path, header=TRUE)
  }
}

shinyServer(function(input, output) {
  currentData <- reactiveVal()
  currentFilenames <- reactiveVal()
  currentNames <- reactiveVal()
  currentResults <- reactiveVal()
  currentSpecies <- reactiveVal()
  currentAssembly <- reactiveVal()
  currentOverlappingGenes <- reactiveVal()
  currentEnrichmentResults <- reactiveVal()
  emptyResult <- reactiveVal()
  
  observeEvent(input$resetButton, {
    currentData(NULL)
    currentFilenames(NULL)
    currentNames(NULL)
    currentResults(NULL)
    currentSpecies(NULL)
    currentAssembly(NULL)
    currentOverlappingGenes(NULL)
    currentEnrichmentResults(NULL)
    emptyResult(NULL)
  })
  
  output$hasData <- reactive({
    req(currentData())
    return(TRUE)
  })
  outputOptions(output, "hasData", suspendWhenHidden=FALSE)
  
  output$hasResults <- reactive({
    req(currentResults())
    return(TRUE)
  })
  outputOptions(output, "hasResults", suspendWhenHidden=FALSE)
  
  output$gotEmptyResult <- reactive({
    return(emptyResult())
  })
  outputOptions(output, "gotEmptyResult", suspendWhenHidden=FALSE)
  
  output$hasEnrichmentResults <- reactive({
    req(currentEnrichmentResults())
    return(TRUE)
  })
  outputOptions(output, "hasEnrichmentResults", suspendWhenHidden=FALSE)
  
  output$group1Name <- renderText(currentNames()[1])
  output$group2Name <- renderText(currentNames()[2])
  
  output$assemblySelect <- renderUI({
    selectInput("assembly", "Assembly", choices = assemblies[[input$species]])
  })
  
  observeEvent(input$uploadButton, {
    if(!isTruthy(input$file1)) {
      alert("Missing segment file for group 1.")
      return()
    }
    if(!isTruthy(input$file2)) {
      alert("Missing segment file for group 2.")
      return()
    }
    
    # read segment files and set column names
    s1 <- tryCatch(
      read_data(input$file1$datapath),
      error = function(e) { alert(paste0("File 1 is malformed: ", e$message)); return(NULL) }
    )
    s2 <- tryCatch(
      read_data(input$file2$datapath),
      error = function(e) { alert(paste0("File 2 is malformed: ", e$message)); return(NULL) }
    )
    if(is.null(s1) || is.null(s2)) return()
    if(ncol(s1) < 5) { alert("File 1 does not have 5 columns."); return() }
    if(ncol(s2) < 5) { alert("File 2 does not have 5 columns."); return() }
    colnames(s1) <- c("patient","chr","start","end","type")
    colnames(s2) <- c("patient","chr","start","end","type")
    
    fix_types <- function(x, filenum) {
      x2 <- types.pretty[match(tolower(x), types)]
      bad.index <- which(is.na(x2))
      bad.types <- unique(x[bad.index])
      if(length(bad.types) > 0) {
        alert(sprintf("Unrecognized segment type(s) in file %d: %s", filenum, paste0(bad.types, collapse=", ")))
        return(NULL)
      }
      return(x2)
    }
    
    types1 <- fix_types(s1$type, 1)
    types2 <- fix_types(s2$type, 2)
    if(is.null(types1) || is.null(types2)) {
      return()
    }
    s1$type <- types1
    s2$type <- types2
    
    # remove "chr" prefix from chromosomes if present
    s1$chr <- gsub("^chr", "", s1$chr)
    s2$chr <- gsub("^chr", "", s2$chr)
    
    # update reactive values
    currentData(list(s1, s2))
    currentFilenames(c(input$file1$name, input$file2$name))
    currentNames(c(input$name1, input$name2))
    currentSpecies(input$species)
    currentAssembly(input$assembly)
  })
  
  observeEvent(input$useExampleData, {
    s1 <- fread("data/disease.csv")
    s2 <- fread("data/healthy.csv")
    
    types.pretty <- c("Gain","Loss","LOH")
    types <- tolower(c("Gain","Loss","LOH"))
    
    currentData(list(s1, s2))
    currentFilenames(c("disease.csv","healthy.csv"))
    currentNames(c("Disease","Healthy"))
    currentSpecies("human")
    currentAssembly("hg38")
  })
  
  observeEvent(input$submitButton, {
    withProgress(min=0, max=1, value=0, message="Computing results", {
      setProgress(value=0.1, detail="Preparing data")
      data <- currentData()
      group.names <- currentNames()
      s1 <- data[[1]]
      s2 <- data[[2]]
      
      setProgress(value=0.2, detail="Searching for matching regions")
      if(input$modelTabs == "statistical") {
        res <- convaq(
          s1, s2, model="statistical",
          name1=group.names[1], name2=group.names[2],
          merge=input$merge, merge.threshold=input$mergeThreshold,
          p.cutoff=input$pvalueCutoff,
          qvalues=input$computeQvalues
        )
      }
      else if(input$modelTabs == "query") {
        pred1 <- paste(input$qcomp1, input$qvalue1/100, input$qeq1, input$qtype1)
        pred2 <- paste(input$qcomp2, input$qvalue2/100, input$qeq2, input$qtype2)
        res <- convaq(
          s1, s2, model="query",
          name1=group.names[1], name2=group.names[2],
          merge=input$merge, merge.threshold=input$mergeThreshold,
          pred1=pred1, pred2=pred2,
          qvalues=input$computeQvalues
        )
      }
      setProgress(value=0.9, detail="Preparing output")
      emptyResult(nrow(res$regions) == 0)
      currentResults(res)
    })
  })
  
  regionModal <- function(row) {
    results <- currentResults()
    regions <- results$regions
    
    chr <- regions[row,"chr"]
    start <- regions[row,"start"]
    end <- regions[row,"end"]
    
    ucsc_link <- sprintf("https://genome.ucsc.edu/cgi-bin/hgTracks?position=%s:%d-%d&db=%s", chr, start, end, currentAssembly())
    
    summary_table <- regions(results)[row,]
    if(!is.null(summary_table$pvalue)) summary_table$pvalue <- formatC(summary_table$pvalue)
    if(!is.null(summary_table$qvalue)) summary_table$qvalue <- formatC(summary_table$qvalue)
    
    freq <- frequencies(results)[row,]
    freq <- rbind(
      setNames(freq[,1:3], types.pretty),
      setNames(freq[,4:6], types.pretty)
    )
    rownames(freq) <- currentNames()
    
    states1 <- sapply(results$state[[row]][[1]], paste0, collapse=",")
    states2 <- sapply(results$state[[row]][[2]], paste0, collapse=",")
    states1 <- data.frame(patient=names(states1), state=states1)
    states2 <- data.frame(patient=names(states2), state=states2)
    
    modalDialog(
      size = "l",
      title = "Inspect region",
      easyClose=TRUE,
      footer = modalButton("Close"),
      
      h4("Summary"),
      renderTable(summary_table, rownames=FALSE, colnames=TRUE),
      renderTable(freq, rownames=TRUE, colnames=TRUE),
      h4("Patient/sample states"),
      fluidRow(
        column(width=6,
          tags$label(results$name1),
          renderDT(datatable(states1, rownames=FALSE, options=list(scrollY="200px", searching=FALSE, paging=FALSE)), server=FALSE)
        ),
        column(width=6,
          tags$label(results$name2),
          renderDT(datatable(states2, rownames=FALSE, options=list(scrollY="200px", searching=FALSE, paging=FALSE)), server=FALSE)
        )
      ),
      if(currentSpecies() != "other") {
        tagList(
          h4("Genome browser"),
          a(href=ucsc_link, target="_blank", class="btn btn-primary", "Show region in UCSC Genome Browser")
        )
      }
    )
  }
    
  observeEvent(input$resultsTable_cell_clicked, {
    event <- req(input$resultsTable_cell_clicked)
    if(length(event) == 0) return()
    if(event$col == 0) {
      showModal(regionModal(event$row))
    }
  })
  
  analyzeModal <- function(rows) {
    withProgress(value=0, min=0, max=1, message="Finding overlapping genes", {
      regions <- currentResults()$regions[rows,]
      setProgress(value=0.1, detail="Searching for genes overlapping regions")
      genes <- get_genes(regions, currentSpecies(), currentAssembly())
      
      currentOverlappingGenes(genes)
      
      setProgress(value=0.9, detail="Preparing output")
      genes[[1]] <- make_links(genes[[1]], "ncbi_gene")
      colnames(genes)[1] <- "Entrez ID"
      
      modalDialog(
        size = "l",
        title = "Analyze regions",
        easyClose = TRUE,
        footer = modalButton("Close"),
        
        tabsetPanel(
          tabPanel("Overlapping genes",
            h3("Overlapping genes"),
            renderDT(datatable(genes, rownames=FALSE, selection="none", escape=FALSE,
              extensions = "Buttons",
              options = list(
                dom="Bfrtip",
                buttons=list(
                  list(extend="csv",   text="Download CSV",   filename="genes"),
                  list(extend="excel", text="Download Excel", filename="genes", title=NULL)
                )
              )
            ), server = FALSE)
          ),
          tabPanel("Gene set enrichment",
            h3("Gene set enrichment"),
            fluidRow(
              column(width=4, selectInput("enrichmentType", "Enrichment type", choices = gene_set_enrichment_types(currentSpecies()))),
              column(width=4, numericInput("enrichmentPvalueCutoff", "p-value cutoff", value=0.05, min=0, step=0.01, max=1)),
              column(width=4, numericInput("enrichmentQvalueCutoff", "q-value cutoff", value=0.2, min=0, step=0.01, max=1))
            ),
            actionButton("enrichmentButton", "Run enrichment analysis", styleclass="primary"),
            conditionalPanel("output.hasEnrichmentResults", {
              tagList(
                hr(),
                tabsetPanel(
                  tabPanel("Table",
                    DTOutput("enrichmentResultsTable")
                  ),
                  tabPanel("Dot plot",
                    plotOutput("enrichmentDotplot"),
                    p(class="text-muted text-center", "Only the top 20 most significant results will be shown.")
                  )
                )
              )
            })
          )
        )
      )
    })
  }
  
  observeEvent(input$analyzeRegionsButton, {
    if(!isTruthy(input$resultsTable_rows_selected)) {
      alert("Please select at least one row for analysis.")
      return()
    }
    if(currentSpecies() == "other") {
      alert("Cannot perform analysis with unknown species.")
      return()
    }
    currentEnrichmentResults(NULL)
    showModal(analyzeModal(input$resultsTable_rows_selected))
  })
  
  output$summaryText <- renderUI({
    HTML(sprintf("<p><b>Species</b>: %s<br><b>Assembly</b>: %s<br><b>Files</b>: %s</p>", currentSpeciesName(), currentAssemblyName(), paste0(currentFilenames(), collapse=", ")))
  })
  
  summaryTable <- reactive({
    data <- req(currentData())
    agg1 <- aggregate(end-start+1~type, data=data[[1]], FUN=sum)
    agg2 <- aggregate(end-start+1~type, data=data[[2]], FUN=sum)
    
    cts1 <- setNames(agg1[,2], agg1[,1])
    cts2 <- setNames(agg2[,2], agg2[,1])
    
    named.zeros <- setNames(rep(0, length(types)), types.pretty)
    cts1 <- pmax(named.zeros, cts1[types.pretty], na.rm=TRUE)
    cts2 <- pmax(named.zeros, cts2[types.pretty], na.rm=TRUE)
    
    data.frame(
      `Group name`=currentNames(),
      `No. patients`=c(length(unique(data[[1]]$patient)), length(unique(data[[2]]$patient))),
      `No. segments`=c(nrow(data[[1]]), nrow(data[[2]])),
      `Gain coverage (BP)` = c(cts1["Gain"], cts2["Gain"]),
      `Loss coverage (BP)` = c(cts1["Loss"], cts2["Loss"]),
      `LOH coverage (BP)`  = c(cts1["LOH"],  cts2["LOH"]),
      check.names = FALSE
    )
  })
  
  output$summaryTable <- renderTable(summaryTable())
  
  output$resultsTable <- renderDT({
    results <- req(currentResults())
    datatable(
      data.frame(info='<button class="btn btn-default btn-sm" type="button"><i class="fa fa-search fa-1-5x"></i></button>', regions(results), check.names=FALSE),
      rownames = FALSE,
      escape = FALSE,
      selection = "multiple",
      options = list(scrollX=TRUE)
    ) %>% formatSignif(c(if(results$model == "statistical") "pvalue", if(results$qvalues) "qvalue"), digits=3)
  }, server=FALSE)
  
  observeEvent(input$enrichmentButton, {
    withProgress(value=0, min=0, max=1, message="Gene set enrichment", {
      setProgress(value=0.1, detail="Preparing data")
      genes <- currentOverlappingGenes()[[1]]
      setProgress(value=0.2, detail="Finding enriched gene sets")
      res <- gene_set_enrichment(genes, currentSpecies(), input$enrichmentType, input$enrichmentPvalueCutoff, input$enrichmentQvalueCutoff)
      setProgress(value=0.9, detail="Preparing output")
      currentEnrichmentResults(res)
    })
  })
  
  output$enrichmentResultsTable <- renderDT({
    D <- as.data.frame(req(currentEnrichmentResults()))
    D <- get_gene_set_enrichment_links(D, isolate(input$enrichmentType))
    datatable(
      D,
      selection = "none",
      rownames = FALSE,
      escape = FALSE,
      extensions = "Buttons",
      options = list(
        scrollX = TRUE,
        dom="Bfrtip",
        buttons=list(
          list(extend="csv",   text="Download CSV",   filename="enrichment"),
          list(extend="excel", text="Download Excel", filename="enrichment", title=NULL)
        )
      )
    ) %>% formatSignif(c("pvalue","p.adjust","qvalue"), digits=3)
  }, server=FALSE)
  
  output$enrichmentDotplot <- renderPlot({
    DOSE::dotplot(req(currentEnrichmentResults()), showCategory=20)
  })
  
  get_full_results <- function(){
    results <- currentResults()
    cbind(results$regions, frequencies(results), states(results))
  }
  
  output$downloadResultsCSV <- downloadHandler(
    filename = "results.csv",
    content = function(file) {
      write.csv(get_full_results(), file=file, row.names=FALSE, na="")
    }
  )
  
  output$downloadResultsExcel <- downloadHandler(
    filename = "results.xlsx",
    content = function(file) {
      library(openxlsx)
      write.xlsx(get_full_results(), file=file, row.names=FALSE, keepNA=FALSE)
    }
  )
  
  output$downloadResultsPDF <- downloadHandler(
    filename = "report.pdf",
    content = function(file) {
      generate_report(currentSpeciesName(), currentAssemblyName(), currentFilenames(), summaryTable(), currentResults(), file)
    }
  )
  
  currentSpeciesName <- function() {
    names(which(species == req(currentSpecies())))
  }
  
  currentAssemblyName = function() {
    names(which(assemblies[[req(currentSpecies())]] == req(currentAssembly())))
  }
})
