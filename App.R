#BIBLIOTECAS UTILIZADAS
library("shiny")
library("shinythemes")
library("shinyWidgets")
library("dplyr")
library("lubridate")
library("readxl")
##library("zoo")
#library("knitr")
#library("printr")

ui <- shinyUI( 
  navbarPage( theme = shinytheme("united"), 
              title = "", 
              windowTitle="Conferindo Catracas", responsive = TRUE, collapsible = TRUE,
              
              tabPanel("Conferindo Catracas", icon = icon("cloud-upload-alt", lib = "font-awesome"),
                       
                       tags$head(
                         
                         tags$link(rel="shortcut icon", href="http://estatistica.info/examples/images/favicon/favicon.ico"),
                         tags$link(rel="shortcut icon", href="http://estatistica.info/examples/images/favicon/favicon-16x16.png"),
                         tags$link(rel="shortcut icon", href="http://estatistica.info/examples/images/favicon/favicon-32x32.png"),
                         tags$link(rel="shortcut icon", href="http://estatistica.info/examples/images/favicon/favicon-96x96.png"),
                         
                         tags$style(HTML("@import url('//fonts.googleapis.com/css2?family=MuseoModerno:wght@500&display=swap');")),
                         tags$style(HTML("@import url('//fonts.googleapis.com/css2?family=Bebas+Neue&display=swap');")),
                         tags$style( HTML("#logo { font-family: MuseoModerno; color: white; font-size: 17px; }")),
                         tags$style( HTML('#logotxt { font-family: MuseoModerno; }')) ),
                       tags$style( HTML("#segment_alert { font-family: 'Bebas Neue'; color: green ; font-size: 17px; background-color:#DC143C }")),
                       
                       uiOutput('upload_server')  ) ) )

server <- shinyServer(function(input, output, session) {
  
  output$upload_server <- renderUI({
    tagList(
      
      sidebarLayout(
        sidebarPanel(
          pickerInput('selected_month', "Selecione o m?s", multiple = FALSE,
                      choices = list("Janeiro'20"='1', "Fevereiro'20"='2', "Mar?o'20"='3', "Abril'20"='4', "Maio'20"='5', "Junho'20"='6',
                                 "Julho'20"='7', "Agosto'20"='8', "Setembro'20"='9', "Outubro'20"='10', "Novembro'20"='11', "Dezembro'20"='12')
                                  , selected = '6'),

          fileInput("file", "Selecione o arquivo (Excel)", multiple = TRUE,
                    accept = c(".xlsx", ".xls")),
          
          actionButton("btn_analyze" ,"CONFIRMAR UPLOAD", icon("cloud-upload-alt", lib = "font-awesome")),
          uiOutput("selectfile")
        ),
        mainPanel(
          uiOutput("tb"),
          h2(tags$strong("SISTEMA DE AUX?LIO PARA ACOMPANHAMENTO DE C.H."), align="center"),
          h3("Fa?a upload do arquivo 'das catracas' e o sistema fornecer? os dados em formato padr?o para an?lise do supervisor."),
          helpText("Obs.: Trata-se de um mero aux?lio e portanto sujeito a erros de c?lculo")
        ) )
        )})


  output$Legenda <- renderText({"LEGENDA:"})
  output$ESQUECIMENTO <- renderText({ "ESQUECIMENTO: marcou somente a entrada ou sa?da em um determinado dia."})
  output$s_registro <- renderText({ "s.registro: n?o marcou entrada ou sa?da em um determinado dia."})
  output$ini_plantao <- renderText({ "ini.plant?o: quando identificado IN?CIO de plant?o noturno."})
  output$fim_plantao <- renderText({ "fim.plant?o: quando identificado T?RMINO de plant?o noturno."})
  output$reg_normal <- renderText({ "reg.normal: registro aparentemente normal, com entrada e sa?da no mesmo dia."})
  
  output$Upload_MENU <- renderText({ 
    paste0("Upload")
  })

  
  BaseEmR <- eventReactive(input$btn_analyze, {
    Base <- temporario
    Base <- data.frame(temporario_temp())
    NOME_DO_RESIDENTE_BASE <<- as.character(Base[1,3])
    Base <- cbind(Base,as.character(as.Date(Base[,11])) )
    names(Base)[dim(Base)[2]] <- "Data"
    
    #CRIANDO COLUNA COM HORAS
    for (i in 1:dim(Base)[1]) {
      hora <- hour(Base[i,11])
      minuto <- minute(Base[i,11])
      segundo <- second(Base[i,11])
      Base$hs_legivel[i] <- as.character(hms(paste0(hora,":",minuto,":",segundo)))
      Base$hs_numerico[i] <- hora*60 + minuto + segundo/60
    }
    
    
    rang_datas_ano <- list(
      '1'=c('2020-01-01','2020-01-31'),
      '2'=c('2020-02-01','2020-02-29'),
      '3'=c('2020-03-01','2020-03-31'),
      '4'=c('2020-04-01','2020-04-30'),
      '5'=c('2020-05-01','2020-05-31'),
      '6'=c('2020-06-01','2020-06-30'),
      '7'=c('2020-07-01','2020-07-31'),
      '8'=c('2020-08-01','2020-08-31'),
      '9'=c('2020-09-01','2020-09-30'),
      '10'=c('2020-10-01','2020-10-31'),
      '11'=c('2020-11-01','2020-11-30'),
      '12'=c('2020-12-01','2020-12-31'))
    
    MES_ESCOLHIDO = input$selected_month
    #MES_ESCOLHIDO = "6"
    
    #DEFINE IN?CIO DO M?S
    Inicio_Mes <- rang_datas_ano[[MES_ESCOLHIDO]][1]
    Inicio_Mes <- as.Date(Inicio_Mes, format = c("%Y-%m-%d"))
    
    #DEFINE FINAL DO M?S
    Final_Mes <- rang_datas_ano[[MES_ESCOLHIDO]][2]
    Final_Mes <- as.Date(Final_Mes, format = c("%Y-%m-%d"))
    
    #DEFINE A MATRIZ PARA ARMAZENAGEM
    compilado <- matrix("",(Final_Mes - Inicio_Mes+1), 10)
    colnames(compilado) <- c("Nome", "Data", "Hs_Entrada", "Hs_Sa?da", "Interpreta??o" ,"Saldo Parcial", "Acumulado(Saldo)", "aux_hs_entrada","aux_hs_saida", "aux_acm")
    rownames(compilado) <- 1:(Final_Mes-Inicio_Mes+1)
    
    #PREENCHENDO NOME
    for (i in 1:dim(compilado)[1]) { compilado[i,1] <- as.character(Base[1,3]) }
    
    #PREENCHENDO DIAS
    for (i in 1:dim(compilado)[1]) { compilado[i,2] <- as.character(Inicio_Mes + (i-1)) }
    
    #PREENCHENDO Hs_Entrada
    for (i in 1:dim(compilado)[1]) { 
      SUBBASE <- Base %>% filter(Data == compilado[i,2]) %>% filter(Tipo == "Entrada") 
      SUBBASE <- SUBBASE[order(SUBBASE$hs_numerico, decreasing = FALSE),]
      SUBBASE
      compilado[i,3] <- SUBBASE$hs_legivel[1]
      compilado[i,8] <- SUBBASE$hs_numerico[1]
    }
    
    #PREENCHENDO Hs_Sa?da
    for (i in 1:dim(compilado)[1]) { 
      SUBBASE <- Base %>% filter(Data == compilado[i,2]) %>% filter(Tipo == "Sa?da") 
      SUBBASE <- SUBBASE[order(SUBBASE$hs_numerico, decreasing = TRUE),]
      SUBBASE
      compilado[i,4] <- SUBBASE$hs_legivel[1]
      compilado[i,9] <- SUBBASE$hs_numerico[1]
    }
    
    #PREENCHENDO Interpreta??o
    for (i in 1:(dim(compilado)[1])) { 
      if ( is.na(compilado[i,3]) && is.na(compilado[i,4]) ) {
        compilado[i,5] <- "s.registro"
      } else {
        if ( !is.na(compilado[i,3]) && is.na(compilado[i,4]) && is.na(compilado[i+1,3]) && !is.na(compilado[i+1,4])  ) {
          compilado[i,5] <- "ini.plant?o"  
        } else {
          if ( (i>1) && is.na(compilado[i,3]) && !is.na(compilado[i,4]) && !is.na(compilado[i-1,3]) && is.na(compilado[i-1,4])  ) {
            compilado[i,5] <- "fim.plant?o"  
          } else {
            if ( (i>1) && !is.na(compilado[i,3]) && !is.na(compilado[i,4]) && ( !(c("ini.plant?o", "fim.plant?o") %in% compilado[i,5]) ) ) {
              compilado[i,5] <- "reg.normal"  
            } else {
              if ( (i==1) && !is.na(compilado[i,3]) && !is.na(compilado[i,4]) ) {
                compilado[i,5] <- "reg.normal"  
              } else {
                if ( (i>1) && (is.na(compilado[i,3]) || is.na(compilado[i,4])) && ( !(c("ini.plant?o", "fim.plant?o") %in% compilado[i,5]) ) ) {
                  compilado[i,5] <- "ESQUECIMENTO"  
                } else {
                  if ( (i==1) && (is.na(compilado[i,3]) || is.na(compilado[i,4])) ) {
                    compilado[i,5] <- "ESQUECIMENTO"    
                  } } } } } } } }
    
    #PREENCHENDO Saldo Parcial
    for (i in 1:(dim(compilado)[1])) { 
      if (compilado[i,5] == "reg.normal") {
        
        tempo_min <- as.numeric(compilado[i,9])- as.numeric(compilado[i,8])
        hora <- trunc(tempo_min/60)
        minuto <- trunc((tempo_min - hora*60))
        compilado[i,6] <- paste0(hora,"H ",minuto,"M")
        compilado[i,10] <- as.numeric(tempo_min)/60
        
      } else {
        if ((compilado[i,5] == "s.registro") || (compilado[i,5] == "ESQUECIMENTO") || (compilado[i,5] == "ini.plant?o")) {
          compilado[i,6] <- 0
          compilado[i,10] <- 0
          
        } else {
          if (compilado[i,5] == "fim.plant?o") {
            tempo_min <- (24*60 - as.numeric(compilado[i-1,8])) + as.numeric(compilado[i,9])
            hora <- trunc(tempo_min/60)
            minuto <- trunc(tempo_min - hora*60)
            compilado[i,6] <- paste0(hora,"H ",minuto,"M")
            compilado[i,10] <- as.numeric(tempo_min)/60
          } } } }
    
    #PREENCHENDO Acumulado(Saldo)
    for (i in 1:(dim(compilado)[1])) {
      
      if (i == 1) { 
        if (is.na(as.numeric(compilado[i,6]))) { compilado[i,7] <- compilado[i,10] } else {compilado[i,7] <- 0}
      }
      if ( i>1 ) {
        compilado[i,7] <-   as.numeric(compilado[(i-1),7]) + as.numeric(compilado[i,10])
      }
    }
    
    #CONVERTENDO VALORES PARA VISUALIZA??O AGRAD?VEL
    for (i in 1:(dim(compilado)[1])) {
      hora <- trunc(as.numeric(compilado[i,7]))
      minuto <- trunc( (as.numeric(compilado[i,7]) - hora)*60 )
      compilado[i,7] <- paste0(hora,"H ",minuto,"M")
    }
    
    #CONVERTENDO VALORES PARA VISUALIZA??O AGRAD?VEL
    for (i in 1:(dim(compilado)[1])) {
      if ( !is.na(compilado[i,9])) { compilado[i,6] <- compilado[i,6]} else {compilado[i,6] <- "-"}
    }
    
    
    #ADICIONANDO DIAS DA SEMANA
    compilado <- compilado[,2:7]
    Semana<-0
    for (i in 1:dim(compilado)[1]) {
      Semana[i] <- weekdays(as.Date(compilado[i,1]), abbreviate = TRUE)
    }
    compilado <- data.frame(cbind(compilado,Semana))
    
    #REORDENANDO COLUNAS
    compilado <- compilado %>% select("Data", "Semana", everything())
    
    compilado

  })

  temporario_temp <- eventReactive(input$btn_analyze, {
    if(is.null(input$file)){return ()}
    temporario <- data.frame(read_excel(input$file$datapath[input$file$name==input$Select], skip = 5))
    #temporario <- data.frame(read_excel("CATRACAS_PARA_AVALIAR/EXEMPLO_REAL2.xlsx", skip = 5))
    temporario <<- temporario
    temporario
  })
  
  output$selectfile <- renderUI({
    if(is.null(input$file)) {return()}
    list(hr(), 
         selectInput("Select", "File", choices=input$file$name)
    )
  })
  
  output$table <- renderTable({ 
    if(is.null(input$file)){return()}
    BaseEmR()
  })
  
  output$nome_do_residente <- renderText({ 
    NOME_DO_RESIDENTE_BASE <- data.frame(temporario_temp())[1,3]
  })
  
  
  
  output$tb <- renderUI({
    if(is.null(input$file)) {return()}
    else
      tabsetPanel(
        tabPanel("Dados Padronizados para An?lise",
                 h4("RESIDENTE: ",textOutput("nome_do_residente", inline = TRUE)),
                 tableOutput("table"), 
                 tags$strong(textOutput("Legenda")),
                 helpText(textOutput("ESQUECIMENTO")),
                 helpText(textOutput("s_registro")),
                 helpText(textOutput("ini_plantao")),
                 helpText(textOutput("fim_plantao")),
                 helpText(textOutput("reg_normal"))
                 ))
  })

})

shinyApp(ui, server)

