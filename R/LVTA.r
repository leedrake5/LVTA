source("~/GitHub/LVTA/R/back.r")


library(ggplot2)
library(RCurl)
library(reshape2)
library(data.table)
library(gsheet)
library(tidyverse)
library(lubridate)
library(scales)
library(rvest)



lvta_main <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1Qq2EYhEZeQfszqlYD-lyEsa6VJcGZSq4V9KabMUf2fE/edit#gid=0", "LVTA")
finra_nyse <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1Qq2EYhEZeQfszqlYD-lyEsa6VJcGZSq4V9KabMUf2fE/edit#gid=0", "FINRA and NYSE")
nyse <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1Qq2EYhEZeQfszqlYD-lyEsa6VJcGZSq4V9KabMUf2fE/edit#gid=0", "NYSE")
finra_1 <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1Qq2EYhEZeQfszqlYD-lyEsa6VJcGZSq4V9KabMUf2fE/edit#gid=0", "FINRA1")
finra_2 <- googlesheets4::read_sheet("https://docs.google.com/spreadsheets/d/1Qq2EYhEZeQfszqlYD-lyEsa6VJcGZSq4V9KabMUf2fE/edit#gid=0", "FINRA2")


###LVTA
lvta_data = lvta_main[,c("Date", "LVTA")]
lvta_data$Date <- as.Date(lvta_data$Date)
colnames(lvta_data) <- c("Date", "LVTA")
lvta_data <- lvta_data %>%
    arrange(Date) %>%
    mutate(Daily = LVTA - lag(LVTA, default = first(LVTA)))

current_lvta <- ggplot(lvta_data, aes(Date, LVTA)) +
geom_col(data=lvta_data, mapping=aes(Date, Daily), alpha=0.8, position = position_dodge(0.7)) +
geom_point() +
stat_smooth(method="gam") +
scale_x_date(date_labels = "%m/%d/%Y") +
scale_y_continuous("Total Debt:Capital", labels=scales::comma) +
ggtitle(paste0("Total Debt to Capital on ", Sys.Date())) +
theme_light()
ggsave("~/Github/LVTA/Plots/lvta_total.jpg", current_lvta, device="jpg", width=6, height=5)

###Free LVTA
lvta_free_data = lvta_main[,c("Date", "Free_LVTA")]
lvta_free_data$Date <- as.Date(lvta_free_data$Date)
colnames(lvta_free_data) <- c("Date", "Free_LVTA")
lvta_free_data <- lvta_free_data %>%
    arrange(Date) %>%
    mutate(Daily = Free_LVTA - lag(Free_LVTA, default = first(Free_LVTA)))

current_lvta_free <- ggplot(lvta_free_data, aes(Date, Free_LVTA)) +
geom_col(data=lvta_free_data, mapping=aes(Date, Daily), alpha=0.8, position = position_dodge(0.7)) +
geom_point() +
stat_smooth(method="gam") +
scale_x_date(date_labels = "%m/%d/%Y") +
scale_y_continuous("Free Debt:Capital", labels=scales::comma) +
ggtitle(paste0("Free Debt to Capital on ", Sys.Date())) +
theme_light()
ggsave("~/Github/LVTA/Plots/lvta_free.jpg", current_lvta_free, device="jpg", width=6, height=5)

###Margin LVTA
lvta_margin_data = lvta_main[,c("Date", "Margin_LVTA")]
lvta_margin_data$Date <- as.Date(lvta_margin_data$Date)
colnames(lvta_margin_data) <- c("Date", "Margin_LVTA")
lvta_margin_data <- lvta_margin_data %>%
    arrange(Date) %>%
    mutate(Daily = Margin_LVTA - lag(Margin_LVTA, default = first(Margin_LVTA)))

current_lvta_margin <- ggplot(lvta_margin_data, aes(Date, Margin_LVTA)) +
geom_col(data=lvta_margin_data, mapping=aes(Date, Daily), alpha=0.8, position = position_dodge(0.7)) +
geom_point() +
stat_smooth(method="gam") +
scale_x_date(date_labels = "%m/%d/%Y") +
scale_y_continuous("Margin Debt:Capital", labels=scales::comma) +
ggtitle(paste0("Margin Debt to Capital on ", Sys.Date())) +
theme_light()
ggsave("~/Github/LVTA/Plots/lvta_margin.jpg", current_lvta_margin, device="jpg", width=6, height=5)
