#FlashcardsDashboard.R

#Deployment URL: https://larossi.shinyapps.io/FlashCards/

###############################################################
##Loading packages
###############################################################

library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(flashCard) 
library(tibble)   # add_row to dataframe function in this package
library(DT)
library(dplyr)
library(shinyjs)
library(shinyalert)
library(stringr) # to wrap text
library(htmlwidgets)
library(readxl) #to save dataframe to Excel
library(openxlsx)
library(xlsx)

###############################################################
##  Define URL variables that are using in the dashboard
###############################################################
urlFlashCard1 <- a(HTML(paste('<h5><b>',"Reference:  Jiena McLellan's contribution in github.com",'</b><br><h5>')),
                href="https://github.com/jienagu/flashCard_Shiny_Demo/blob/main/app.R")

urlFlashCard2 <- a(HTML(paste('<h5><b>',"Reference: Demo Apps and Podcast",'</b><br><h5>')),
                href="https://www.jienamclellan.com/")

urlmyYouTube <- a(HTML(paste('<h5><b>',"My YouTube channel",'</b><br><h5>')),
                   href="https://www.youtube.com/channel/UCDmEAmoLuyE0h61aGpthGvA/videos")



###############################################################
##  Button formatting function
###############################################################
styleButtonBlue<- function(){
  "white-space: normal;
                        text-align:center;
                        color: #ffffff; 
                        background-color:#00c9cc;
                        border-color: #ffffff;
                        border-width:3px;
                        height:35px;
                        width:140px;
                        font-size: 13px;"
}

###############################################################
##  UI Coding starts here
###############################################################

ui <- dashboardPage(
  dashboardHeader(),
  dashboardSidebar(
    fluidRow(
      column(
        hr(),
        width = 12,
        align = "center",
        height = 40,
        # Input: Select a file ----
        fileInput("mfile", "Choose File",
                  multiple = FALSE,
                  accept = c("excel",
                             "excel",
                             ".xls",".xlsx"))
      )
    ),
    hr(),
    column(
      width = 12,
      align='center',
    sidebarMenu(id = "tabs",
                menuItem('Overview & Citation',
                         tabName = 'taboverview',
                         icon = icon('line-chart')),
                menuItem('Flash Cards',
                         tabName = 'tabFlashCards',
                         icon = icon('line-chart')),  
                menuItem('Show Table',
                         tabName = 'tabdataset',
                         icon = icon('line-chart'))
                
    ),#sidebar menu
    hr()
    ),

    column(
      width = 12,
      align='center',
      actionBttn("mdummydffile", "Get Template",style = 'pill',color = 'primary',size = 'sm' ),
      hr()
      )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        tabName ="taboverview",
        box(
          background = 'teal',
          width = 12,
          height = 50,
          scrollX = FALSE,
          HTML(
            paste(
              '<p text-align ="center"><h4><b>',
              'Flash Card - Overview & Citations',
              '</b></p>'
            )
          )
        ),
        box(
          id = "boxtaboverview",
          width = 12,
          height = 400,
          title = NULL,
          status = "primary",
          solidHeader = TRUE,
          collapsible = FALSE,
          uiOutput(outputId = 'mFlashcardOverview')
        ) # box closure
      ),
      tabItem(
        tabName = "tabFlashCards",
        column(
          width = 6,
          offset = 0,
          align = "center",
          box(
            width = 12,
            height = 475,
            align = "center",
            title = "Flashcard Dataset",
            status = "primary",
            solidHeader = TRUE,
            collapsible = FALSE,
            uiOutput(outputId = "mTopicUI"),
            DT::dataTableOutput("dt",height = 300,width = 450),
            tags$style(HTML('table.dataTable tr.selected td{background-color: pink !important;}')),
            useShinyjs(),
            extendShinyjs(text = paste0("shinyjs.resetDTClick = function() { Shiny.onInputChange('dt_cell_clicked', null); }"),functions = c('foo','bar'))
          )
        ),
        
        column(
          width = 6,
          offset = 0,
          align = "center",
          fluidRow(
            box(
              width = 12,
              height = 475,
              align = "justify",
              title = "Flash Card",
              status = "primary",
              solidHeader = TRUE,
              collapsible = FALSE,
              align = "center",
              uiOutput(outputId = "mflashcardUI"),
              br(),
              uiOutput(outputId = "mpreviousnextbtn")
            )
          ) #fluid Row Closure
        )#column closure
      ),#tabitem closure
      
      tabItem(
        tabName = "tabdataset",
        box(
          width = 12,
          height = 525, 
          align ="center",
          title ="Flash Card Dataset", 
          status = "primary",
          solidHeader = TRUE,
          collapsible = FALSE,
          downloadButton("downloadCSV", "Download CSV",style = styleButtonBlue()),
          actionButton("downloadExcel", "Download Excel",style = styleButtonBlue()),
          DT::dataTableOutput('mdatatable', height = 425),
          tags$style(HTML('table.dataTable tr.selected td{background-color: pink !important;}'))
          
        ) #box closure
      ) #tabitem closure
    )#tabItems closure
  )#dashboardbody closure
)#dashboardPage closure


###############################################################
##  Server Coding starts here
###############################################################
server <- function(input, output,session) {
  #this is to hide right side bar
  shinyjs::addCssClass(selector = "body", class = "sidebar-collapse")
  onevent("mouseenter", "sidebarCollapsed", shinyjs::removeCssClass(selector = "body", class = "sidebar-collapse"))
  onevent("mouseleave", "sidebarCollapsed", shinyjs::addCssClass(selector = "body", class = "sidebar-collapse"))
  
  vmy <- reactiveValues(mydataOriginal=NULL,mydata = NULL,df1=NULL,irow=1)
  vmy$mydataTemplate <- readxl::read_excel("Data Template.xlsx") 
  
  observeEvent(input$mfile,{
    ### interactive dataset 
    ext <- tools::file_ext(input$mfile$name)
    
    if (ext == "xls" || ext == 'xlsx'){
      vmy$mydataOriginal <- readxl::read_excel(input$mfile$datapath)  # got from https://readxl.tidyverse.org/
    }
    else {
      sendSweetAlert(
        session  = session,
        title = "Error - File Type",
        text = tags$span(
          tags$h4(HTML(paste("Hi",'<br>',"You have selected '",ext,"' file type.",'<br>',"Should only be xlsx or xls file")),
                  style = "color: steelblue;")),
        type = 'primary'
      )
      return()
    }
    
    updateTabItems(session = session, inputId = "tabs", selected = "tabFlashCards")
    
    output$mTopicUI <- renderUI({
        selectInput(inputId ="mTopic", label = "Select Topic",
                    choices = c(unique(vmy$mydataOriginal$Topic),"Select ALL"),
                    selected = 'Select ALL',multiple = TRUE,width = '100%')
    })

observeEvent(input$mTopic,{
  if ("Select ALL" %in% input$mTopic){
    vmy$mydata <- vmy$mydataOriginal
  }
  else{
    vmy$mydata <- vmy$mydataOriginal%>%dplyr::filter(Topic %in% input$mTopic)
  }

  fnrenderFlashCardTbl(1)

})
})


  ##################################################################
  ##  Function to show flash card table with topic filter and reuse
  ##################################################################

  fnrenderFlashCardTbl<-function(xirow){
    output$dt <- DT::renderDataTable({
    mtempdf <- vmy$mydata[,1:2]
    DT::datatable(mtempdf,
                  selection = list(mode = "single", selected = c(xirow), target = 'row'),
                  rownames = TRUE,
                  class ='cell-border stripe compact white-space: nowrap', #where you got this multiple classes: https://rstudio.github.io/DT/
                  escape= FALSE,
                  editable = FALSE,
                  options = list(lengthMenu = list(c(15, 25, 50,-1), c('15', '25','50' ,'All')),
                                 pageLength = 15,
                                 autoWidth = TRUE, 
                                 columnDefs = list(list(width ='10px', targets = c(0)),
                                                   list(width ='50px', targets = c(1)),
                                                   list(width ='200px', targets = c(2))),
                                 initComplete = htmlwidgets::JS(
                                   "function(settings, json) {",
                                   paste0("$(this.api().table().container()).css({'font-size': '", "12px", "'});"),
                                   "}")
                  ) ,
                  fillContainer = getOption("DT.fillContainer", TRUE)
                  
    ) %>% 
      DT::formatStyle( columns=names(mtempdf), target= 'row',color = 'teal',
                       backgroundColor = 'white',
                       fontWeight ='normal',lineHeight='75%')
    })  
  }

  
  ##################################################################
  ##  To move Next and Previous in Flash cards
  ##################################################################
  
  observeEvent(input$mPrevious,{
    if(vmy$irow== 1){
      alert("This is the first row")
      return()
    }
    else{
      vmy$irow <<- vmy$irow-1
      fnShowFlashCard(vmy$irow)
      fnrenderFlashCardTbl(vmy$irow)      
    }
  })
  
  observeEvent(input$mNext,{
    if(vmy$irow== nrow(vmy$mydata)){
      alert("This is the last row")
      return()
    }
    else{
      vmy$irow <<- vmy$irow+1
      fnShowFlashCard(vmy$irow)
      fnrenderFlashCardTbl(vmy$irow)      
    }
  })
  
  
  observeEvent(input$dt_cell_clicked, {
    validate(need(length(input$dt_cell_clicked) > 0, ''))
    clicked_list <- input$dt_cell_clicked
    i_name <- unlist(vmy$mydata[clicked_list$row,2], use.names=FALSE)
    vmy$irow <<- which(vmy$mydata$Question == i_name) 
    
    fnShowFlashCard(vmy$irow)
  })
  
  
  
  ##################################################################
  ##  Function to generate and show flash card and review
  ##################################################################
  fnShowFlashCard <- function(xirow){
    vmy$df1 <- data.frame(front="text",back = "text")[-1,]
    vmy$df1 <- vmy$df1  %>% add_row(
      front = c(
        paste('<br>','<br>','<br>',vmy$mydata$Topic[xirow]), 
        paste('<h4>',vmy$mydata$Question[xirow],'<h4>'),""), 
      back = c(
        paste('<h4><b><i>',"Definition",'</i></b><h5>',paste(vmy$mydata$Definition[xirow])),
        paste('<h4><b><i>',"Example(s)",'</i></b><h5>',paste(vmy$mydata$Examples[xirow])),
        paste('<h4><b><i>',"Comments / Strategies",'</i></b><h5>',paste(vmy$mydata$Comments[xirow])))
    )
    
    
    
    output$mflashcardUI <- renderUI({
      flashCardOutput("card1", width = 450,height = 350)
      
    })
    
    output$mpreviousnextbtn <- renderUI({
      splitLayout(
        cellWidths = c("50%", "50%"),
        actionButton(inputId = "mPrevious", label = icon("arrow-left")),
        actionButton(inputId = "mNext", label = icon("arrow-right"))
      )#splitLayout closure
    })
    
    
    
    output$card1 <- renderFlashCard({
      flashCard(
        vmy$df1,
        frontColor = "#009999",
        backColor = "#00cccc",
        front_text_color = "white",
        back_text_color = "white",
        elementId = NULL
      )
    })
  }
  
  output$mdatatable <- DT::renderDataTable({
    DT::datatable( vmy$mydataOriginal,
                   selection = list(mode = "single", selected = c(1), target = 'row'),
                   rownames = TRUE,
                   escape= FALSE,
                   editable = FALSE,
                   options = list(lengthMenu = list(c(10, 20, 50,-1), c('10', '20','50' ,'All')),
                                  pageLength = 10,
                                  autoWidth = FALSE,
                                  columnDefs = list(list(width ='5px',  targets  = c(0)),
                                                    list(width ='30px', targets  = c(1)),
                                                    list(width ='30px',  targets = c(2)),
                                                    list(width ='150px', targets = c(3)),
                                                    list(width ='150px', targets = c(4)),
                                                    list(width ='150px', targets = c(5))),
                                  initComplete = htmlwidgets::JS(
                                    "function(settings, json) {",
                                    paste0("$(this.api().table().container()).css({'font-size': '", "12px", "',});"),
                                    "}")
                    ) ,
                   fillContainer = getOption("DT.fillContainer", TRUE)
                   
    ) %>% 
      DT::formatStyle(columns=names(vmy$mydataOriginal), target= 'row',color = 'black',
                       backgroundColor = 'white',
                       fontWeight ='normal',lineHeight='100%')%>%
      formatStyle(c(names(vmy$mydataOriginal)),target= 'cell', 'vertical-align'='top', backgroundColor='white') %>% 
      formatStyle(c(names(vmy$mydataOriginal)),target= 'cell', 'text-align' = 'left', backgroundColor='white')

  })  
  

  ### this is warning message to remove existing df and create a blank new
  observeEvent(input$mdummydffile,{
    showModal(
      modalDialog(
        title = "Warning",
        paste("Confirm you want to download a new data set template?" ),
        footer = tagList(
          modalButton("Cancel"),
          actionButton("dummyok", "Yes")
        ), easyClose = TRUE)
    )
    updateTabItems(session = session, inputId = "tabs", selected = "tabdataset")
    
  })
  
  ### If user say OK then download template
  observeEvent(input$dummyok, {
    
    ### create template df
    removeModal()
    dummydf <- data.frame(read_excel("Data Template.xlsx"))
    vmy$mydataTemplate <- dummydf
    fnCreateFormattedExcel(vmy$mydataTemplate,"FlashcardDatasetTemplate")
    })
  
  
  
  ### can download the table in CSV
  output$downloadCSV <- downloadHandler(
    filename = function() {
      paste("FlashcardDataset", Sys.Date(), ".csv", sep = ",")
    },
    content = function(file) {
      write.csv(data.frame(vmy$mydataOriginal), file, row.names = FALSE)
    }
  )
  

  ### can download the table in Excel
  observeEvent(input$downloadExcel,{
    fnCreateFormattedExcel(vmy$mydataOriginal)
  }) 
  


#############################################
## Overview and Citations
#############################################
  
  output$mFlashcardOverview <- renderUI({
    fluidRow(
      column(width = 6,
             tags$div(
               tags$p(
                 useShinyjs(),
                 HTML(paste('<h5><b>',"Overview:",'</b><br><h5>')),
                 HTML(paste('<h5>',
                            "A flashcard or flash card is a card bearing information on both sides, which",
                            "is intended to be used as an aid in memorization. Each flashcard bears a question",
                            "on one side and an answer on the other.",'<br><br>')),
                 HTML(paste('<h5><b>',"Credits:",'</b><br><h5>')),
                 HTML(paste('<h5>',"Thanks to Jiena McLellan, a software developer in Atlanta, GA.,",
                            "for her contribution in her website.",urlFlashCard2,'<br>')),
                 HTML(paste('<h5><b>',"Citation:",'</b><br><h5>')),
                 HTML(paste('<h5>',"The core script for flash card is borrowed from ",
                            "github.com/jienagu/flashCard_Shiny_Demo. ",urlFlashCard1,'<br>'))
               ))
             
      ),
      column(width = 6,
             tags$div(
               tags$p(
                 useShinyjs(),
                 HTML(paste('<h5><b>',"Value Addition:",'</b><br><h5>')),
                 HTML(paste('<h5>',"I have taken the flashcard R script from",'<b>',"github.com/jienagu/flashCard_Shiny_Demo",'</b>',"and added the following features:",'<br>',
                            HTML(paste('<h5><p style="text-align:justify;">',
                                       "1. Option to import an excel file with column headers i.e. Topic, Question, Definition, Examples, Comments; ",'<br>',
                                       "2. Alternatively; there is an option to create standard template for flashcard; that could be downloaded as csv or excel file; ",'<br>',
                                       "3. Option to upload an excel file.  The template could be updated and loaded back to the package",'<br>',
                                       "4. Option to view the dataset as table",'<br>',
                                       "5. Option to filter the questions by topic;",'<br>','<br>',
                            HTML(paste('<h5><b>',"About me:",'</b><br><h5>')),
                            HTML(paste0('<h5>',"I am a Chartered Accountant having 25+ years of experience in Finance & Accounting.",
                                        " The Data visualization and Data Science are always at the back of my mind.",
                                        " I am a 'Tableau Desktop Certified Associate and working in 'R' with specific reference to Shiny App.",'<br>',
                                        " In the process of sharing knowledge; ", 
                                        "I have a channel in YouTube on R Shiny App.  Copy the link and paste in browser to view", '<br>',
                                        'https://www.youtube.com/channel/UCDmEAmoLuyE0h61aGpthGvA/videos'
                                        ))
                 ))#inside HTML closure
               )) #outside HTML closure
               ))#div closure
      )#column closure
    )#fluidrow
  })
  
  
  #############################################
  ## Generate Excel file using xlsx package 
  #############################################
  
  fnCreateFormattedExcel <- function(xdata,filename_input=''){
    # create a new workbook for outputs
    #####################################
    wb<-createWorkbook()

    # Define some cell styles and column style
    #####################################

    # Styles for the data table row/column names
    TABLE_ROWNAMES_STYLE <- xlsx::CellStyle(wb) + Font(wb, isBold=TRUE)
    TABLE_COLNAMES_STYLE <- xlsx::CellStyle(wb) + Font(wb, isBold=TRUE) +
      Alignment(wrapText=TRUE, horizontal="ALIGN_CENTER")
    TABLE_DATA_STYLE <- xlsx::CellStyle(wb) + Font(wb, isBold=FALSE) +
      Alignment(wrapText=TRUE, horizontal="ALIGN_LEFT",vertical='VERTICAL_TOP')

    # # Create a new sheet in the workbook
    #####################################
    sheet <- createSheet(wb, sheetName = "FlashCardsDS")
    
    # Add a table into a worksheet
    #####################################
    addDataFrame(data.frame(xdata), sheet, row.names = FALSE, 
                 startRow=1, startColumn=1,               
                 colnamesStyle = TABLE_COLNAMES_STYLE,
                 rownamesStyle = TABLE_ROWNAMES_STYLE,
                 colStyle= list('1'=TABLE_DATA_STYLE,
                                '2'=TABLE_DATA_STYLE,
                                '3'=TABLE_DATA_STYLE,
                                '4'=TABLE_DATA_STYLE,
                                '5'=TABLE_DATA_STYLE)
                 )
    setColumnWidth(sheet, colIndex = 3:ncol(xdata), colWidth = 40)
    setColumnWidth(sheet, colIndex = 1:2, colWidth = 15)
    

    # Save the workbook to a file...
    #####################################
    mfilepath <- if (interactive() && .Platform$OS.type == "windows")
      choose.dir(getwd(), "Save file to:")

    if (is.na(mfilepath))
      return()
    
    filename = paste0(mfilepath,"\\",filename_input, Sys.Date(), ".xlsx")
    saveWorkbook(wb, file = filename)
    
  }
  
  
  
}#server closure

# Run the application 
shinyApp(ui = ui, server = server)
