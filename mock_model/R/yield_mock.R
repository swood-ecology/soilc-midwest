#####################################################################
# Project:      SNAPP soil carbon working group                     #
# Description:  Mock code for US-scale model of yield variability   #
# Data sources: NASS; SoilGrids                                     #
# Author:       Steve Wood                                          #
# Last updated: March 12, 2018                                      #
#####################################################################

# LOAD PACKAGES
library(tidyverse)  # For reading in and manipulating data
library(rstan)      # For interfacing with Stan

# READ DATA
model_data <- read_csv("/home/shares/soilcarbon/soilc-midwest/data/IL_toy_data.csv")

# MANIPULATE DATA
## Drop NA values
model_data <- model_data[which(is.na(model_data$Yield.bu.acre)==FALSE),]
## Simplify variable names
names(model_data)[c(5,9)] <- c('county','yield')

# PREPARE DATA FOR STAN
## Weird alternating high and low numbers. Take only high
md_onecounty <- filter(md_onecounty, yield < 200)

# ## Generate county-level dummies and merge back original data
md_dummy <- model_data[,c('county','yield')] %>%
              model.matrix(yield ~ ., .) %>%
              cbind(model_data,.)
## Subset data needed for analysis
md_dummy <- select(md_dummy, yield,Year,countyALEXANDER:countyWOODFORD)

## List data to pass to Stan
dat_list <- list(
                    N=nrow(md_dummy),
                    yield=md_dummy$yield
)

# CALL STAN MODEL
ar1_model <- stan(
                    file = "/home/shares/soilcarbon/soilc-midwest/mock_model/stan/yield-ar1_mock.stan", 
                    data = dat_list, 
                    control = list(adapt_delta=0.99,max_treedepth=15), chains = 4
)

# MODEL RESULTS
##  Print results
print(
      ar1_model,pars=c("beta_ar","alpha","sigma"),
      probs=c(0.05,0.95)
)

##  Plot results
plot(ar1_model,pars=c("beta_ar","alpha","sigma"))

# ##  Posterior predictive check
# ### Extract predicted data
# yield_pred <- extract(yield_model,pars=c('y_tilde','yield_cov'))
# ### Unlist predicted data
# yield_pred <- unlist(yield_pred, use.names=FALSE)
# ### Create data frame with observed and predicted data
# yield_pp_data <- data.frame(
#                             c(yield_pred),
#                             c(rep("yield_pred",length(yield_pred$y_tilde)),
#                               rep("y_cov",length(yield_pred$yield_cov)))
# )
# ### Rename data
# names(yield_pp_data) <- c("y","type")
# ### Overlap density plot of observed vs. predicted
# ggplot(yield_pp_data, aes(x=y)) + 
#   geom_density(
#     aes(group=type, fill=type), 
#     alpha=0.75
#   ) + 
#   theme_bw() +
#   xlab("Yield variability") + ylab("Density") +
#   scale_fill_manual(values=wesanderson::wes_palette("Royal1",n=2)) +
#   theme(
#     legend.title = element_blank(),
#     legend.position = c(0.85,0.55),
#     panel.grid = element_blank(),
#     panel.background = element_rect(fill="white"),
#     plot.background = element_rect(fill="white")
#   )
