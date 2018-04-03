library(shiny)
library(shinyjs)
library(DT)

source("get_genes.R")

make_panel <- function(..., heading=NULL) {
  div(class="panel panel-default",
      if(!is.null(heading)) div(class="panel-heading", heading),
      div(class="panel-body", ...)
  )
}

shinyUI(
  navbarPage("CoNVaQ", inverse=FALSE, fluid=FALSE, theme="style.css",
    footer=column(width=12, hr(), p(sprintf("CoNVaQ version %s", APP_VERSION))),
    tabPanel("Home",
      useShinyjs(),
      tags$head(
        #tags$link(rel="stylesheet", href="font-awesome.min.css", type="text/css"), # not necessary as long as downloadButton is used
        tags$script(src="convaq.js", type="text/javascript")
      ),
      div(class="page-header", h1("CoNVaQ")),
      includeMarkdown("index.md")
    ),
    tabPanel("Get started",
      conditionalPanel("output.hasData != true",
        div(class="page-header", h1("Upload data")),
        p("Select the species and genome assembly of interest, then upload sample files for each group.
           For information on how to structure the data, see the synthetic example data set and the file format specification."),
        div(class="alert alert-info",
          span("Want to try out CoNVaQ without uploading data?", style="margin-right:10px"),
          actionButton("useExampleData", "Use example data", class="btn-primary")
        ),
        make_panel(
          fluidRow(
            column(width=6,
              selectInput("species", "Species", choices=species)
            ),
            column(width=6,
              uiOutput("assemblySelect")
            )
          )
        ),
        fluidRow(
          column(width=6,
            make_panel(heading="Group 1",
              textInput("name1", "Name", value="Group 1"),
              fileInput("file1", "File")
            )
          ),
          column(width=6,
            make_panel(heading="Group 2",
              textInput("name2", "Name", value="Group 2"),
              fileInput("file2", "File")
            )
          )
        ),
        p(class="text-muted", "Please wait for files to finish uploading before hitting Submit."),
        actionButton("uploadButton", "Submit", class="btn-primary btn-lg")
      ),

      conditionalPanel("output.hasData == true",
        div(class="page-header", h1("Analysis")),
        actionButton("resetButton", "Start new analysis", class="btn-primary"),
        span(class="text-muted", style="margin-left: 20px", "Press here to start over with a new data set."),
        
        hr(),
        
        h2("Data set summary"),
        uiOutput("summaryText"),
        tableOutput("summaryTable"),
        
        h2("Model"),
        div(
          p("Choose the model to use below."),
          tabsetPanel(id="modelTabs", type="pills",
            tabPanel("Statistical model", value="statistical",
              make_panel(heading="Parameters",
                numericInput("pvalueCutoff", "P-value cutoff", value = 0.05, min=0, max=1)
              )
            ),
            tabPanel("Query model", value="query",
              make_panel(heading=tagList("Predicate: ", textOutput("group1Name", inline=TRUE)),
                fluidRow(
                  column(width=2, selectInput("qcomp1", "", choices=c("At least"=">=", "At most"="<="))),
                  column(width=5, sliderInput("qvalue1", "", value=50, min=0, max=100, post="%")),
                  column(width=3, selectInput("qeq1", "", choices=c("equal to"="==", "not equal to"="!="))),
                  column(width=2, selectInput("qtype1", "", choices=c("Gain","Loss","LOH","Normal")))
                )
              ),
              make_panel(heading=tagList("Predicate: ", textOutput("group2Name", inline=TRUE)),
                fluidRow(
                  column(width=2, selectInput("qcomp2", "", choices=c("At least"=">=", "At most"="<="))),
                  column(width=5, sliderInput("qvalue2", "", value=50, min=0, max=100, post="%")),
                  column(width=3, selectInput("qeq2", "", choices=c("equal to"="==", "not equal to"="!="))),
                  column(width=2, selectInput("qtype2", "", choices=c("Gain","Loss","LOH","Normal")))
                )
              )
            )
          ),
          make_panel(heading="Options",
            p(tags$b("Merging regions")),
            checkboxInput("merge", "Merge adjacent regions", value=FALSE),
            numericInput("mergeThreshold", "within threshold (base pairs)", value=0, min=0, max=Inf),
            hr(),
            checkboxInput("computeQvalues", tags$b("Compute q-values"), value=FALSE),
            p("Compute empirical p-values through permutation tests.", class="text-muted")
          ),
          actionButton("submitButton", "Run analysis", class="btn-primary btn-lg")
        ),
        
        hr(),
        
        conditionalPanel("output.gotEmptyResult == true",
          h2("Results"),
          div(class="alert alert-info", "No matching regions found.")
        ),
        conditionalPanel("output.hasResults == true && output.gotEmptyResult != true",
          h2("Results"),
          tags$ul(
            tags$li(HTML("Click on the <i class='fa fa-search'></i> icon to show detailed information about a region.")),
            tags$li(HTML("Select rows for analysis by clicking on them. Click on a row again to deselect it."))
          ),
          actionButton("analyzeRegionsButton", "Analyze selected regions", class="btn-primary"),
          tags$button("Select all", id="selectAllRowsButton", class="btn btn-default", type="button"),
          tags$button("Deselect all", id="deselectAllRowsButton", class="btn btn-default", type="button"),
          DTOutput("resultsTable"),
          
          h3("Export results"),
          p("Download all regions, including variant frequencies and individual patient states:"),
          downloadButton("downloadResultsCSV", "Download as CSV", class="btn-primary"),
          downloadButton("downloadResultsExcel", "Downloads as Excel", class="btn-primary")
        )
      )
    ),
    tabPanel("Guide",
      div(class="page-header", h1("Guide")),
      includeMarkdown("guide.md")
    ),
    tabPanel("About",
      div(class="page-header", h1("About")),
      includeMarkdown("about.md")
    )
  )
)
