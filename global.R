library(shiny)
library(ggplot2)
library(jsonlite)

options(warn = 2)

isShinyLocal <- Sys.getenv('SHINY_PORT') == ""

# email with gmail needs 2FA now?
config <- config::get()

if (is.null(config$maintainer_name)) config$maintainer_name <- "Steve"
if (is.null(config$maintainer_email)) config$maintainer_email <- "stanpumpR@gmail.com"
if (is.null(config$help_link)) config$help_link <- "https://steveshafer.shinyapps.io/stanpumpR_HelpPage"
if (is.null(config$debug)) config$debug <- FALSE

DEBUG <- config$debug

# Load other files
#CANCEL <- readPNG("www/cancel.png", native=TRUE)
enableBookmarking(store = "url")

# Setup Theme
theme_update(
  panel.background = element_rect(fill = "white", color = "white"),
  legend.box.background = element_rect(fill = "white", color = "white"),
  panel.grid.major.y = element_line(color = "lightgrey"),
  panel.grid.major.x = element_line(color = "lightgrey"),
  axis.ticks = element_line(color = "lightgrey"),
  axis.ticks.length = unit(.25, "cm"),
  axis.title = element_text(size = rel(1.5)),
  axis.text = element_text(size = rel(1.2)),
  axis.line = element_line(linewidth = 1, color = "black"),
  aspect.ratio = 0.6,
  plot.title = element_text(size = rel(1.5)),
  legend.text = element_text(size = rel(0.9)),
  legend.position = "right",
  legend.key = element_blank()
)

e <- new.env()
load("data/sysdata.rda", envir=e)
js_drug_defaults <- paste0("var drug_defaults=",toJSON(rlang::env_get(e, "drugDefaults_global")))
rm(e)

blanks <- rep("", 6)
doseTableInit <- data.frame(
  Drug = c("propofol","propofol","fentanyl","remifentanil","remifentanil","rocuronium", blanks),
  Time = c(as.character(rep(0,6)), blanks),
  Dose = c(as.character(rep(0,6)), blanks),
  Units = c("mg","mcg/kg/min","mcg","mcg","mcg/kg/min","mg", blanks)
)
doseTableNewRow <-  doseTableInit[7, ]

eventTableInit <- data.frame(
  Time = numeric(0),
  Event = character(0),
  Fill = character(0)
)

outputComments <- function(
  ...,
  echo = getOption("ECHO_OUTPUT_COMMENTS", TRUE),
  sep = " ")
{
  isolate({
    argslist <- list(...)
    if (length(argslist) == 1) {
      text <- argslist[[1]]
    } else {
      text <- paste(argslist, collapse = sep)
    }

    # If this is called within a shiny app, try to get the active session
    # and write to the session's logger
    commentsLog <- function(x) invisible(NULL)
    session <- getDefaultReactiveDomain()
    if (!is.null(session) &&
        is.environment(session$userData) &&
        is.reactive(session$userData$commentsLog))
    {
      commentsLog <- session$userData$commentsLog
    }

    if (is.na(echo)) return()
    if (is.data.frame((text)))
    {
      con <- textConnection("outputString","w",local=TRUE)
      capture.output(print(text, digits = 3), file = con, type="output", split = FALSE)
      close(con)
      if (echo)
      {
        for (line in outputString) cat(line, "\n")
      }
      for (line in outputString) commentsLog(paste0(commentsLog(), "<br>", line))
    } else {
      if (echo)
      {
        cat(text, "\n")
      }
      commentsLog(paste0(commentsLog(), "<br>", text))
    }
  })
}

bookmarksToExclude <- c(
  "doseTableHTML",
  "doseTableHTML_select",
  "setTarget",
  "targetDrug",
  "targetDrug-selectized",
  "targetEndTime",
  "targetOK",
  "plot_click",
  "plot_dblclick",
  "plot_hover",
  "sidebarCollapsed",
  "sidebarItemExpanded",
  "simType",
  "effectsiteLinetype-selectized",
  "maximum-selectized",
  "plasmaLinetype-selectized",
  "targetTableHTML",
  "targetTableHTML_select",
  "editPriorDosesTable_select",
  "editPriorDosesTable",
  "clickDose",
  "clickEvent",
  "clickEvent-selectized",
  "clickOKDrug",
  "clickOKEvent",
  "clickTimeDrug",
  "clickTimeEvent",
  "clickUnits",
  "dblclickDrug",
  "dblclickDrug-selectized",
  "dblclickTime",
  "dblclickDose",
  "dblclickUnits",
  "dblclickOK",
  "dblclickDelete",
  "editDoses",
  "editDosesOK",
  "editEvents",
  "editEventsOK",
  "sendSlide",
  "recipient",
  "drugEditsOK",
  "editDrugsHTML",
  "editDrugsHTML_select",
  "editDrugs",
  "newEndCe",
  "hoverInfo"
)
