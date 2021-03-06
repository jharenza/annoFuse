#' Function to identify fusions called by at least n callers

#' @param standardFusioncalls A dataframe from star fusion or arriba standardized to run through the filtering steps
#' @param limitMultiFused Integer to identify a limit of times a gene can be fused per sample
#' @return Fusions where gene partner(s) is multifused per sample

fusion_multifused<-function(standardFusioncalls=standardFusioncalls,limitMultiFused=limitMultiFused){

# remove multi-fused genes
fusion_multifused_per_sample <- standardFusioncalls  %>%
  # We want to keep track of the gene symbols for each sample-fusion pair
  dplyr::select(Sample, FusionName, Gene1A, Gene1B, Gene2A, Gene2B) %>%
  # We want a single column that contains the gene symbols
  tidyr::gather(Gene1A, Gene1B, Gene2A, Gene2B,
                key = gene_position, value = GeneSymbol) %>%
  # Remove columns without gene symbols
  dplyr::filter(GeneSymbol != "") %>%
  dplyr::arrange(Sample, FusionName) %>%
  # Retain only distinct rows
  dplyr::distinct() %>%
  group_by(Sample,GeneSymbol) %>%
  dplyr::summarise(Gene.ct = n()) %>%
  dplyr::filter(Gene.ct>limitMultiFused) %>%
  mutate(note=paste0("multfused " ,limitMultiFused, " times per sample"))

return(fusion_multifused_per_sample)

}
