library(ggplot2)
library(plyr)
library(reshape2)

args <- commandArgs(TRUE)
expression_data_file <- args[1]
gene <- args[2]

# Read in expression values (in RPKM) for the gene
expression_data <- read.csv(expression_data_file, header=F, stringsAsFactors=F)
colnames(expression_data) <- c("line_no", "donor_id", "donor_name", "donor_age",
                               "gender", "structure_id", "structure_acronym",
                               "structure_name", "RPKM")

# Donor ages for samples are strings (e.g. "8 pcw", "4 mos"), but the nature of
# the input data is that expression values are always listed in temporal order.
# The following line ensures that no further sorting of expression values will
# take place (e.g. by alphabetical order of donor ages).
expression_data$donor_age <- factor(expression_data$donor_age, 
                                    levels=unique(expression_data$donor_age), 
                                    ordered=T)

# Calculate mean expression and standard error of the mean for each donor age
expression_data = expression_data[c("donor_id", "donor_age", "RPKM")]
expression_data <- melt(expression_data, id.vars=c("donor_id", "donor_age"))

means.sem <- ddply(expression_data, c("donor_age", "variable"), summarise,
                   mean=mean(value), sem=sd(value)/sqrt(length(value)))
means.sem[c("sem")][is.na(means.sem[c("sem")])] <- 0
means.sem <- transform(means.sem, lower=mean-sem, upper=mean+sem)

# Plot developmental expression pattern to file "<gene>_expression.png"
png(paste(gene, "expression.png", sep='_'), width=1200, height=900)
ggplot(means.sem, aes(x=donor_age, y=mean),  color="black") + 
  geom_errorbar(aes(ymin=lower, ymax=upper), width=.1, color="red") +
  geom_line(aes(group = variable)) + 
  geom_point() + 
  xlab("Age") +
  ylab("RPKM") +
  ggtitle(paste(gene, "expression", sep=" ")) +
  theme(plot.title = element_text(face="bold"))
dev.off()
