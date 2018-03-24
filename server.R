library(shiny)
library(DT)
library(shinyjs)
library(data.table)
library(rconvaq)

shinyServer(function(input, output) {
  summaryTable <- reactiveVal()
  
  currentData <- reactiveVal()
  currentNames <- reactiveVal()
  currentResults <- reactiveVal()
  currentSpecies <- reactiveVal()
  currentAssembly <- reactiveVal()
  currentOverlappingGenes <- reactiveVal()
  emptyResult <- reactiveVal()
  
  observeEvent(input$resetButton, {
    currentData(NULL)
    currentNames(NULL)
    currentResults(NULL)
    currentSpecies(NULL)
    currentAssembly(NULL)
    currentOverlappingGenes(NULL)
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
  
  output$assemblySelect <- renderUI({
    choices <- list(
      human =  c(
        "Dec. 2013 (GRCh38/hg38)" = "hg38",
        "Feb. 2009 (GRCh37/hg19)" = "hg19",
        "Mar. 2006 (NCBI36/hg18)" = "hg18"
      ),
      mouse = c(
        "Dec. 2010 (GRCm38/mm10" = "mm10",
        "Jul. 2007 (NCBI37/mm9)" = "mm9"
      ),
      rat = c(
        "Jul. 2014 (RGSC 6.0/rn6)"
      )
    )
    selectInput("assembly", "Assembly", choices = choices[[input$species]])
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
    
    s1 <- fread(input$file1$datapath, header=TRUE)
    s2 <- fread(input$file2$datapath, header=TRUE)
    
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
    currentNames(c("Disease","Healthy"))
    currentSpecies("human")
    currentAssembly("hg38")
  })
  
  observeEvent(input$submitButton, {
    withProgress(min=0, max=1, value=0, message="Computing results", {
      setProgress(value=0.1, detail="Preparing data")
      data <- currentData()
      s1 <- data[[1]]
      s2 <- data[[2]]
      
      setProgress(value=0.2, detail="Searching for matching regions")
      if(input$modelTabs == "statistical") {
        res <- convaq(s1, s2, model="statistical", name1=input$name1, name2=input$name2, p.cutoff=input$pvalueCutoff, qvalues=input$computeQvalues, qvalues.rep=2000)
      }
      else if(input$modelTabs == "query") {
        pred1 <- paste(input$qcomp1, input$qvalue1/100, input$qeq1, input$qtype1)
        pred2 <- paste(input$qcomp2, input$qvalue2/100, input$qeq2, input$qtype2)
        res <- convaq(s1, s2, model="query", name1=input$name1, name2=input$name2, pred1=pred1, pred2=pred2, qvalues=input$computeQvalues, qvalues.rep=2000)
      }
      setProgress(value=0.9, detail="Preparing output")
      emptyResult(is.na(res))
      currentResults(res)
    })
  })
  
  regionModal <- function(row) {
    results <- currentResults()
    
    chr <- results[row,"chr"]
    start <- results[row,"start"]
    end <- results[row,"end"]
    
    title <- sprintf("%s:%d-%d", chr, start, end)
    infotable <- t(results[row,1:7])
    ucsc_link <- sprintf("https://genome.ucsc.edu/cgi-bin/hgTracks?position=%s:%d-%d&db=%s", chr, start, end, currentAssembly())
    
    modalDialog(
      size = "l",
      title = title,
      easyClose=TRUE,
      footer = modalButton("Close"),
      
      renderTable(infotable, rownames=TRUE, colnames=FALSE),
      a(href=ucsc_link, target="_blank", class="btn btn-primary", "Show in UCSC Genome Browser")
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
      results <- currentResults()[rows,]
      setProgress(value=0.1, detail="Searching for genes overlapping regions")
      genes <- get_genes(results, currentSpecies(), currentAssembly())
      
      currentOverlappingGenes(genes)
      
      setProgress(value=0.9, detail="Preparing output")
      genes[[1]] <- sprintf('<a href="https://www.ncbi.nlm.nih.gov/gene/%s" target=_blank>%s</a>', genes[[1]], genes[[1]])
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
              options = list(
                dom="Bfrtip",
                buttons=list(
                  list(extend="csv",   text="Download CSV"),
                  list(extend="excel", text="Download Excel")
                )
              )
            ))
          ),
          tabPanel("Gene set enrichment",
            h3("Gene set enrichment"),
            selectInput("enrichmentType", "Enrichment type", choices = c(
              "GO Biological process" = "gobp",
              "GO Molecular function" = "gomf",
              "GO Cellular component" = "gocc"
            )),
            actionButton("enrichmentButton", "Run enrichment analysis", styleclass="primary")
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
    showModal(analyzeModal(input$resultsTable_rows_selected))
  })
  
  
  output$summary <- renderTable({
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
  
  output$resultsTable <- renderDT({
    D <- req(currentResults())
    export.cols <- list(columns=seq(1, ncol(D)))
    datatable(
      data.frame(info="<button class='btn btn-xs'><i class='fa fa-question-circle fa-2x'></i></button>", D, check.names=FALSE),
      extensions = c("Buttons","Select"),
      rownames = FALSE,
      escape = FALSE,
      options = list(
        dom="Bfrtip",
        buttons=list(
          list(extend="csv",   text="Download CSV",   exportOptions=export.cols),
          list(extend="excel", text="Download Excel", exportOptions=export.cols),
          "selectAll",
          "selectNone"
        ),
        scrollX=TRUE,
        select=list(style="multiple")
      )
    )
  })
})
