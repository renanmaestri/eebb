# install_deps.R

# Install CRAN packages
cran_packages <- c("epm", "tmap", "terra", "raster", "sp", "PCPS", "adespatial", "vegan", "picante", "mvMORPH", "RRphylo", "geodist", "progressr", "devtools", "BiocManager")
new_packages <- cran_packages[!(cran_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) {
  install.packages(new_packages, repos="https://cloud.r-project.org/")
}

# Install BioGeoBEARS dependencies from Bioconductor if needed
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
if (!("rexpokit" %in% installed.packages()[,"Package"])) {
  install.packages("rexpokit", repos="https://cloud.r-project.org/")
}
if (!("cladoRcpp" %in% installed.packages()[,"Package"])) {
  install.packages("cladoRcpp", repos="https://cloud.r-project.org/")
}

# Install GitHub packages
if(!("Herodotools" %in% installed.packages()[,"Package"])) {
  devtools::install_github("GabrielNakamura/Herodotools")
}
if(!("BioGeoBEARS" %in% installed.packages()[,"Package"])) {
  devtools::install_github("nmatzke/BioGeoBEARS")
}
if(!("daee" %in% installed.packages()[,"Package"])) {
  devtools::install_github("vanderleidebastiani/daee")
}

cat("Dependencies installed successfully!\n")
