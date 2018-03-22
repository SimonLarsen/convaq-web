library(shiny)
library(data.table)
library(rconvaq)

shinyServer(function(input, output) {
  summaryTable <- reactiveVal()
  
  currentData <- reactiveVal()
  currentNames <- reactiveVal()
  currentResults <- reactiveVal()
  
  output$hasData <- reactive({
    req(currentData())
    return(TRUE)
  })
  outputOptions(output, "hasData", suspendWhenHidden=FALSE)
  
  observeEvent(input$uploadButton, {
    s1 <- fread(input$file1$datapath, header=TRUE)
    s2 <- fread(input$file2$datapath, header=TRUE)
    
    currentData(list(s1, s2))
    currentNames(c(input$name1, input$name2))
  })
  
  observeEvent(input$useExampleData, {
    s1 <- fread("data/disease.csv")
    s2 <- fread("data/healthy.csv")
    
    currentData(list(s1, s2))
    currentNames(c("Disease","Healthy"))
  })
  
  observeEvent(input$submitButton, {
    data <- currentData()
    s1 <- data[[1]]
    s2 <- data[[2]]
    
    if(input$modelTabs == "statistical") {
      res <- convaq(s1, s2, model="statistical", name1=input$name1, name2=input$name2, p.cutoff=input$pvalueCutoff, qvalues=input$computeQvalues, qvalues.rep=2000)
    }
    else if(input$modelTabs == "query") {
      pred1 <- paste(input$qcomp1, input$qvalue1/100, input$qeq1, input$qtype1)
      pred2 <- paste(input$qcomp2, input$qvalue2/100, input$qeq2, input$qtype2)
      res <- convaq(s1, s2, model="query", name1=input$name1, name2=input$name2, pred1=pred1, pred2=pred2, qvalues=input$computeQvalues, qvalues.rep=2000)
    }
    currentResults(res)
  })
  
  output$summary <- renderTable({
    data <- req(currentData())
    
    data.frame(
      `Group name`=currentNames(),
      `No. patients`=c(length(unique(data[[1]]$patient)), length(unique(data[[2]]$patient))),
      `No. segments`=c(nrow(data[[1]]), nrow(data[[2]])),
      check.names = FALSE
    )
  })
  
  output$resultsTable <- renderDataTable(
    req(currentResults()),
    options=list(
      scrollX=TRUE,
      pageLength=10
    )
  )
})
