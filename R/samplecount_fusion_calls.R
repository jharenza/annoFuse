#' Function to identify fusions called in n samples

#' @param standardFusioncalls A dataframe from star fusion or arriba standardized to run through the filtering steps
#' @param numSample Least number of samples per group that have the fusion
#' @param group column name for grouping variable
#' @return Fusions found in atleast n samples

samplecount_fusion_calls<-function(standardFusioncalls=standardFusioncalls,numSample=numSample,group=group){

#Found in at least n samples in each group

sample.count <- standardFusioncalls %>%
  dplyr::filter(Fusion_Type != "other") %>%
  dplyr::select(FusionName, Sample, !!as.name(group),-Fusion_Type) %>%
  unique() %>%
  group_by(FusionName, !!as.name(group)) %>%
  dplyr::mutate(sample.count = n(),Sample = toString(Sample)) %>%
  dplyr::filter(sample.count > numSample) %>%
  unique() %>%
  mutate(note=paste0("Found in atleast ",numSample, " samples in a group")) %>%
  as.data.frame()

return(sample.count)
}
