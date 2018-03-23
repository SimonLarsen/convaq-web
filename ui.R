library(shiny)
library(shinyjs)
library(shinysky)

make_panel <- function(..., heading=NULL) {
  div(class="panel panel-default",
      if(!is.null(heading)) div(class="panel-heading", heading),
      div(class="panel-body", ...)
  )
}

shinyUI(navbarPage("CoNVaQ", inverse=TRUE, fluid=FALSE, selected="Get started", theme="style.css",
  footer=column(width=12, hr(), p(sprintf("CoNVaQ version %s", APP_VERSION))),
  useShinyjs(),
  tabPanel("Home",
    div(class="page-header", h1("CoNVaQ"))
  ),
  tabPanel("Get started",
    conditionalPanel("output.hasData != true",
      div(class="page-header", h1("Upload data")),
      p("Select the species and genome assembly of interest, then upload sample files for each group.
         For information on how to structure the data, see the synthetic example data set and the file format specification."),
      div(class="alert alert-info",
        span("Want to try out CoNVaQ without uploading data?", style="margin-right:10px"),
        actionButton("useExampleData", "Use example data", styleclass="primary")
      ),
      make_panel(
        fluidRow(
          column(width=6,
            selectInput("species", "Species", choices = c(
              "Homo sapiens" = "human",
              "Mus musculus" = "mouse",
              "Rattus norvegicus" = "rat"
            ))
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
      actionButton("uploadButton", "Submit", styleclass="primary")
    ),

    conditionalPanel("output.hasData == true",
      div(class="page-header", h1("Analysis")),
      actionButton("resetButton", "Start new analysis", styleclass="primary"),
      span(class="text-muted", style="margin-left: 20px", "Press here to start over with a new data set."),
      
      hr(),
      
      h2("Data set summary"),
      tableOutput("summary"),
      
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
            make_panel(heading="Predicate: Group 1",
              fluidRow(
                column(width=2, selectInput("qcomp1", "", choices=c("At least"=">=", "At most"="<="))),
                column(width=5, sliderInput("qvalue1", "", value=50, min=0, max=100, post="%")),
                column(width=3, selectInput("qeq1", "", choices=c("equal to"="==", "not equal to"="!="))),
                column(width=2, selectInput("qtype1", "", choices=c("Gain","Loss","LOH","Normal")))
              )
            ),
            make_panel(heading="Predicate: Group2",
              fluidRow(
                column(width=2, selectInput("qcomp2", "", choices=c("At least"=">=", "At most"="<="))),
                column(width=5, sliderInput("qvalue2", "", value=50, min=0, max=100, post="%")),
                column(width=3, selectInput("qeq2", "", choices=c("equal to"="==", "not equal to"="!="))),
                column(width=2, selectInput("qtype2", "", choices=c("Gain","Loss","LOH","Normal")))
              )
            )
          )
        ),
        hr(),
        checkboxInput("computeQvalues", tags$b("Compute q-values"), value=TRUE),
        actionButton("submitButton", "Run analysis", styleclass="primary")
      ),
      
      hr(),
      
      h2("Results"),
      conditionalPanel("output.gotEmptyResult == true",
        div(class="alert alert-info", "No matching regions found.")
      ),
      conditionalPanel("output.hasResults == true",
        dataTableOutput("resultsTable"),
        downloadButton("downloadResultsTableCSV", "Download table (CSV)"),
        downloadButton("downloadResultsTableExcel", "Download table (Excel)")
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
))
