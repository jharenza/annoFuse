% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fusion_driver.R
\name{fusion_driver}
\alias{fusion_driver}
\title{Filter standardized fusion calls for driver fusions}
\usage{
fusion_driver(standardFusioncalls = standardFusioncalls,
  annotated = TRUE,
  geneListReferenceDataTab = geneListReferenceDataTab,
  fusionReferenceDataTab = fusionReferenceDataTab)
}
\arguments{
\item{standardFusioncalls}{A dataframe from star fusion or arriba (more callers to be added)}

\item{annotated}{Boolean if annotated}

\item{geneListReferenceDataTab}{A dataframe with column 1 as GeneName 2 source file 3 type; collapse to summarize type}

\item{fusionReferenceDataTab}{A dataframe with column 1 as FusionName 2 source file 3 type; collapse to summarize type}
}
\value{
Putative Driver standardized fusion calls annotated with gene list and fusion list provided in reference folder
}
\description{
If standardized fusion calls are annotated using the geneListReferenceDataTab and fusionReferenceDataTab filters out fusion calls where partner genes are not annotated.
If standardized fusion is not annotated it will be annotated with geneListReferenceDataTab and fusionReferenceDataTab provided
}
