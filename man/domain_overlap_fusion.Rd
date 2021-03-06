% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ensembleDB_Geneviz_transcript_model.R
\name{domain_overlap_fusion}
\alias{domain_overlap_fusion}
\title{Function to indetify domains retained and lost per breakpoint in gene}
\usage{
domain_overlap_fusion(genesymbol = genesymbol, ensembldb = ensembldb,
  fusionbk = fusionbk, geneposition = geneposition)
}
\arguments{
\item{genesymbol}{gene symbol associated with the fusion breakpoint}

\item{ensembldb}{annotation databse from ensembldb}

\item{fusionbk}{chr:position format breakpoint in fusion}

\item{geneposition}{RIGHT or LEFT gene}
}
\value{
Standardized fusion calls with aggregated Caller and read support
}
\description{
Function to indetify domains retained and lost per breakpoint in gene
}
