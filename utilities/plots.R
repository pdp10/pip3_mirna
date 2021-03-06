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


library(reshape2)
library(ggplot2)
library(data.table)

library(VennDiagram)

#source("https://bioconductor.org/biocLite.R")
#biocLite("made4")
library(made4)


source('../utilities/deseq.R')



################
# ggplot2 themes
################

# A simple theme without grid
theme_basic <- function(base_size = 12){
  theme_bw(base_size) %+replace%
  theme(
      panel.grid.major=element_blank(), 
      panel.grid.minor=element_blank()
    )
}





##############
# time courses
##############


# Plot a data frame of lines and a data frame of points.
plot_all_expr_tc_wcolour <- function(df.line, df.point, filename, title='expression', xlab='time [m]', ylab='mean standardised expression', colorlab='strain') {
  g <- ggplot() +
    geom_line(data=df.line, aes(x=variable, y=value, group=id, color=colour)) + 
    geom_point(data=df.point, aes(x=variable, y=value, group=id, color=colour)) +
    theme_basic() + 
    labs(title=title, x=xlab, y=ylab, color=colorlab)
  ggsave(filename, width=4, height=4, dpi=300)
  return(g)
}


# Plot a data frame of lines and a data frame of points.
plot_mean_expr_tc_wcolour <- function(df.line, df.point, filename, title='expression', xlab='time [m]', ylab='mean standardised expression', colorlab='strain') {
  g <- ggplot() +
    geom_line(data=df.line, aes(x=variable, y=value, group=colour, color=colour)) + 
    geom_point(data=df.point, aes(x=variable, y=value, group=colour, color=colour)) +
    theme_basic() + 
    labs(title=title, x=xlab, y=ylab, color=colorlab)
  ggsave(filename, width=4, height=4, dpi=300)
  return(g)
}





# Plot miRNAs time courses with colour
plot_expr_tc_wcolour <- function(df, filename, line=TRUE, gradient=TRUE, title='expression', xlab='time [m]', ylab='expression', colorlab='strain') {
  g <- ggplot(data=df, aes(x=variable, y=value, group=miRNA, color=colour)) + 
    theme_basic() + 
    labs(title=title, x=xlab, y=ylab, color=colorlab)
  if(gradient) {
    g <- g + scale_colour_gradient2(low="red", mid="lightgrey", high="navyblue")
  }
  if(line) {
    g <- g + geom_line()
  } else {
    g <- g + geom_point()
  }
  ggsave(filename, width=4, height=4, dpi=300)
  return(g)
}


# Plot miRNAs time courses
plot_expr_tc <- function(df, filename, line=TRUE, title='expression', xlab='time [m]', ylab='expression') {
  g <- ggplot(data=df, aes(x=variable, y=value, group=miRNA)) + 
    theme_basic() + 
    labs(title=title, x=xlab, y=ylab)
  if(line) {
    g <- g + geom_line()
  } else {
    g <- g + geom_point()
  }
  ggsave(filename, width=4, height=4, dpi=300)
  return(g)
}




# plot DESeq2 Log2FoldChange time courses with Strain as a colour.
plot_deseq_lfc_tc_wstrain <- function(deseq2.tc.files, deseq2.strain.file, deseq2.strain.signif.file, filter.vec=c(), filename.out) {
  
  # Merge time course data sets
  #############################
  # Create a data frame of Deseq2:log2FoldChange time courses. 
  df.tc <- deseq_lfc_time_course_df(deseq2.tc.files)
  if(!('0' %in% colnames(df.tc))) {
    df.tc <- data.frame('0'=rep(0, nrow(df.tc)), df.tc, check.names = FALSE)
  }
  
  # Extract DESeq:strain for colour information
  #############################################
  # Load log2FoldChange for Strain
  df.strain <- read.table(deseq2.strain.file, sep=",",fill=T,header=T,row.names=1)
  # Extract the names of the significant miRNA when contrast:Strain. 
  df.strain.signif.mirna <- rownames(read.table(deseq2.strain.signif.file, sep=",",fill=T,header=T,row.names=1))
  
  # Filtered a subset of miRNA
  ############################
  if(length(filter.vec) != 0) {
    df.tc <- subset(df.tc, rownames(df.tc) %in% filter.vec)
    df.strain <- subset(df.strain, rownames(df.strain) %in% filter.vec)
    df.strain.signif.mirna <- subset(df.strain.signif.mirna, df.strain.signif.mirna %in% filter.vec)
  }
  
  # Melt and plot data frames
  ###########################
  df <- df.tc
  # add miRNA as new row
  df$miRNA <- rownames(df)
  # Add strain (colour) (Log2 fold change)
  df$colour <- df.strain[,2]
  # Melt times so that we have 'miRNA', 'colour', 'variable' (time-cols), 'value' (time-vals)
  df.melt <- melt(df, id=c('miRNA','colour'))
  # Plot
  plot_expr_tc_wcolour(df=df.melt, filename=paste0(filename.out, ".png"), 
                       title='miRNA expression', xlab='time [m]', ylab='log2 fold change', colorlab='strain')
  
  # Due to the high number of miRNA, we also filter those having significant change in DESeq contrast `Strain`.
  df.signif <- df[df.strain.signif.mirna,]
  # Melt
  df.melt.signif <- melt(df.signif, id=c('miRNA','colour'))
  # Plot
  plot_expr_tc_wcolour(df=df.melt.signif, filename=paste0(filename.out, "__signif", ".png"),
                       title='miRNA expression', xlab='time [m]', ylab='log2 fold change', colorlab='strain')
  
}


# plot DESeq2 Log2FoldChange time courses with PAM clustering labels as a colour.
plot_deseq_lfc_tc_wpam <- function(deseq2.tc.files, pam.clust.file, filter.vec=c(), filename.out) {
  
  # Merge time course data sets
  #############################
  # Create a data frame of Deseq2:log2FoldChange time courses. 
  df.tc <- deseq_lfc_time_course_df(deseq2.tc.files)
  if(!('0' %in% colnames(df.tc))) {
    df.tc <- data.frame('0'=rep(0, nrow(df.tc)), df.tc, check.names = FALSE)
  }
  
  # Load PAM cluster labels for colour information
  #############################################
  # Load strain information
  df.pam <- read.table(pam.clust.file, sep=",",fill=T,header=T,row.names=1)
  
  # Filtered a subset of miRNA
  ############################
  if(length(filter.vec) != 0) {
    df.tc <- subset(df.tc, rownames(df.tc) %in% filter.vec)
    df.pam <- subset(df.pam, rownames(df.pam) %in% filter.vec)
  }
  
  # Melt and plot data frames
  ###########################
  df <- df.tc
  # add miRNA as new row
  df$miRNA <- rownames(df)
  # Add PAM cluster (colour)
  # pam is converted to factor so that it is not automatically interpreted as a continuous variable
  df$colour <- factor(df.pam[,1])
  # Melt times so that we have 'miRNA', 'pam', 'variable' (time-cols), 'value' (time-vals)
  df.melt <- melt(df, id=c('miRNA','colour'))
  
  # Plot miRNA using PAM clustering for colours
  plot_expr_tc_wcolour(df=df.melt, filename=paste0(filename.out, ".png"), gradient=FALSE, 
                       title='miRNA expression', xlab='time [m]', ylab='log2 fold change', colorlab='pam')
  
}







#####
# PCA
#####

# Plot PCA with strain and time (PC1, PC2, PC3)
plot_pca <- function(df, eigen, filename) {
  # PC1 vs PC2
  c1c2.strain.time <- ggplot(df) + 
    geom_point(aes(x=PC1, y=PC2, colour=strain, shape=as.factor(time)), size=3) +  
    labs(x=sprintf("PC1 %.1f %%",eigen[1,2]), y=sprintf("PC2 %.1f %%",eigen[2,2]), shape='time (min)') +
    theme_basic(base_size = 16)
  
  # PC2 vs PC3
  c2c3.strain.time <- ggplot(df) + 
    geom_point(aes(x=PC2, y=PC3, colour=strain, shape=as.factor(time)), size=3) +  
    labs(x=sprintf("PC2 %.1f %%",eigen[2,2]), y=sprintf("PC3 %.1f %%",eigen[3,2]), shape='time (min)') +
    theme_basic(base_size = 16)
  
  # PC1 vs PC3
  c1c3.strain.time <- ggplot(df) + 
    geom_point(aes(x=PC1, y=PC3, colour=strain, shape=as.factor(time)), size=3) +  
    labs(x=sprintf("PC1 %.1f %%",eigen[1,2]), y=sprintf("PC3 %.1f %%",eigen[3,2]), shape='time (min)') +
    theme_basic(base_size = 16)  
  
  ## COMBINED plots
  c1c2c3.combined <- arrangeGrob(c1c2.strain.time, c2c3.strain.time, c1c3.strain.time, ncol=3)
  ggsave(filename, plot=c1c2c3.combined, width=17, height=4, dpi=300)
  
  return(c1c2c3.combined)
}


# Plot PCA with PAM clustering (colour is cluster)
plot_pca_clustering <- function(df, filename, show.labels=FALSE) {
  
  # Plot Clustering
  # PC1 vs PC2
  c1c2.pam <- ggplot(data=df) + 
    geom_point(aes(x=PC1, y=PC2, colour=cluster), size=3) +  
    labs(x="PC1", y="PC2", shape='time (min)') +
    theme_basic(base_size = 16)
  
  # PC2 vs PC3
  c2c3.pam <- ggplot(data=df) + 
    geom_point(aes(x=PC2, y=PC3, colour=cluster), size=3) +  
    labs(x="PC2", y="PC3", shape='time (min)') +
    theme_basic(base_size = 16)
  
  # PC1 vs PC3
  c1c3.pam <- ggplot(data=df) + 
    geom_point(aes(x=PC1, y=PC3, colour=cluster), size=3) +  
    labs(x="PC1", y="PC3", shape='time (min)') +
    theme_basic(base_size = 16)
  
  if(show.labels) {
    c1c2.pam <- c1c2.pam +
      geom_text(data=df, aes(x=PC1, y=PC2, label=label),hjust=0,vjust=1, color="black", size=2.5)
    c2c3.pam <- c2c3.pam +
      geom_text(data=df, aes(x=PC2, y=PC3, label=label),hjust=0,vjust=1, color="black", size=2.5)
    c1c3.pam <- c1c3.pam +
      geom_text(data=df, aes(x=PC1, y=PC3, label=label),hjust=0,vjust=1, color="black", size=2.5)
    
    ## COMBINE plots
    c1c2c3.pam.combined <- arrangeGrob(c1c2.pam, c2c3.pam, c1c3.pam, ncol=3)
    ggsave(filename, plot=c1c2c3.pam.combined, width=14, height=3.5, dpi=300)
  } else {
    ## COMBINED plots
    c1c2c3.pam.combined <- arrangeGrob(c1c2.pam, c2c3.pam, c1c3.pam, ncol=3)
    ggsave(filename, plot=c1c2c3.pam.combined, width=14, height=3.5, dpi=300)
  }  
}




# Plot PCA based on DESeq2:plotPCA()
plotPrettyPCA1Var <- function(x, intgroup=c("condition"), ntop=500, plotColor=TRUE) {
  x.data <- plotPCA(x, intgroup=intgroup, ntop=ntop, returnData=TRUE)
  percentVar <- round(100 * attr(x.data, "percentVar"))
  # Depending on plotColor, we decide if plotting values using different colours or shapes.
  shape <- NULL
  color <- NULL
  if(plotColor) { 
    color <- intgroup[1] 
  } else { 
    shape <- intgroup[1] 
  }
  ggplot(x.data, aes_string(x="PC1", y="PC2", color=color, shape=shape)) +
    geom_point(size=3) +
    xlab(paste0("PC1: ", percentVar[1], "% variance")) +
    ylab(paste0("PC2: ", percentVar[2], "% variance")) +
    coord_fixed() + 
    theme_bw() + 
    theme(panel.grid.major=element_blank(), panel.grid.minor=element_blank())
}

# Plot PCA based on DESeq2:plotPCA()
plotPrettyPCA2Var <- function(x, intgroup=c("condition1", "condition2"), ntop=500) {
  x.data <- plotPCA(x, intgroup=intgroup, ntop=ntop, returnData=TRUE)
  percentVar <- round(100 * attr(x.data, "percentVar"))
  ggplot(x.data, aes_string(x="PC1", y="PC2", color=intgroup[1], shape=intgroup[2])) +
    geom_point(size=3) +
    xlab(paste0("PC1: ", percentVar[1], "% variance")) +
    ylab(paste0("PC2: ", percentVar[2], "% variance")) +
    coord_fixed() + 
    theme_bw() + 
    theme(panel.grid.major=element_blank(), panel.grid.minor=element_blank())
}




##########
# HEATPLOT
##########

# use these functions for clustering like heatplot.
dist.pear <- function(x) as.dist(1-cor(t(x)))
hclust.ave <- function(x) hclust(x, method="ward.D")

# plot the counts matrix using heatmap.2
plot_counts_matrix_heatmap <- function(df, filename="heatmap.png", palette=redgreen(50), dendrogram="both", scale="none", trace="none", labRow=FALSE, ylab='miRNA', xlab='Samples') {
  png(file=filename, width=8, height=8, units="in", bg="white", res=300)
  heatmap.2(as.matrix(df), col=palette,
            dendrogram=dendrogram, scale=scale, trace=trace,
            distfun=dist.pear, hclustfun=hclust.ave,
            margins = c(9, 3),
            labRow = labRow, ylab=ylab, xlab=xlab)
  dev.off()
}


# plot the counts matrix using heatplot
plot_counts_matrix_heatplot <- function(df, filename="heatplot.png", dendrogram="both", scale="row", method="ward.D", labRow=FALSE, ylab='miRNA', xlab='Samples') {
  png(file=filename, width=8, height=8, units="in", bg="white", res=300)  
  heatplot(df, 
           dend=dendrogram, scale=scale, 
           cols.default=FALSE, lowcol="blue", highcol="yellow", 
           method=method,
           margins = c(9, 3),
           keysize=1, #key.par = list(cex=0.5)
           labRow = labRow, ylab=ylab, xlab=xlab)
  dev.off()
}




####################
# CORRELATION MATRIX
####################

# Compute and plot correlation matrix of samples
plot_corr_matrix <- function(counts, method) {
  
  # calculate the correlation matrix using pearson correlation coefficients
  counts.corr.mat <- cor(counts, method='pearson')
  
  # cut off the lower triangle
  counts.corr.mat[lower.tri(counts.corr.mat)]<- NA
  
  # Melt the correlation matrix
  counts.corr.mat.melt <- melt(counts.corr.mat, na.rm = TRUE)
  
  # Heatmap
  ggheatmap <- ggplot(data = counts.corr.mat.melt, aes(Var2, Var1, fill = value))+
    geom_tile(color = "white")+
    scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                         midpoint = 0.975, limit = c(0.95,1), space = "Lab", 
                         name="Pearson\nCorrelation") +
    scale_y_discrete(position="right") + 
    #theme_minimal() + 
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, size = 7, hjust = 1),
          axis.text.y = element_text(size = 7),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          panel.grid.major = element_blank(),
          panel.border = element_blank(),
          panel.background = element_blank(),
          axis.ticks = element_blank(),
          legend.justification = c(1, 0),
          legend.position = c(0.3, 0.4))+
    coord_fixed()
  return(ggheatmap)
}





############
# STATISTICS
############

plot_read_density <- function(d) {
  d$samples <- paste(d$strain, d$time, d$rep, sep = "_")
  p <- ggplot(as.data.frame(d), aes(value, color = samples)) +
    geom_density() +
    theme_basic() + 
    theme(legend.key.size = unit(0.4, "cm")) +
    scale_x_log10()
  ggsave("miRNA_read_density_per_sample.png", width=6, height=4, dpi=300)
  p <- p + facet_grid(strain ~ time)
  ggsave("miRNA_read_density_per_sample_facet.png", width=6, height=4, dpi=300)    
}

plot_read_ecdf <- function(d) {
  d$samples <- paste(d$strain, d$time, d$rep, sep = "_")
  p <- ggplot(as.data.frame(d), aes(value, color = samples)) +
    stat_ecdf() +
    theme_basic() + 
    theme(legend.key.size = unit(0.4, "cm")) +
    scale_x_log10() 
  ggsave("miRNA_read_ecdf_per_sample.png", width=6, height=4, dpi=300)
  p <- p + facet_grid(strain ~ time)
  ggsave("miRNA_read_ecdf_facet_per_sample.png", width=6, height=4, dpi=300)  
}

plot_counts_density <- function(df, filename) {
  png(file=filename, width=8, height=8, units="in", bg="white", res=300)
  plot(density(as.matrix(df)))
  dev.off()
}




###############
# Volcano plots
###############

# Generate a volcano plot and return the list of significant genes
volcano_plot <- function(deseq2.res, thres.padj = 0.05, thres.lfc = 0.5, title="padj versus fold change", show.x.annot=TRUE, show.y.annot=TRUE) {
  df <- data.frame(log2FoldChange=deseq2.res$log2FoldChange, negLog10Padj=-log10(deseq2.res$padj))
  rownames(df) <- rownames(deseq2.res)
  # plot
  par(mar = c(5,5,5,4))
  signif.genes <- ( df$negLog10Padj > -log10(thres.padj) & abs(df$log2FoldChange) > thres.lfc )
  plot(df, xlab=expression(log[2]~fold~change), ylab=expression(-log[10]~padj),
       pch=16, cex=0.5)
  
  points(df, pch=16, cex=0.5, col="grey")
  points(df[signif.genes & df$log2FoldChange>thres.lfc, ], pch=16, cex=0.5, col="red") 
  points(df[signif.genes & df$log2FoldChange<thres.lfc, ], pch=16, cex=0.5, col="blue") 
  
  abline(h = -log10(thres.padj), col="black", lty=2, lwd=1.5)
  abline(v = c(-thres.lfc, thres.lfc), col="black", lty=2, lwd=1.5)
  if(show.y.annot) {
    mtext(paste0("padj=",thres.padj), side=4, at=-log10(thres.padj), cex=0.8, line=0.5, las=1)
  }
  if(show.x.annot) {
    mtext(c(paste0("-", thres.lfc), paste0("+", thres.lfc)), side=3, at=c(-thres.lfc-0.05,thres.lfc+0.05), cex=0.8, line=0.2)
  }
  title(title)
  return(df[signif.genes,])
}





###############
# Venn Diagrams
###############

plot_venn_diagram <- function(data, filename, category.names, colours) {
  # suppress the log file venn.diagram generates
  futile.logger::flog.threshold(futile.logger::ERROR, name = "VennDiagramLogger")
  # Now we plot the Venn diagram
  venn.diagram(
    x = data,
    category.names = category.names,
    filename = paste0(filename, ".png"),
    output = FALSE,
    imagetype="png",
    height = 1000, 
    width = 1000, 
    resolution = 300,
    compression = "lzw",
    lwd = 1,
    lty = 'blank',
    fill = colours,
    margin=c(0.05,0.05),
    cex = 1,
    fontfamily = "sans",
    cat.cex = 0.6,
    cat.default.pos = "outer",
    #cat.pos = c(-15, 12),
    #cat.dist = c(0.050, 0.055),
    cat.fontfamily = "sans"
  )
}



