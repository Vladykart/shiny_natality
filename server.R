library(shiny)
library(ggplot2)
library(dplyr)
library(scales)
library(grid)
library(bigrquery)
library(httr)
library(googleAuthR)
library(zoo)
library(readr)
library(ggpubr)



project <- "put your project ID here" # put your project ID here
bq_auth(path = 'YOUR AUTH FILE HERE')
sql <- "SELECT
        date_str,
        SUM(plurality) as birth_per_month
        FROM(
                SELECT
                IFNULL(plurality, 1) as plurality,
                CONCAT(STRING(year),'-', STRING(month)) as date_str
                FROM [publicdata:samples.natality]
             )
        GROUP BY date_str
        
        "

data_df <- data.frame(query_exec(sql, project = project, max_pages = Inf, useLegacySql = FALSE))
data_df$Date <- as.yearmon(data_df$date_str)

# HISTOGRAM

sql_2 <- "SELECT
        year,
        IFNULL(plurality, 1) as plurality,
        COUNT(1) as birth
        FROM
          publicdata.samples.natality
        GROUP BY
        plurality, year
        "
data_df_plurality <- data.frame(query_exec(sql_2, project = project, max_pages = Inf, useLegacySql = FALSE))

# SCATTER

sql_3_apgar_1min <- "SELECT
      apgar_1min,
      mother_age,
      gestation_weeks,
      weight_pounds,
      drinks_per_week
        
        FROM
          publicdata.samples.natality
        WHERE
        apgar_1min IS NOT NULL AND apgar_1min <= 10
        AND weight_pounds IS NOT NULL
        AND gestation_weeks >27 AND gestation_weeks IS NOT NULL
        AND weight_pounds IS NOT NULL
        AND mother_age IS NOT NULL
        AND drinks_per_week IS NOT NULL AND drinks_per_week < 99
        LIMIT 10000
  
        "

sql_4_apgar_5min <- "SELECT
      apgar_5min,
      mother_age,
      gestation_weeks,
      weight_pounds,
      drinks_per_week
        
        FROM
          publicdata.samples.natality
        WHERE
        apgar_5min IS NOT NULL AND apgar_5min <= 10
        AND weight_pounds IS NOT NULL
        AND gestation_weeks >27 AND gestation_weeks IS NOT NULL
        AND weight_pounds IS NOT NULL
        AND mother_age IS NOT NULL
        AND drinks_per_week IS NOT NULL AND drinks_per_week < 99
        LIMIT 10000
        
  
        "
data_df_apgar_1min <- data.frame(query_exec(sql_3_apgar_1min, project = project, max_pages = Inf, useLegacySql = FALSE))

data_df_apgar_5min <- data.frame(query_exec(sql_4_apgar_5min, project = project, max_pages = Inf, useLegacySql = FALSE))


# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
    
    output$dateRangeText <- renderText({
        paste(input$yearRange)
       
    })
    
    output$histPlot <- renderPlot({
        
        ranged_data <- data_df_plurality %>%
            filter(year >= input$yearRange[1] & year <= input$yearRange[2])
        
        sum_dist_df <- ranged_data %>% 
            group_by(plurality) %>% 
            summarise_at(vars(birth), funs(sum))  
        
        sum_dist_df$percent <- (sum_dist_df$birth*100)/sum(sum_dist_df$birth)
        
        specify_decimal <- function(x, k) trimws(format(round(x, k), nsmall=k))
        
        #HISTOGRAM VISUALISATION
        
        ggplot(sum_dist_df, aes(x = plurality, y = percent)) +  
            geom_bar(stat = "identity", fill = 'blue', color = 'blue' )+      
            geom_text(
                aes(label = specify_decimal(percent, 5)),
                position = position_dodge(0.9),
                vjust = -.5)+
            theme_minimal()
        
    })
    
    output$distPlot <- renderPlot({
        
        ts_data <- data_df %>%
            filter(Date >= as.yearmon(input$dateRange[1]) & Date <= as.yearmon(input$dateRange[2]))
        
        # generate bins based on input$
        ggplot(ts_data,
               aes(x= as.Date(Date))) + 
            scale_x_date(date_breaks = "1 years",
                         date_minor_breaks = "4 month")+
            geom_line(aes(y=birth_per_month/1000))+ 
            labs(title="Time Series Chart", 
                 subtitle="Returns 1-th births per month from 'publicdata:samples.natality' Dataset", 
                 caption="Source: GOOGLE publicdata:samples.natality", 
                 y="Returns birth_per_month",
                 x= "Date")+
            theme_minimal()+
            theme(axis.text.x = element_text(angle=45, hjust = 1))
        
    })
    
    
    output$userChoise <- renderText({
        paste(input$xcol, input$ycol)
        
    })
    
    output$scatterPlot <- renderPlot({
        xcol<- input$xcol
        ycol<- input$ycol
        
       if(input$xcol == 'apgar_1min'){
           ggscatter(data_df_apgar_1min, x = xcol, y = ycol, 
                     add = "reg.line", conf.int = TRUE, 
                     cor.coef = TRUE, cor.method = "pearson")}
       else if(input$xcol == 'apgar_5min'){
           ggscatter(data_df_apgar_5min, x = xcol, y = ycol, 
                     add = "reg.line", conf.int = TRUE, 
                     cor.coef = TRUE, cor.method = "pearson")}
        
        
        
    })
})
