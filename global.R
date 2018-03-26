options(shiny.maxRequestSize=100*1024^2)
options(spinner.type=5)

APP_VERSION <- "0.1-preview"
    
types.pretty <- c("Gain","Loss","LOH")
types <- tolower(c("Gain","Loss","LOH"))