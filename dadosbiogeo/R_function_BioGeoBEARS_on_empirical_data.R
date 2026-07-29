#' Run BioGeoBEARS analysis on empirical data.
#'
#' This function takes a single empirical geography file (PHYLIP format)
#' and a phylogeny (Newick format), runs a BioGeoBEARS analysis, and
#' returns the best model and its results.
#'
#' @param geography_file Path to the PHYLIP-formatted geography file.
#' @param phylogeny_file Path to the Newick-formatted phylogeny file.
#' @param max_range_size The maximum number of areas a species can inhabit
#'   in the BioGeoBEARS analysis. This should match the number of areas
#'   defined in your geography file.
#' @param num_cores The number of cores to use for parallel processing in
#'   BioGeoBEARS. Default: 1.
#' @param min_branchlength A small value to add to zero branch lengths in the
#'   phylogeny. BioGeoBEARS can be sensitive to zero branch lengths. Default: 0.000001.
#'
#' @return A list containing:
#' \itemize{
#'  \item \strong{restable_AIC_rellike}: A table summarizing the AIC and relative
#'    likelihood of each model.
#'  \item \strong{best_model_name}: The name of the model with the lowest AIC.
#'  \item \strong{best_model_output}: The full BioGeoBEARS results object for the best model.
#'  \item \strong{all_model_results}: A named list containing the full BioGeoBEARS
#'    results objects for all models (DEC, DEC+J, DIVALIKE, etc.).
#' }
#'
#' @details This function will run the DEC, DEC+J, DIVALIKE, DIVALIKE+J,
#'   BAYAREALIKE, and BAYAREALIKE+J models. It selects the best model based on AIC.
#'   Ensure that all required BioGeoBEARS dependencies (ape, optimx, GenSA,
#'   rexpokit, cladoRcpp, parallel, BioGeoBEARS) are installed.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Assuming you have 'my_geography.txt' (PHYLIP) and 'my_phylogeny.nwk' (Newick)
#' # in your working directory.
#'
#' # Create dummy files for demonstration (replace with your actual files)
#' # This part is for example only, you'd load your real data
#' library(ape)
#' dummy_tree <- rtree(10, min.edge.length = 0.1)
#' write.tree(dummy_tree, file = "my_phylogeny.nwk")
#'
#' # Create a dummy geography file (e.g., 4 areas A, B, C, D)
#' # This is just to make the example runnable. Your file should have real data.
#' dummy_geog_data <- matrix(0, nrow = 10, ncol = 4,
#'                           dimnames = list(dummy_tree$tip.label, c("A", "B", "C", "D")))
#' dummy_geog_data[1:3, 1] <- 1 # Species 1-3 in area A
#' dummy_geog_data[4:6, 2] <- 1 # Species 4-6 in area B
#' dummy_geog_data[7:8, 3] <- 1 # Species 7-8 in area C
#' dummy_geog_data[9:10, 4] <- 1 # Species 9-10 in area D
#' dummy_geog_data[1,2] <- 1 # Species 1 also in area B
#' 
#' # Convert to character for write.table to preserve 0s and 1s as text
#' write.table(dummy_geog_data, file = "my_geography.txt",
#'             col.names = FALSE, row.names = TRUE, quote = FALSE, sep = "\t")
#'
#' result_empirical <- run_empirical_biogeobears(
#'   geography_file = "my_geography.txt",
#'   phylogeny_file = "my_phylogeny.nwk",
#'   max_range_size = 4, # Adjust based on your actual areas (A, B, C, D = 4 areas)
#'   num_cores = 2
#' )
#'
#' # Print results
#' print(result_empirical$restable_AIC_rellike)
#' print(result_empirical$best_model_name)
#' # Access the best model object
#' # best_res <- result_empirical$best_model_output
#' }
run_empirical_biogeobears <- function(geography_file, phylogeny_file, max_range_size, num_cores = 1, min_branchlength = 0.000001) {
  # --- 1. Load Required Packages ---
  # Ensure all BioGeoBEARS dependencies are installed
  required_packages <- c("ape", "optimx", "GenSA", "rexpokit", "cladoRcpp", "parallel", "BioGeoBEARS")
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop(paste("Package '", pkg, "' needed for this function to work. Please install it with install.packages('", pkg, "').", sep=""))
    }
    library(pkg, character.only = TRUE, quietly = TRUE) # Load the package
  }
  
  # --- 2. Input Validation ---
  if (!file.exists(geography_file)) {
    stop(paste("Geography file not found:", geography_file))
  }
  if (!file.exists(phylogeny_file)) {
    stop(paste("Phylogeny file not found:", phylogeny_file))
  }
  if (!is.numeric(max_range_size) || max_range_size < 1) {
    stop("max_range_size must be a positive numeric value.")
  }
  if (!is.numeric(num_cores) || num_cores < 1 || num_cores %% 1 != 0) {
    stop("num_cores must be a positive integer.")
  }
  
  # --- 3. Load Data ---
  # Load phylogeny
  phy <- read.tree(phylogeny_file)
  # Add small value to edge lengths if any are zero (BioGeoBEARS sensitive to this)
  phy$edge.length[phy$edge.length == 0] <- min_branchlength
  
  # Set up geography file path and read tip ranges
  geogfn <- np(geography_file) # np() ensures path is in native format
  tipranges <- getranges_from_LagrangePHYLIP(lgdata_fn = geogfn)
  
  # --- 4. Define Helper Function to Run a Single BioGeoBEARS Model ---
  run_biogeobears_model <- function(model_name, res_object_name, trfn, geogfn, max_range_size, num_cores, include_null = TRUE) {
    BioGeoBEARS_run_object <- define_BioGeoBEARS_run()
    BioGeoBEARS_run_object$trfn <- trfn
    BioGeoBEARS_run_object$geogfn <- geogfn
    BioGeoBEARS_run_object$max_range_size <- max_range_size
    BioGeoBEARS_run_object$min_branchlength <- min_branchlength # Use the min_branchlength from main function
    BioGeoBEARS_run_object$include_null_range <- include_null
    
    BioGeoBEARS_run_object <- readfiles_BioGeoBEARS_run(BioGeoBEARS_run_object)
    BioGeoBEARS_run_object$return_condlikes_table <- TRUE
    BioGeoBEARS_run_object$calc_TTL_loglike_from_condlikes_table <- TRUE
    BioGeoBEARS_run_object$calc_ancprobs <- TRUE
    BioGeoBEARS_run_object = fix_BioGeoBEARS_params_minmax(BioGeoBEARS_run_object = BioGeoBEARS_run_object)
    check_BioGeoBEARS_run(BioGeoBEARS_run_object)
    BioGeoBEARS_run_object$num_cores_to_use <- num_cores # Use user-specified number of cores
    
    # Set model-specific parameters based on original function's logic
    if (model_name == "DEC+J") {
      # Safely get initial values if previous model (DEC) exists
      dstart <- if (exists("resDEC", envir = .GlobalEnv)) get("resDEC", envir = .GlobalEnv)$outputs@params_table["d", "est"] else 0.1
      estart <- if (exists("resDEC", envir = .GlobalEnv)) get("resDEC", envir = .GlobalEnv)$outputs@params_table["e", "est"] else 0.1
      jstart <- 0.0001
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["d", "init"] <- dstart
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["d", "est"] <- dstart
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["e", "init"] <- estart
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["e", "est"] <- estart
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["j", "type"] <- "free"
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["j", "init"] <- jstart
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["j", "est"] <- jstart
    } else if (model_name %in% c("DIVALIKE", "DIVALIKE+J")) {
      BioGeoBEARS_run_object$include_null_range <- TRUE
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s", "type"] <- "fixed"
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s", "init"] <- 0.0
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s", "est"] <- 0.0
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["ysv", "type"] <- "2-j"
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["ys", "type"] <- "ysv*1/2"
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["y", "type"] <- "ysv*1/2"
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["v", "type"] <- "ysv*1/2"
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01v", "type"] <- "fixed"
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01v", "init"] <- 0.5
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01v", "est"] <- 0.5
      if (model_name == "DIVALIKE+J") {
        BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["j", "type"] <- "free"
        jstart <- if (exists("resDIVALIKE", envir = .GlobalEnv)) get("resDIVALIKE", envir = .GlobalEnv)$outputs@params_table["j", "est"] else 0.0001
        BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["j", "init"] <- jstart
        BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["j", "est"] <- jstart
        BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["j", "min"] <- 0.00001
        BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["j", "max"] <- 1.99999
      }
    } else if (model_name %in% c("BAYAREALIKE", "BAYAREALIKE+J")) {
      BioGeoBEARS_run_object$include_null_range <- TRUE
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s", "type"] <- "fixed"
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s", "init"] <- 0.0
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["s", "est"] <- 0.0
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["v", "type"] <- "fixed"
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["v", "init"] <- 0.0
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["v", "est"] <- 0.0
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["ysv", "type"] <- "1-j"
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["ys", "type"] <- "ysv*1/1"
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["y", "type"] <- "1-j"
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01y", "type"] <- "fixed"
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01y", "init"] <- 0.9999
      BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["mx01y", "est"] <- 0.9999
      if (model_name == "BAYAREALIKE+J") {
        BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["j", "type"] <- "free"
        jstart <- if (exists("resBAYAREALIKE", envir = .GlobalEnv)) get("resBAYAREALIKE", envir = .GlobalEnv)$outputs@params_table["j", "est"] else 0.0001
        BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["j", "init"] <- jstart
        BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["j", "est"] <- jstart
        BioGeoBEARS_run_object$BioGeoBEARS_model_object@params_table["j", "max"] <- 0.99999
      }
    }
    
    BioGeoBEARS_run_object = fix_BioGeoBEARS_params_minmax(BioGeoBEARS_run_object = BioGeoBEARS_run_object)
    check_BioGeoBEARS_run(BioGeoBEARS_run_object)
    
    cat(paste0("Running BioGeoBEARS model: ", model_name, "...\n"))
    res <- bears_optim_run(BioGeoBEARS_run_object)
    
    # Assign result to global environment so subsequent models can access
    # (e.g., resDEC for resDECj). This is common in BioGeoBEARS examples.
    assign(res_object_name, res, envir = .GlobalEnv) 
    
    return(res)
  }
  
  # --- 5. Run BioGeoBEARS Models ---
  # (Note: Results are temporarily assigned to .GlobalEnv for sequential model parameter init)
  resDEC <- run_biogeobears_model("DEC", "resDEC", phylogeny_file, geography_file, max_range_size, num_cores, include_null = FALSE)
  resDECj <- run_biogeobears_model("DEC+J", "resDECj", phylogeny_file, geography_file, max_range_size, num_cores, include_null = FALSE)
  resDIVALIKE <- run_biogeobears_model("DIVALIKE", "resDIVALIKE", phylogeny_file, geography_file, max_range_size, num_cores, include_null = TRUE)
  resDIVALIKEj <- run_biogeobears_model("DIVALIKE+J", "resDIVALIKEj", phylogeny_file, geography_file, max_range_size, num_cores, include_null = TRUE)
  resBAYAREALIKE <- run_biogeobears_model("BAYAREALIKE", "resBAYAREALIKE", phylogeny_file, geography_file, max_range_size, num_cores, include_null = TRUE)
  resBAYAREALIKEj <- run_biogeobears_model("BAYAREALIKE+J", "resBAYAREALIKEj", phylogeny_file, geography_file, max_range_size, num_cores, include_null = TRUE)
  
  # Store all model results in a list
  all_model_results <- list(
    DEC = resDEC,
    `DEC+J` = resDECj,
    DIVALIKE = resDIVALIKE,
    `DIVALIKE+J` = resDIVALIKEj,
    BAYAREALIKE = resBAYAREALIKE,
    `BAYAREALIKE+J` = resBAYAREALIKEj
  )

  # --- 6. Calculate Summary Statistics and Compare Models ---
  restable <- NULL
  teststable <- NULL
  
  # Function to perform model comparison and extract results (modified for direct use)
  compare_models <- function(res_j, res_no_j, model_name_j, model_name_no_j) {
    LnL_j <- get_LnL_from_BioGeoBEARS_results_object(res_j)
    LnL_no_j <- get_LnL_from_BioGeoBEARS_results_object(res_no_j)
    
    numparams_j <- length(res_j$outputs@params_table[, "est"][res_j$outputs@params_table[, "type"] == "free"])
    numparams_no_j <- length(res_no_j$outputs@params_table[, "est"][res_no_j$outputs@params_table[, "type"] == "free"])
    
    stats <- AICstats_2models(LnL_no_j, LnL_j, numparams_no_j, numparams_j) # Order is (null, alt)
    
    res_j_params <- extract_params_from_BioGeoBEARS_results_object(results_object = res_j, returnwhat = "table", addl_params = c("j"), paramsstr_digits = 4)
    res_no_j_params <- extract_params_from_BioGeoBEARS_results_object(results_object = res_no_j, returnwhat = "table", addl_params = c("j"), paramsstr_digits = 4)
    
    tmp_tests <- conditional_format_table(stats)
    
    return(list(restable_entry_j = res_j_params, restable_entry_no_j = res_no_j_params, teststable_entry = tmp_tests, aic_stats = stats))
  }
  
  # Perform comparisons
  comp_DEC <- compare_models(resDECj, resDEC, "DEC+J", "DEC")
  comp_DIVALIKE <- compare_models(resDIVALIKEj, resDIVALIKE, "DIVALIKE+J", "DIVALIKE")
  comp_BAYAREALIKE <- compare_models(resBAYAREALIKEj, resBAYAREALIKE, "BAYAREALIKE+J", "BAYAREALIKE")
  
  # Assemble restable (using names to ensure correct order)
  restable <- rbind(
    comp_DEC$restable_entry_no_j,
    comp_DEC$restable_entry_j,
    comp_DIVALIKE$restable_entry_no_j,
    comp_DIVALIKE$restable_entry_j,
    comp_BAYAREALIKE$restable_entry_no_j,
    comp_BAYAREALIKE$restable_entry_j
  )
  rownames(restable) <- c("DEC", "DEC+J", "DIVALIKE", "DIVALIKE+J", "BAYAREALIKE", "BAYAREALIKE+J")
  restable <- put_jcol_after_ecol(restable) # Helper function from BioGeoBEARS
  
  # Assemble teststable
  teststable <- rbind(
    comp_DEC$teststable_entry,
    comp_DIVALIKE$teststable_entry,
    comp_BAYAREALIKE$teststable_entry
  )
  teststable$alt <- c("DEC+J", "DIVALIKE+J", "BAYAREALIKE+J")
  teststable$null <- c("DEC", "DIVALIKE", "BAYAREALIKE")
  
  # Calculate AICs and Akaike Weights
  AICtable <- calc_AIC_column(LnL_vals = restable$LnL, nparam_vals = restable$numparams)
  restable_AIC_rellike <- AkaikeWeights_on_summary_table(restable = cbind(restable, AICtable), colname_to_use = "AIC")
  restable_AIC_rellike <- put_jcol_after_ecol(restable_AIC_rellike)
  
  # Select the best model
  best_model_name <- rownames(restable_AIC_rellike)[which.min(restable_AIC_rellike$AIC)]
  cat("The best model based on AIC is:", best_model_name, "\n")
  
  # Get the full output for the best model
  best_model_output <- all_model_results[[best_model_name]]
  
  # --- 7. Return Results ---
  list(
    restable_AIC_rellike = restable_AIC_rellike,
    best_model_name = best_model_name,
    best_model_output = best_model_output,
    all_model_results = all_model_results
  )
}
