params <-
list(group = "broad_histology")

## ------------------------------------------------------------------------
suppressPackageStartupMessages(library(reshape2))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(qdapRegex))
suppressPackageStartupMessages(library(ggpubr))
suppressPackageStartupMessages(library(randomcoloR))
suppressPackageStartupMessages(library(plotly))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(tibble))

theme_Publication <- function(base_size=15, base_family="Helvetica") {
  library(grid)
  library(ggthemes)
  (theme_foundation(base_size=base_size, base_family=base_family)
    + theme(plot.title = element_text(face = "bold",
                                      size = rel(0.75), hjust = 0.5),
            text = element_text(family="Helvetica"),
            panel.background = element_rect(colour = NA),
            plot.background = element_rect(colour = NA),
            panel.border = element_rect(colour = NA),
            axis.title = element_text(face = "bold",size = 12),
            axis.title.y = element_text(angle=90,vjust =2,size=12),
            axis.title.x = element_text(size=12),
            axis.text = element_text(size=9,color="black",face="bold",angle = 60,hjust = 1),
            axis.line = element_line(colour="black",size=1),
            axis.ticks = element_line(),
            panel.grid.major = element_line(colour="#f0f0f0"),
            panel.grid.minor = element_blank(),
            legend.text = element_text(size=rel(0.7)),
            legend.key = element_rect(colour = NA),
            legend.position = "right",
            legend.direction = "vertical",
            legend.key.size= unit(0.5, "cm"),
            legend.spacing  = unit(1, "mm"),
            legend.title = element_text(family="Helvetica",face="italic",size=rel(0.7)),
            plot.margin=unit(c(10,10,1,10),"mm"),
            strip.background=element_rect(colour="#f0f0f0",fill="#f0f0f0"),
            strip.text = element_text(face="bold")
    ))

}



## ------------------------------------------------------------------------
#read filtFusion files
dataFilteredFusion<-read_tsv(system.file("extdata", "FilteredFusion.tsv", package = "annoFuse")) %>% as.data.frame()
dataPutativeDriver<-read_tsv(system.file("extdata", "PutativeOncogenicFusion.tsv", package = "annoFuse")) %>% as.data.frame()

QCGeneFiltered_filtFusion<-rbind(dataFilteredFusion,dataPutativeDriver)
  
# for recurrent filtering
fusion_calls<-unique(QCGeneFiltered_filtFusion)


# get grouping column id
group<-params$group

# merge with histology file
clinical<-read.delim(system.file("extdata", "pbta-histologies.tsv", package = "annoFuse"),stringsAsFactors = FALSE)
clinical<-clinical[,c("Kids_First_Biospecimen_ID",group,"Kids_First_Participant_ID","disease_type_new")]
clinical<-clinical[!is.na(clinical$broad_histology),]

fusion_calls$FusionName<-unlist(lapply(fusion_calls$FusionName,function(x) rm_between(x, "(", ")", extract = F)))


table(clinical$broad_histology)

## ------------------------------------------------------------------------

# get labels for count per histology
hist.ct <- unique(clinical[,c('broad_histology','Kids_First_Biospecimen_ID','disease_type_new')])
hist.ct <- plyr::count(hist.ct, 'broad_histology')
hist.ct$freq <- paste0(hist.ct$broad_histology,' (n=', hist.ct$freq, ')')
colnames(hist.ct)[2] <- 'Histology.Broad.Label'

#fuse with fusion calls
final <- merge(fusion_calls, hist.ct, by= 'broad_histology')
final <- final %>% group_by(Kids_First_Participant_ID,broad_histology) %>% summarise(value = n())
final <- final %>% group_by(broad_histology) %>% mutate(median = median(value)) %>% as.data.frame()
to.include <- setdiff(clinical$broad_histology, final$broad_histology)
final <- rbind(final, data.frame(Kids_First_Participant_ID = c(rep(NA,length(to.include))),
                                 broad_histology = to.include,
                                 value = c(rep(0,length(to.include))),
                                 median = c(rep(0,length(to.include)))))
final$broad_histology <- reorder(final$broad_histology, final$median)

final<-final[!is.na(final$broad_histology),]



## ------------------------------------------------------------------------

#plot broad histology distribution boxplots
n <- length(levels(as.factor(final$broad_histology)))
palette <- rainbow(n)
names(palette)<-levels(as.factor(final$broad_histology))
colScale <- scale_colour_manual(name = "broad_histology",values = palette)

p1 <- ggplot(final, aes(x = broad_histology, y = log2(value), color = broad_histology, alpha = 0.75)) +
  geom_boxplot(outlier.shape = 21, fill = 'white') +
  geom_jitter(position=position_jitter(width=.1, height=0), shape = 21) +
  stat_boxplot(geom ='errorbar', width = 0.5) +
  guides(alpha = FALSE, fill = FALSE) +
  xlab("BroadHistology") + ylab('Number of Fusions (log2)') +
  guides(color = F) +
  scale_y_continuous(breaks = seq(0, 6, by = 1))+theme(axis.text = element_text(size=9,color="black",face="bold",angle = 45,hjust = 1))+colScale+theme_Publication()+ggtitle("Broad histology distribution")

ggplotly(p1,height = 600, width=1200)


## ------------------------------------------------------------------------

# keep fusion if atleast 1 is protein-coding 
#BiocManager::install("EnsDb.Hsapiens.v86")
library(EnsDb.Hsapiens.v86)
edb <- EnsDb.Hsapiens.v86

genes<-as.data.frame(genes(edb))

# keep if atleast 1 gene is protein coding gene in fusions
fusion_protein_coding_gene_df <- fusion_calls %>%
  # We want to keep track of the gene symbols for each sample-fusion pair
  dplyr::select(Sample, FusionName, Gene1A, Gene1B, Gene2A, Gene2B,broad_histology) %>%
  # We want a single column that contains the gene symbols
  tidyr::gather(Gene1A, Gene1B, Gene2A, Gene2B,
                key = gene_position, value = GeneSymbol) %>%
  # Remove columns without gene symbols
  dplyr::filter(GeneSymbol != "") %>%
  dplyr::arrange(Sample, FusionName) %>%
  # Retain only distinct rows
  dplyr::distinct() %>% left_join(genes,by=c("GeneSymbol"="gene_name"))


head(fusion_protein_coding_gene_df)

## ------------------------------------------------------------------------
fusion_calls_interchromosomal<-fusion_calls %>% dplyr::filter(grepl("INTERCHROMOSOMAL",annots))
fusion_calls_intrachromosomal<-fusion_calls %>% dplyr::filter(grepl("INTRACHROMOSOMAL",annots))

fusion_chrom<-rbind(data.frame(cbind(fusion_calls_interchromosomal,"Distance"=rep("INTERCHROMOSOMAL",nrow(fusion_calls_interchromosomal)))),cbind(fusion_calls_intrachromosomal,"Distance"=rep("INTRACHROMOSOMAL",nrow(fusion_calls_intrachromosomal)))) %>% unique()

p2<-ggplot(fusion_chrom,aes(x=broad_histology,fill=Distance,alpha=0.75))+geom_bar()+theme_Publication()+theme(axis.text = element_text(size=9,color="black",face="bold",angle = 60,hjust = 1),legend.position = "bottom",legend.text = element_text(size=rel(0.7)),)+ggtitle("Chromosomal Distance")+xlab("BroadHistology")+guides(alpha=FALSE)
ggplotly(p2,height = 600, width=1200)



## ------------------------------------------------------------------------
# bubble plot for genes in kinase/oncoplot etc
fusion_type_gene_df <- fusion_calls %>%
  # We want to keep track of the gene symbols for each sample-fusion pair
  dplyr::select(Sample, FusionName, Gene1A_anno, Gene1B_anno, Gene2A_anno, Gene2B_anno,broad_histology) %>%
  unique() %>%
  # We want a single column that contains the gene symbols
  tidyr::gather(Gene1A_anno, Gene1B_anno, Gene2A_anno, Gene2B_anno,
                key = gene_position, value = Annot) %>%
  # Remove columns without gene symbols
  dplyr::filter(Annot != "") %>%
  mutate(Annot=gsub(" ","",.$Annot)) %>%
  mutate(Annot = strsplit(as.character(Annot), ",")) %>% 
  unnest(Annot)  %>%
  group_by(broad_histology,Annot) %>% 
  dplyr::summarise(Annot.ct = n()) %>%
  dplyr::filter(!Annot %in% c("curatedTF","predictedTF"))

fusion_type_gene_df$Annot[grep("onco",fusion_type_gene_df$Annot)]<-"Oncogene"
fusion_type_gene_df$Annot[grep("tsgs",fusion_type_gene_df$Annot)]<-"TumorSuppressorGene"
fusion_type_gene_df$Annot[grep("kinase",fusion_type_gene_df$Annot)]<-"Kinase"


p3<-plotly::plot_ly(fusion_type_gene_df, x = ~broad_histology, y= ~Annot.ct, type = 'scatter', mode = 'markers', size = ~Annot.ct, color = ~Annot,sizes=c(1,max(fusion_type_gene_df$Annot.ct)),height = 600, width=1200)
p3





## ------------------------------------------------------------------------

# bubble plot for genes in biotype fromensemble
fusion_type_gene_df <- fusion_protein_coding_gene_df %>%
  # We want to keep track of the gene symbols for each sample-fusion pair
  dplyr::select(Sample, FusionName, gene_position, gene_biotype,broad_histology) %>%
  unique() %>%
  group_by(broad_histology,gene_biotype,gene_position) %>% 
  dplyr::summarise(Type.ct = n())

p4<-plotly::plot_ly(fusion_type_gene_df, x = ~gene_biotype, y= ~gene_position, type = 'scatter', mode = 'markers', size = ~Type.ct, color = ~gene_position,sizes=c(1,max(fusion_type_gene_df$Type.ct)),height = 600, width=1200)
p4






## ------------------------------------------------------------------------
kinaseGeneList<-read_tsv("~/Documents/annofusion/inst/extdata/Kincat_Hsap.08.02.txt")

kinase_fusion<-fusion_protein_coding_gene_df %>%
  left_join(kinaseGeneList,by=c("GeneSymbol"="Name")) %>%
  dplyr::filter(!is.na(Family)) %>%
  dplyr::select("gene_position","Group","Sample") %>%
  unique() %>%
  group_by(Group,gene_position) %>% 
  dplyr::summarise(Type.ct = n()) %>% 
  unique()
  


p5<-ggplot(kinase_fusion,aes(x=Group,y=Type.ct,fill=gene_position,alpha=0.75))+geom_col()+scale_color_brewer(palette="Pastel2")+scale_fill_brewer(palette="Pastel2")+theme_Publication()+ylab("Count")+theme(legend.position = "bottom")+ggtitle("Kinase group distribution")+guides(alpha=FALSE)
ggplotly(p5,height = 600, width=1200)



