library(shiny)
library(shinysky)

shinyUI(navbarPage("CoNVaQ", inverse=TRUE, fluid=TRUE, selected="Start analysis",
  tabPanel("Home",
    div(class="page-header", h2("CoNVaQ"))
  ),
  tabPanel("Start analysis",
    div(class="page-header", h2("Analysis")),
    sidebarLayout(
      sidebarPanel(width=3,
        h4("Group 1"),
        textInput("name1", "Name", value="Group 1"),
        fileInput("file1", "File"),
        h4("Group 2"),
        textInput("name2", "Name", value="Group 2"),
        fileInput("file2", "File"),
        selectInput("species", "Species", choices = c(
          "Homo sapiens" = "human", "Mus musculus" = "mouse"
        )),
        selectInput("assembly", "Assembly", choices = c(
          "Dec. 2013 (GRCh38/hg38)" = "hg38",
          "Feb. 2009 (GRCh37/hg19)" = "hg19",
          "Mar. 2006 (NCBI36/hg18)" = "hg18"
        )),
        actionButton("uploadButton", "Upload files", styleclass="primary"),
        actionButton("useExampleData", "Use example data", styleclass="primary")
      ),

      mainPanel(conditionalPanel("output.hasData == true",
        h2("Summary"),
        tableOutput("summary"),
        
        h2("Model"),
        div(
          tabsetPanel(id="modelTabs",
            tabPanel("Statistical model", value="statistical",
              h4("Parameters"),
              numericInput("pvalueCutoff", "P-value cutoff", value = 0.05, min=0, max=1)
            ),
            tabPanel("Query model", value="query",
              h4("Group 1"),
              fluidRow(
                column(width=2, selectInput("qcomp1", "", choices=c("At least"=">=", "At most"="<="))),
                column(width=5, sliderInput("qvalue1", "", value=50, min=0, max=100, post="%")),
                column(width=3, selectInput("qeq1", "", choices=c("equal to"="==", "not equal to"="!="))),
                column(width=2, selectInput("qtype1", "", choices=c("Gain","Loss","LOH","Normal")))
              ),
              hr(),
              h4("Group 2"),
              fluidRow(
                column(width=2, selectInput("qcomp2", "", choices=c("At least"=">=", "At most"="<="))),
                column(width=5, sliderInput("qvalue2", "", value=50, min=0, max=100, post="%")),
                column(width=3, selectInput("qeq2", "", choices=c("equal to"="==", "not equal to"="!="))),
                column(width=2, selectInput("qtype2", "", choices=c("Gain","Loss","LOH","Normal")))
              )
            )
          ),
          hr(),
          checkboxInput("computeQvalues", tags$b("Compute q-values"), value=TRUE),
          actionButton("submitButton", "Run analysis", styleclass="primary")
        ),
        
        hr(),
        
        h2("Results"),
        dataTableOutput("resultsTable")
      )
    ))
  ),
  tabPanel("Guide",
    div(class="page-header", h2("Guide")),
    includeMarkdown("guide.md")
  ),
  tabPanel("About",
    div(class="page-header", h2("About")),
    includeMarkdown("about.md")
  )
))
