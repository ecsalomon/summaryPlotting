################################################################################
######################### LOAD PACKAGES ########################################
################################################################################

library(psych)
library(ggplot2)
library(reshape)
library(Hmisc)

################################################################################
######################### BUILD DATA ###########################################
################################################################################

# We will pull in 2 data sets: one containing raw data with each participants'
# responses, and a second containing summarized data by demographic variables.
# In the raw data, each participant rated their association strength for 13
# different concept pairs from the social psych priming literature.
# You can create a table similar to the summarized data using the `summarizeBy`
# function in the `psych` package, but these data were created with custom
# functions using 10,000 bootstrap resamples. This process is not repeated here
# to save you (and me) lots of time.

# pull in raw data with all responses
rawData <- read.csv("rawData.csv")

# identify associations variables
assocVars <- c("warmth_5", "god_5", "god_6", "death_5", "death_6", "elderly_5",
               "power_5", "power_6", "conservati_5", "time_5", "purity_5",
               "sweet_5", "sexypics_5")

# identify demographic variables
demoVars <- c("gender", "religionbinary")

# summarize data
rawSummary <- data.frame(psych::describe(rawData[, assocVars]))

# rank data by median association
associationID <- row.names(rawSummary[order(rawSummary$median), ])
rank <- c(1:length(associationID))
ranks <- data.frame(associationID, rank)

# convert to long format, one row per rating
rawDataLong <- reshape(rawData, varying = c(assocVars),
                       v.names = "associationStrength",
                       idvar = "ResponseID",
                       id = assocData$ResponseID, direction = "long",
                       timevar = "associationID",
                       times = assocVars)

# add ranks
rawDataLong <- merge(rawDataLong, ranks, by = "associationID")

#####

# pull in summarized data
summarizedData <- read.csv("summarizedData.csv")


################################################################################
######################### PLOT DATA ############################################
################################################################################

# create a vector of concept pair labels
xlabels <- c("death - selfishness","death - generosity",
             "holding something hot - interpersonal warmth",
             "sugary - kindness","time-self - reflection",
             "sexy pictures - relationship closeness",
             "God - watching",
             "God - generosity","power - self-esteem",
             "patriotism - conservatism",
             "cleanliness - white",
             "elderly people - slow walking",
             "power - being in charge")

# This first plot is a single panel showing overal means overlaid on the raw
# data

singlePanel <- ggplot(data = rawDataLong,
                      aes(x = rank,
                          y = associationStrength)) +
  geom_point(shape = 5, alpha = .1, color = "darkgray",
             aes(group = ResponseID)) + # one point per person per association
  coord_flip() + # flip x and y
  stat_summary(fun.data = mean_cl_boot, , geom = "pointrange",
               colour = "blue") + # add mean & bootstapped 95% CI
  geom_hline(aes(yintercept = 50), color="#FFFF99") + # yellow line at 50
  scale_x_continuous("Concept Pair", breaks=c(1:13), labels = xlabels) + 
  theme_bw() +
  ylab("Association Strength") +
  theme(axis.title.x = element_text(face="bold"), 
        axis.title.y = element_text(face="bold"), 
        axis.text.x  = element_text(colour="#000000"), 
        axis.text.y  = element_text(colour="#000000"))

ggsave("singlePanel.png", singlePanel)


# this second plot just plots the medians and 95% eqivalent bca CIs in three
# panels for (a) all participants, (b) broken down by gender, (c) broken down by
# religion

# how far to separate men from women, religious from non-religious
pd <- position_dodge(.3)

multiPanel <- ggplot(data = summarizedData,
                     aes(x = Rank,
                         y = Median,
                         ymin = LL,
                         ymax = UL,
                         colour=Group)) +
  geom_pointrange(position = pd) + 
  facet_grid(. ~ panel) +
  coord_flip() +
  scale_x_continuous("Concept Pair", breaks=c(1:13), labels = xlabels) + 
  theme_bw() +
  theme(axis.title.x = element_text(face="bold", size=12), 
        axis.title.y = element_text(face="bold", size=12), 
        axis.text.x  = element_text(colour="#000000", size=10), 
        axis.text.y  = element_text(colour="#000000", size=10),
        legend.justification=c(1,0), 
        legend.position=c(1,0),
        legend.key = element_blank(), 
        legend.background = element_rect(fill = "#EEEEEE"),
        legend.text = element_text(size=9)
  ) + 
  scale_colour_discrete(labels=c("All", "Men", "Women", "Religious", "Non-Religious")) + 
  ylab("Median Association Score")

ggsave("multiPanel.png", multiPanel, width = 9)