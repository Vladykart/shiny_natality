
library(markdown)


# Define UI for application that draws a histogram
shinyUI(fluidPage(



navbarPage("Natility data",
           tabPanel("Plot",
                    sidebarLayout(
                        sidebarPanel(
                            dateRangeInput("dateRange", strong("Date range"), 
                                           start = '1968-01-01', end = '2008-12-31',
                                           min = '1968-01-01', max = '2008-12-31'),
                        ),
                        # Show a plot of the generated distribution
                        mainPanel(
                            plotOutput("distPlot")
                        )
                        
                    )
           ),
           tabPanel("Hist",
                    sidebarLayout(
                        sidebarPanel(
                            sliderInput("yearRange", "Year released", 1969, 2008, value = c(1970, 2008),
                                        sep = ""),
                        ),
                        # Show a plot of the generated distribution
                        mainPanel(
                            verbatimTextOutput("dateRangeText"),
                            plotOutput("histPlot")
                        )
                        
                    )
           ),
           tabPanel("Scatter",
                    sidebarLayout(
                        sidebarPanel(
                            selectInput('xcol', 'X Variable', c('apgar_1min', 'apgar_5min')),
                            selectInput('ycol', 'Y Variable', c('mother_age',
                                                                    'gestation_weeks',
                                                                    'weight_pounds',
                                                                    'drinks_per_week'),
                                        selected= 'drinks_per_week'),
                        ),
                        # Show a plot of the generated distribution
                        mainPanel(
                            verbatimTextOutput("userChoise"),
                            plotOutput("scatterPlot")
                            
                        )
                        
                    )
                    
           ),
           
           tabPanel("About",
                    fluidRow(
                      column(4,
                             includeMarkdown("include.md")
                      ))
                    
                    
                   
                               )
                      )
))
