# The MIT License
# 
# Copyright (c) 2017 Piero Dalle Pezze
# 
# Permission is hereby granted, free of charge, 
# to any person obtaining a copy of this software and 
# associated documentation files (the "Software"), to 
# deal in the Software without restriction, including 
# without limitation the rights to use, copy, modify, 
# merge, publish, distribute, sublicense, and/or sell 
# copies of the Software, and to permit persons to whom 
# the Software is furnished to do so, 
# subject to the following conditions:
# 
# The above copyright notice and this permission notice 
# shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
# ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.





######################################################
# DESeq2-based comparison of strain (A66 vs WT) vs egf
######################################################

# NOTICE: only two samples are labelled with `noEGF`. This may be the reason why 
# this analysis fails.



# download DESeq2 from: 
# source("https://bioconductor.org/biocLite.R")
# biocLite("DESeq2")

library("DESeq2")

source('../utilities/plots.R')



# select the file countaining the data
location <- "../data"
filename.counts <- "summarised_mirna_counts_after_mapping_filtered"
filename.counts.metadata <- "summarised_mirna_counts_after_mapping_filtered_metadata"
suffix <-".csv"
padj.thres <- 0.05
lfc.thres <- 0.1

par(mar=c(5,5,5,5))


#####################################
# Read Counts Table and Samples Table
#####################################

# load counts
counts <- read.table(paste0(location,"/",filename.counts,suffix), sep=",",fill=T,header=T,row.names=1)

# load counts metadata
counts.metadata <- read.table(paste0(location,"/",filename.counts.metadata,suffix), sep=",",fill=T,header=T,row.names=1)
# cast the column `time` from numeric to factor
counts.metadata$time <- as.factor(counts.metadata$time)
# cast the column `replicate` from numeric to factor
counts.metadata$replicate <- as.factor(counts.metadata$replicate)


#######################
# Prepare DESeq dataset
#######################
# create the dataset for DESeq. We use this as an annotated SummarizedExperiment object
# use assay(se), colData(se), design(se) to read the most important info
dds <- DESeqDataSetFromMatrix(countData = counts, colData=counts.metadata, design = ~ 1)

# combine the factors of interest into a single factor with all combinations of the original factors
dds$group <- factor(paste0(dds$egf, dds$strain))

design(dds) <- ~ group





###########
# Run DESeq
###########
# Additional filters for dds

# run DESeq with and without betaPrior
resultsDESeq <- DESeq(dds)

###########################################
# Analysis: WT vs A66 in strain per time point
###########################################

egf_flags <- c('EGF', 'noEGF')

for(egf_flag in egf_flags) {
  
  group1 <- paste0(egf_flag, 'WT')
  group2 <- paste0(egf_flag, 'A66')

  # results WT vs A66 in strain vs EGF
  results.strain.WT_A66 <- results(resultsDESeq, contrast=c("group",group1,group2))
  results.signif.strain.WT_A66 <- subset(results.strain.WT_A66, padj < padj.thres)
  write.csv(results.strain.WT_A66, file=paste0(filename.counts ,"_results_DESeq__strain_vs_", egf_flag, suffix))
  write.csv(results.signif.strain.WT_A66, file=paste0(filename.counts ,"_results_DESeq__strain_vs_", egf_flag, "__padj_", gsub("\\.","",padj.thres), suffix))

  ########################
  # Generate Volcano plots 
  ########################
  # results strain vs egf
  png(paste0(filename.counts,"_VolcanoPlot_results_DESeq__strain_vs_", egf_flag, ".png"), width=2000, height=2000, pointsize=18, res=300)
  signif.genes <- volcano_plot(results.strain.WT_A66, title='strain vs egf', thres.padj=padj.thres, thres.lfc=lfc.thres)
  dev.off()
  write.csv(signif.genes, file=paste0(filename.counts ,"_results_DESeq__strain_vs_", egf_flag, "__padj_", gsub("\\.","",padj.thres), '_lfc_', gsub("\\.","",lfc.thres), suffix))

  ###################
  # Generate MA-plots
  ###################
  # An MA plot is an application of a Bland–Altman plot for visual representation of genomic data. 
  # The plot visualises the differences between measurements taken in two samples, by transforming the 
  # data onto M (log ratio) and A (mean average) scales, then plotting these values.
  # Here we test for differential expression between conditions strain and egf. 
  # The red colour marks genes (here miRNAs) detected as differentially expressed at 10% false discovery rate 
  # when Benjamini-Hochberg multiple testing adjustment is used. The symbols at the upper and lower plot border 
  # indicate genes (here miRNAs) with very large or infinite log fold change.
  # Plot mean expression vs log fold change for the contrast strain vs egf
  png(paste0(filename.counts,"_MAplot_results_DESeq__strain_vs_", egf_flag, ".png"), width=2000, height=2000, pointsize=18, res=300)
  plotMA(results.strain.WT_A66, main='Shrunk LFC')
  dev.off()

  ##############################
  # Generate p-values histograms
  ##############################
  # histogram of p-values for the contrast strain vs egf
  png(paste0(filename.counts,"_pvalues_results_DESeq__strain_vs_egf.png"), width=2000, height=2000, pointsize=18, res=300)
  hist(results.strain.WT_A66$pvalue, breaks=100, col="skyblue", border="slateblue", main='p-values for strain vs egf')
  dev.off()
}











# ###########
# # Run DESeq  (SAME but without betaPrior)
# ###########
# # Additional filters for dds
# 
# # run DESeq without betaPrior
# resultsDESeq.noPrior <- DESeq(dds, betaPrior=FALSE)
# 
# ###########################################
# # Analysis: WT vs A66 in strain per time point
# ###########################################
# 
# egf_flags <- c('EGF', 'noEGF')
# 
# for(egf_flag in egf_flags) {
#   
#   group1 <- paste0(egf_flag, 'WT')
#   group2 <- paste0(egf_flag, 'A66')
#   
#   # Same for the results of DESeq without betaPrior
#   results.strain.WT_A66.noPrior <- results(resultsDESeq.noPrior, contrast=c("group",group1,group2))
#   results.signif.strain.WT_A66.noPrior <- subset(results.strain.WT_A66.noPrior, padj < padj.thres)
#   write.csv(results.strain.WT_A66.noPrior, file=paste0(filename.counts ,"_noprior_results_DESeq__strain_vs_", egf_flag, suffix))
#   write.csv(results.signif.strain.WT_A66.noPrior, file=paste0(filename.counts ,"_noprior_results_DESeq__strain_vs_", egf_flag, "__padj_", gsub("\\.","",padj.thres), suffix))
# 
#   ########################
#   # Generate Volcano plots 
#   ########################
#   # Same for the results of DESeq without betaPrior
#   png(paste0(filename.counts,"_noprior_VolcanoPlot_results_DESeq__strain_vs_", egf_flag, ".png"), width=2000, height=2000, pointsize=18, res=300)
#   signif.genes <- volcano_plot(results.strain.WT_A66.noPrior, title='strain vs egf (no BetaPrior)', thres.padj=padj.thres, thres.lfc=lfc.thres)
#   write.csv(signif.genes, file=paste0(filename.counts ,"_noprior_results_DESeq__strain_vs_", egf_flag, "__padj_", gsub("\\.","",padj.thres), '_lfc_', gsub("\\.","",lfc.thres), suffix))
#   dev.off()
# 
#   ###################
#   # Generate MA-plots
#   ###################
#   # Plot mean expression vs log fold change for the contrast strain vs egf
#   png(paste0(filename.counts,"_noprior_MAplot_results_DESeq__strain_vs_", egf_flag, ".png"), width=2000, height=2000, pointsize=18, res=300)
#   plotMA(results.strain.WT_A66.noPrior, main='Unshrunk LFC')
#   dev.off()
# }
# 
# 
# 
# 
